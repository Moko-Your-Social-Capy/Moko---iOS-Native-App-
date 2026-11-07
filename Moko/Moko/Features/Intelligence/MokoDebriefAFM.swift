import Foundation

struct MokoScoreProposal: Equatable {
    var values: [String: Int]
    var evidence: [String: String]
    var nextSteps: [String: String]
    var capReasons: [String: String?]
    var judgeRuns: Int
    static let manual = MokoScoreProposal(
        values: [:],
        evidence: [:],
        nextSteps: [:],
        capReasons: [:],
        judgeRuns: 0
    )
}

typealias MokoDebriefGenerating = DebriefCoaching
typealias MokoDebriefAFM = MokoDebriefAFMCoach

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
