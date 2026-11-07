import Foundation

/// Deterministic policy and guardrail helpers for Apple Foundation Models integration.
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
        let normalized = text.lowercased()
        return crisisPhrases.contains { normalized.contains($0) }
    }

    static func bounded(_ text: String, characters: Int) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(max(0, characters)))
    }

    static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    static func passesChecks(_ text: String, maxWords: Int, source: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, wordCount(trimmed) <= maxWords else { return false }
        let lowercased = trimmed.lowercased()
        guard !prohibitedTerms.contains(where: lowercased.contains) else { return false }
        guard !containsCrisisLanguage(trimmed) else { return false }
        let sourceDigits = Set(source.filter(\.isNumber))
        return trimmed.filter(\.isNumber).allSatisfy(sourceDigits.contains)
    }

    static func shouldOfferOptionalTinyStep(sudsScore: Int?) -> Bool {
        guard let sudsScore else { return false }
        return min(10, max(0, sudsScore)) >= 7
    }
}

/// On-device SUDS check-in store with 24-hour retention.
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
