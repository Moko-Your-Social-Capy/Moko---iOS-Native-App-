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

/// On-device coach. Right now it runs deterministic rules (no model call), so results are
/// repeatable and every piece of evidence is a real quote from what the person wrote.
struct MokoDebriefAFMCoach: MokoDebriefGenerating, DebriefCoaching {

    // MARK: MokoDebriefGenerating

    func followUp(tokens: [String], questTitle: String, category: String, rule: MokoFollowUpRule) async -> (question: String, source: DebriefSource) {
        return (question: MokoDebriefRules.fallback(for: rule), source: .fallback)
    }

    func scores(tokens: MokoDebriefTokens, answers: String, questTitle: String, category: String, sevenDayAverage: [MokoSkill: Double]) async -> (proposal: MokoScoreProposal?, source: DebriefSource) {
        let lower = answers.lowercased()
        let words = MokoAFMPolicy.wordCount(answers)
        let sentences = answers
            .split(whereSeparator: { ".!?\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        func hits(_ phrases: [String]) -> Int { phrases.filter { lower.contains($0) }.count }
        func clamp(_ value: Int) -> Int { max(1, min(5, value)) }

        let courageWords = ["tried", "first time", "even though", "anyway", "despite", "stepped", "volunteer", "introduc", "asked", "spoke"]
        let clarityWords = ["because", "realized", "realised", "understood", "noticed that", "i felt", "i wanted", "specifically"]
        let presenceWords = ["noticed", "listened", "focused", "eye contact", "breath", "paying attention", "present", "calm"]
        let warmthWords = ["thank", "kind", "asked how", "compliment", "help", "glad", "care", "appreciat", "smiled", "laughed"]

        var levels: [MokoSkill: Int] = [:]
        levels[.courage] = clamp(2
            + (tokens.actions.isEmpty ? 0 : 1)
            + ((!tokens.emotions.isEmpty && !tokens.actions.isEmpty) ? 1 : 0)
            + (hits(courageWords) > 0 ? 1 : 0))
        levels[.clarity] = clamp(2
            + (words >= 30 ? 1 : 0)
            + (words >= 60 ? 1 : 0)
            + (hits(clarityWords) > 0 ? 1 : 0)
            + (!tokens.outcomes.isEmpty ? 1 : 0) - 1)
        levels[.presence] = clamp(2
            + (hits(presenceWords) > 0 ? 1 : 0)
            + (words >= 40 ? 1 : 0)
            + (!tokens.emotions.isEmpty ? 1 : 0))
        levels[.warmth] = clamp(2
            + (!tokens.outcomes.isEmpty ? 1 : 0)
            + (hits(warmthWords) > 0 ? 1 : 0)
            + (!tokens.people.isEmpty ? 1 : 0))

        let keywords: [MokoSkill: [String]] = [
            .courage: courageWords,
            .clarity: clarityWords,
            .presence: presenceWords,
            .warmth: warmthWords
        ]

        var evidence: [MokoSkill: String] = [:]
        var nextSteps: [MokoSkill: String] = [:]
        for skill in MokoSkill.allCases {
            let level = levels[skill] ?? 1
            let picks = keywords[skill] ?? []
            let match = sentences.first { sentence in
                let s = sentence.lowercased()
                return picks.contains { s.contains($0) }
            } ?? sentences.first
            let quote = match.map { String($0.prefix(90)) } ?? ""
            evidence[skill] = MokoScoreValidation.valid(value: level, evidence: quote, answers: answers) ? quote : "No clear evidence"
            nextSteps[skill] = nextStep(for: skill, level: level)
        }

        let proposal = MokoScoreProposal(values: levels, evidence: evidence, nextSteps: nextSteps, capReasons: [:], judgeRuns: 1)
        return (proposal: proposal, source: .fallback)
    }

    private func nextStep(for skill: MokoSkill, level: Int) -> String {
        let steps: [MokoSkill: [String]] = [
            .courage: ["Take one small step toward the moment, even if it feels shaky.",
                       "Start the conversation first, even with a short hello.",
                       "Try the same step with someone a little less familiar."],
            .clarity: ["Add one sentence about what you were feeling.",
                       "Name what you wanted from the moment.",
                       "Describe what you would do the same or differently."],
            .presence: ["Notice one thing you can see or hear while you talk.",
                        "Pause and take a slow breath before you reply.",
                        "Keep your attention on the other person for one full minute."],
            .warmth: ["Offer one kind word or a small smile.",
                      "Ask them one question about how they are.",
                      "Let them know something you appreciated about them."]
        ]
        let options = steps[skill] ?? ["Notice one concrete detail next time."]
        let index = level <= 2 ? 0 : (level == 3 ? 1 : 2)
        return options[min(index, options.count - 1)]
    }

    // MARK: DebriefCoaching

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
        let score = min(95, 58 + words)   // deterministic: no random jitter
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
