import Foundation

<<<<<<< HEAD
struct MokoScoreProposal: Equatable {
    var values: [MokoSkill: Int]
    var evidence: [MokoSkill: String]
    var nextSteps: [MokoSkill: String]
    var capReasons: [MokoSkill: String?]
    var judgeRuns: Int
    static let manual = MokoScoreProposal(values: Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, 1) }), evidence: Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, "No clear evidence") }), nextSteps: Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, "Notice one concrete detail next time.") }), capReasons: [:], judgeRuns: 0)
}

protocol MokoDebriefGenerating {
    func followUp(tokens: [String], questTitle: String, category: String, rule: MokoFollowUpRule) async -> (question: String, source: DebriefSource)
    func scores(tokens: MokoDebriefTokens, answers: String, questTitle: String, category: String, sevenDayAverage: [MokoSkill: Double]) async -> (proposal: MokoScoreProposal?, source: DebriefSource)
}

#if canImport(FoundationModels)
import FoundationModels

@Generable private struct AFMFollowUp { @Guide(description: "One open-ended sentence under 20 words, no advice or judgement") var question: String }
@Generable private struct AFMScoreProposal {
    var courage: Int; var clarity: Int; var presence: Int; var warmth: Int
    var courageEvidence: String; var clarityEvidence: String; var presenceEvidence: String; var warmthEvidence: String
    var courageNextStep: String; var clarityNextStep: String; var presenceNextStep: String; var warmthNextStep: String
}

struct MokoDebriefAFM: MokoDebriefGenerating {
    func followUp(tokens: [String], questTitle: String, category: String, rule: MokoFollowUpRule) async -> (question: String, source: DebriefSource) {
        guard !MokoAFMPolicy.containsCrisisLanguage(tokens.joined(separator: " ")) else { return (MokoDebriefRules.fallback(for: rule), .fallback) }
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return (MokoDebriefRules.fallback(for: rule), .fallback) }
        do {
            let session = LanguageModelSession(instructions: "Use only supplied tokens and quest. Do not invent events, diagnose, advise, judge, or ask yes/no questions.")
            let response = try await session.respond(to: "Quest: \(questTitle). Category: \(category). Tokens: \(tokens.joined(separator: ", ")). Focus: \(rule).", generating: AFMFollowUp.self, options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 40))
            let question = response.content.question.trimmingCharacters(in: .whitespacesAndNewlines)
            guard question.split(separator: " ").count <= 20, question.hasSuffix("?") else { return (MokoDebriefRules.fallback(for: rule), .fallback) }
            return (question, .afm)
        } catch { return (MokoDebriefRules.fallback(for: rule), .fallback) }
    }
    func scores(tokens: MokoDebriefTokens, answers: String, questTitle: String, category: String, sevenDayAverage: [MokoSkill: Double]) async -> (proposal: MokoScoreProposal?, source: DebriefSource) {
        let model = SystemLanguageModel.default
        guard case .available = model.availability, !MokoAFMPolicy.containsCrisisLanguage(answers) else { return (nil, .fallback) }
        do {
            async let first = judge(model: model, temperature: 0.0, tokens: tokens.words, answers: answers, questTitle: questTitle, category: category)
            async let second = judge(model: model, temperature: 0.3, tokens: tokens.words, answers: answers, questTitle: questTitle, category: category)
            let (a, b) = try await (first, second)
            return (MokoDebriefScoreCaps.apply(lower: a, other: b, tokens: tokens, answers: answers, average: sevenDayAverage), .afm)
        } catch { return (nil, .fallback) }
    }
    private func judge(model: SystemLanguageModel, temperature: Double, tokens: [String], answers: String, questTitle: String, category: String) async throws -> MokoScoreProposal {
        let instructions = "You are a strict, fair reviewer of reflection quality. Use only the user's words and tokens. Quote evidence exactly. If no evidence, give 1 or 2 and say what is missing. Never invent events. No praise, no advice beyond nextStep. Courage 1 avoided/thought, 3 did it with hesitation, 5 hard action plus follow-through. Clarity 1 vague, 3 main point muddled, 5 plain point and want. Presence 1 distracted, 3 sometimes noticed other person, 5 noticed detail and responded. Warmth 1 no care, 3 polite, 5 specific care and effect. 4 needs action plus reaction or learning; 5 also honest self-awareness. Most early sessions are 1-3. Each nextStep starts with a verb, names one behavior, under 15 words."
        let session = LanguageModelSession(instructions: instructions)
        let r = try await session.respond(to: "Quest: \(questTitle). Category: \(category). Tokens: \(tokens.joined(separator: ", ")). Answers: \(answers)", generating: AFMScoreProposal.self, options: GenerationOptions(temperature: temperature, maximumResponseTokens: 220)).content
        return MokoScoreProposal(values: [.courage:r.courage,.clarity:r.clarity,.presence:r.presence,.warmth:r.warmth], evidence: [.courage:r.courageEvidence,.clarity:r.clarityEvidence,.presence:r.presenceEvidence,.warmth:r.warmthEvidence], nextSteps: [.courage:r.courageNextStep,.clarity:r.clarityNextStep,.presence:r.presenceNextStep,.warmth:r.warmthNextStep], capReasons: [:], judgeRuns: 2)
    }
}
#else
struct MokoDebriefAFM: MokoDebriefGenerating {
    func followUp(tokens: [String], questTitle: String, category: String, rule: MokoFollowUpRule) async -> (String, DebriefSource) { (MokoDebriefRules.fallback(for: rule), .fallback) }
    func scores(tokens: MokoDebriefTokens, answers: String, questTitle: String, category: String, sevenDayAverage: [MokoSkill: Double]) async -> (MokoScoreProposal?, DebriefSource) { (nil, .fallback) }
}
#endif

