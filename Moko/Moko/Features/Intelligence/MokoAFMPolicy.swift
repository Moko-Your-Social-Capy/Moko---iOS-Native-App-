import Foundation

/// Small deterministic policy helpers shared by the app and the terminal smoke test.
/// These checks are product guardrails, not a clinical assessment.
enum MokoAFMPolicy {
    static let maximumTitleCharacters = 120
    static let maximumNotesCharacters = 500
    static let sudsRetention: TimeInterval = 24 * 60 * 60

    private static let crisisPhrases = [
        "want to kill myself", "kill myself", "end my life", "take my own life",
        "hurt myself", "harm myself", "self-harm", "self harm", "suicidal",
        "can't keep myself safe", "cannot keep myself safe", "don't want to live",
        "do not want to live"
    ]

    private static let prohibitedTerms = [
        "diagnos", "disorder", "cure", "treat", "therapy", "you should have",
        "failed", "lazy", "pathetic", "weak", "normal people", "fix you"
    ]

    static func containsCrisisLanguage(_ text: String) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "\n", with: " ")
        return crisisPhrases.contains { normalized.contains($0) }
    }

    static func bounded(_ text: String, characters: Int) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(max(0, characters)))
    }

    static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    /// Validate only generated text. Numbers must be grounded in the supplied facts.
    static func passesChecks(_ text: String, maxWords: Int, source: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, wordCount(trimmed) <= maxWords else { return false }

        let lowercased = trimmed.lowercased()
        guard !prohibitedTerms.contains(where: lowercased.contains) else { return false }
        guard !containsCrisisLanguage(trimmed) else { return false }

        let sourceDigits = Set(source.filter(\.isNumber))
        return trimmed.filter(\.isNumber).allSatisfy(sourceDigits.contains)
    }

    /// Translate only relevant affirmative onboarding answers into short preference hints.
    /// These are not diagnoses, trait labels, or risk scores.
    static func personalizationSignals(category: String, affirmativeQuestionIDs: Set<Int>) -> [String] {
        let category = category.lowercased()
        let relevant: Set<Int>
        switch category {
        case "family": relevant = [1, 2, 6, 7, 8]
        case "friends": relevant = [1, 2, 3, 5, 7]
        case "work", "dating", "others": relevant = [3, 4, 7]
        default: relevant = []
        }

        let phrases: [Int: String] = [
            1: "A small honest conversation with someone trusted may be relevant.",
            2: "A gentle opening that makes sharing optional may be useful.",
            3: "A low-pressure first contribution in a group may be useful.",
            4: "An easy way to enter a new group may be useful.",
            5: "A kind, manageable way to say something honest may be relevant.",
            6: "A respectful boundary-setting step may be relevant.",
            7: "A brief, present-focused step may be useful.",
            8: "A calm way to express a feeling may be relevant."
        ]

        return affirmativeQuestionIDs
            .intersection(relevant)
            .sorted()
            .compactMap { phrases[$0] }
    }

    static func shouldOfferOptionalTinyStep(sudsScore: Int?) -> Bool {
        // This is an app interaction choice, not a SUDS clinical cutoff.
        guard let sudsScore else { return false }
        return min(10, max(0, sudsScore)) >= 7
    }
}

/// A temporary, on-device check-in. It expires after 24 hours and is never uploaded.
enum MokoSUDSStore {
    private static let scoreKey = "moko.suds.today.score"
    private static let dateKey = "moko.suds.today.timestamp"

    static func save(_ score: Int, at date: Date = .now, defaults: UserDefaults = .standard) {
        defaults.set(min(10, max(0, score)), forKey: scoreKey)
        defaults.set(date, forKey: dateKey)
    }

    static func latest(at date: Date = .now, defaults: UserDefaults = .standard) -> Int? {
        guard let timestamp = defaults.object(forKey: dateKey) as? Date,
              let score = defaults.object(forKey: scoreKey) as? Int,
              (0...10).contains(score),
              timestamp <= date,
              date.timeIntervalSince(timestamp) <= MokoAFMPolicy.sudsRetention else {
            clear(defaults: defaults)
            return nil
        }
        return score
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: scoreKey)
        defaults.removeObject(forKey: dateKey)
    }
}
