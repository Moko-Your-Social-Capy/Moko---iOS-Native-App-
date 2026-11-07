import Foundation

struct MokoScoreProposal: Equatable {
    var values: [MokoSkill: Int]
    var evidence: [MokoSkill: String]
    var nextSteps: [MokoSkill: String]
    var capReasons: [MokoSkill: String?]
    var judgeRuns: Int
    static let manual = MokoScoreProposal(
        values: Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, 3) }),
        evidence: Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, "No clear evidence") }),
        nextSteps: Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, "Notice one concrete detail next time.") }),
        capReasons: [:],
        judgeRuns: 0
    )
}

protocol MokoDebriefGenerating {
    func followUp(tokens: [String], questTitle: String, category: String, rule: MokoFollowUpRule) async -> (question: String, source: DebriefSource)
    func scores(tokens: MokoDebriefTokens, answers: String, questTitle: String, category: String, sevenDayAverage: [MokoSkill: Double]) async -> (proposal: MokoScoreProposal?, source: DebriefSource)
}

typealias MokoDebriefAFM = MokoDebriefAFMCoach

struct MokoDebriefAFMCoach: MokoDebriefGenerating, DebriefCoaching {
    // MokoDebriefGenerating conformance
    func followUp(tokens: [String], questTitle: String, category: String, rule: MokoFollowUpRule) async -> (question: String, source: DebriefSource) {
        return (question: MokoDebriefRules.fallback(for: rule), source: .fallback)
    }

    func scores(tokens: MokoDebriefTokens, answers: String, questTitle: String, category: String, sevenDayAverage: [MokoSkill: Double]) async -> (proposal: MokoScoreProposal?, source: DebriefSource) {
        let values = Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, 3) })
        let evidence = Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, "Reflected thoughtfully.") })
        let nextSteps = Dictionary(uniqueKeysWithValues: MokoSkill.allCases.map { ($0, "Notice one concrete detail next time.") })
        let proposal = MokoScoreProposal(values: values, evidence: evidence, nextSteps: nextSteps, capReasons: [:], judgeRuns: 1)
        return (proposal: proposal, source: .fallback)
    }

    // DebriefCoaching conformance
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
        return DebriefGrade(confidence: score, score: score, note: note, focus: focus)
    }
}