enum MokoDebriefScoreCaps {
    static func apply(lower a: MokoScoreProposal, other b: MokoScoreProposal, tokens: MokoDebriefTokens, answers: String, average: [MokoSkill: Double]) -> MokoScoreProposal {
        var output = a; let words = answers.split(whereSeparator: { $0.isWhitespace }).count
        for skill in MokoSkill.allCases {
            var level = min(a.values[skill] ?? 1, b.values[skill] ?? 1); var reason: String?
            if words < 15 { level = min(level, 2); reason = "reflection is still brief" }
            if skill == .courage && tokens.actions.isEmpty { level = min(level, 2); reason = "no clear action" }
            if (skill == .presence || skill == .warmth) && tokens.people.isEmpty { level = min(level, 2); reason = "no clear person context" }
            if (skill == .clarity || skill == .warmth) && tokens.outcomes.isEmpty { level = min(level, 3); reason = "no clear outcome" }
            if !MokoScoreValidation.valid(value: level, evidence: a.evidence[skill] ?? "", answers: answers) { level = min(level, 2); reason = "no clear evidence" }
            let rolling = Int(floor(average[skill] ?? 0)) + 1
            if rolling > 1 { level = min(level, rolling) }
            if level == 5 && (average[skill] ?? 0) < 4 { level = 4; reason = "building toward this level" }
            output.values[skill] = max(1, min(5, level)); output.capReasons[skill] = reason
        }
        return output
    }
}
=======
#if canImport(FoundationModels)
import FoundationModels

@Generable
private struct AFMFollowUp {
    @Guide(description: "One open-ended sentence under 20 words, no advice or judgement")
    var question: String
}

struct MokoDebriefAFMCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String {
        return "Welcome back! How did \(context.questTitle) go? Tell me what happened, in your own words."
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        let combined = previousAnswers.joined(separator: " ")
        let tokens = MokoDebriefTokenizer.tokenize(combined)
        let rule = MokoDebriefRules.rule(for: tokens)
        let fallbackText = MokoDebriefRules.fallback(for: rule)
        let focus: DebriefParameter = switch number {
        case 1: .presence
        case 2: .clarity
        default: .warmth
        }

        if MokoAFMPolicy.containsCrisisLanguage(combined) {
            return DebriefQuestion(text: fallbackText, focus: focus)
        }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return DebriefQuestion(text: fallbackText, focus: focus)
        }

        do {
            let session = LanguageModelSession(instructions: "Use only supplied tokens and quest. Do not invent events, diagnose, advise, judge, or ask yes/no questions.")
            let response = try await session.respond(
                to: "Quest: \(context.questTitle). Category: \(context.category.rawValue). Previous answers: \(combined). Focus rule: \(rule).",
                generating: AFMFollowUp.self,
                options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 40)
            )
            let qText = response.content.question.trimmingCharacters(in: .whitespacesAndNewlines)
            guard qText.split(separator: " ").count <= 20, qText.hasSuffix("?") else {
                return DebriefQuestion(text: fallbackText, focus: focus)
            }
            return DebriefQuestion(text: qText, focus: focus)
        } catch {
            return DebriefQuestion(text: fallbackText, focus: focus)
        }
    }

    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        let words = answer.split(separator: " ").count
        let confidence = min(96, 52 + words + Int.random(in: 0...6))
        let score = min(95, 58 + words + Int.random(in: 0...8))
        let note: String
        switch focus {
        case .presence:
            note = "Honest and self-aware. Noticing your mind drift and tuning back in is real presence."
        case .clarity:
            note = "Clear and specific. Following up on what they said keeps the conversation sharp."
        case .warmth:
            note = "Warm and genuine. Saying it out loud makes people feel valued."
        default:
            note = "You showed up and spoke honestly. That takes courage."
        }
        return DebriefGrade(confidence: confidence, score: score, note: note, focus: focus)
    }
}

#else

struct MokoDebriefAFMCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String {
        return "Welcome back! How did \(context.questTitle) go? Tell me what happened, in your own words."
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        let combined = previousAnswers.joined(separator: " ")
        let tokens = MokoDebriefTokenizer.tokenize(combined)
        let rule = MokoDebriefRules.rule(for: tokens)
        let focus: DebriefParameter = switch number {
        case 1: .presence
        case 2: .clarity
        default: .warmth
        }
        return DebriefQuestion(text: MokoDebriefRules.fallback(for: rule), focus: focus)
    }

    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        let words = answer.split(separator: " ").count
        let confidence = min(96, 52 + words + Int.random(in: 0...6))
        return DebriefGrade(confidence: confidence, score: confidence, note: "Reflected thoughtfully.", focus: focus)
    }
}

#endif
>>>>>>> recovered-local-code
