//
//  OnboardingReflectionService.swift
//  Moko
//
//  Deterministic scoring and category mapping for the 8 onboarding swipe questions.
//  Produces exactly 4 Strengths and 4 Areas to Grow for the initial reflection screen.
//  Completely independent of quest recommendations, XP, debriefing, or profile calculations.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.SRMIST.MokoApp", category: "OnboardingReflection")

// MARK: - Category Mapping Model

/// Fixed mapping between a question and its two possible categories (Yes/No).
struct OnboardingCategoryMapping: Sendable, Equatable {
    let questionID: Int
    let yesCategory: String
    let noCategory: String

    func category(for answer: OnboardingAnswer) -> String {
        answer == .yes ? yesCategory : noCategory
    }
}

// MARK: - Assessment Result Model

/// Saved results of the deterministic onboarding reflection assessment.
struct OnboardingReflectionResult: Codable, Sendable, Equatable {
    /// The 8 original answers: questionID (1...8) -> Bool (true = yes, false = no).
    let answers: [Int: Bool]
    /// The 8 selected category IDs in question order (Q1...Q8).
    let selectedCategoryIDs: [String]
    /// Exactly 4 strength category IDs.
    let strengthCategoryIDs: [String]
    /// Exactly 4 development/growth category IDs.
    let developmentCategoryIDs: [String]
    /// Version of the scoring & mapping rules.
    let version: Int
    /// When the assessment was generated.
    let timestamp: Date

    init(
        answers: [Int: Bool],
        selectedCategoryIDs: [String],
        strengthCategoryIDs: [String],
        developmentCategoryIDs: [String],
        version: Int = 1,
        timestamp: Date = .now
    ) {
        self.answers = answers
        self.selectedCategoryIDs = selectedCategoryIDs
        self.strengthCategoryIDs = strengthCategoryIDs
        self.developmentCategoryIDs = developmentCategoryIDs
        self.version = version
        self.timestamp = timestamp
    }
}

// MARK: - Validation Error

enum OnboardingReflectionError: Error, LocalizedError, Equatable {
    case incompleteAnswers(expected: Int, actual: Int, missingQuestionIDs: [Int])

    var errorDescription: String? {
        switch self {
        case .incompleteAnswers(let expected, let actual, let missing):
            let missingList = missing.map(String.init).joined(separator: ", ")
            return "Expected \(expected) answered questions, but received \(actual). Missing questions: \(missingList)"
        }
    }
}

// MARK: - Onboarding Reflection Service

enum OnboardingReflectionService {
    /// Total number of onboarding reflection questions.
    static let questionCount = 8

    /// Storage key in UserDefaults. Survives app launches without requiring database migration.
    private static let storageKey = "moko.onboarding.reflectionResult"

    /// Fixed category mapping table for all 8 questions.
    static let mappings: [Int: OnboardingCategoryMapping] = [
        1: .init(questionID: 1, yesCategory: "unexpressed_thoughts", noCategory: "honest_expression"),
        2: .init(questionID: 2, yesCategory: "emotional_guardedness", noCategory: "trusted_vulnerability"),
        3: .init(questionID: 3, yesCategory: "hesitant_participation", noCategory: "thoughtful_presence"),
        4: .init(questionID: 4, yesCategory: "social_hesitation", noCategory: "social_initiative"),
        5: .init(questionID: 5, yesCategory: "conflict_avoidance", noCategory: "deep_loyalty"),
        6: .init(questionID: 6, yesCategory: "boundary_softening", noCategory: "boundary_awareness"),
        7: .init(questionID: 7, yesCategory: "post_chat_overthinking", noCategory: "present_moment_confidence"),
        8: .init(questionID: 8, yesCategory: "emotional_suppression", noCategory: "calm_self_expression")
    ]

    // MARK: - Scoring & Mapping Logic

    /// Evaluates the 8 answers and deterministically produces 4 Strengths and 4 Areas to Grow.
    ///
    /// Algorithm:
    /// 1. Validate that all 8 questions (1...8) are answered.
    /// 2. Calculate strength score: No = 100, Yes = 0.
    /// 3. Sort by strength score descending, tie-breaking by question priority ascending (Q1 -> Q8).
    /// 4. Top 4 become Strengths; bottom 4 become Areas to Grow.
    /// 5. Map each question's actual answer to its predefined category ID.
    static func calculate(from answers: [Int: OnboardingAnswer]) throws -> OnboardingReflectionResult {
        // Step 1: Validate that every question has an answer.
        var missing: [Int] = []
        for id in 1...questionCount {
            if answers[id] == nil {
                missing.append(id)
            }
        }
        guard missing.isEmpty else {
            throw OnboardingReflectionError.incompleteAnswers(
                expected: questionCount,
                actual: answers.count,
                missingQuestionIDs: missing
            )
        }

        // Step 2: Calculate scores.
        struct ScoredQuestion {
            let id: Int
            let answer: OnboardingAnswer
            let strengthScore: Int
            let developmentScore: Int
        }

        var scored: [ScoredQuestion] = []
        scored.reserveCapacity(questionCount)

        for id in 1...questionCount {
            guard let answer = answers[id] else { continue }
            // Answering "No" means difficulty is not reported (strength score = 100).
            // Answering "Yes" means difficulty is present (strength score = 0).
            let strength = (answer == .no) ? 100 : 0
            let development = 100 - strength
            scored.append(ScoredQuestion(
                id: id,
                answer: answer,
                strengthScore: strength,
                developmentScore: development
            ))
        }

        // Step 3: Deterministic sort.
        // Primary: strengthScore descending.
        // Secondary: question ID ascending (Q1 -> Q2 -> ... -> Q8).
        let sorted = scored.sorted { a, b in
            if a.strengthScore != b.strengthScore {
                return a.strengthScore > b.strengthScore
            }
            return a.id < b.id
        }

        // Step 4: Partition into 4 strengths and 4 areas of growth.
        let strengthSlice = sorted.prefix(4)
        let developmentSlice = sorted.suffix(4)

        // Step 5: Resolve category IDs.
        // Questions allocated to Strengths resolve to their positive Strength category (noCategory).
        // Questions allocated to Areas to Grow resolve to their Growth/Weakness category (yesCategory).
        func categoryID(for questionID: Int, asStrength: Bool) -> String {
            guard let mapping = mappings[questionID] else { return "" }
            return asStrength ? mapping.noCategory : mapping.yesCategory
        }

        let strengthCategoryIDs = strengthSlice.map { categoryID(for: $0.id, asStrength: true) }
        let developmentCategoryIDs = developmentSlice.map { categoryID(for: $0.id, asStrength: false) }

        let strengthQuestionIDs = Set(strengthSlice.map(\.id))
        var selectedCategoryIDs: [String] = []
        selectedCategoryIDs.reserveCapacity(questionCount)
        for id in 1...questionCount {
            let isStrength = strengthQuestionIDs.contains(id)
            selectedCategoryIDs.append(categoryID(for: id, asStrength: isStrength))
        }

        // Convert answers map for Codable persistence.
        var boolAnswers: [Int: Bool] = [:]
        for (qID, ans) in answers {
            boolAnswers[qID] = (ans == .yes)
        }

        return OnboardingReflectionResult(
            answers: boolAnswers,
            selectedCategoryIDs: selectedCategoryIDs,
            strengthCategoryIDs: strengthCategoryIDs,
            developmentCategoryIDs: developmentCategoryIDs,
            version: 1,
            timestamp: .now
        )
    }

    // MARK: - Persistence

    /// Calculates and saves the reflection result once after onboarding finishes.
    @discardableResult
    static func generateAndSave(from answers: [Int: OnboardingAnswer]) throws -> OnboardingReflectionResult {
        let result = try calculate(from: answers)
        saveResult(result)
        logger.info("Successfully generated and saved deterministic onboarding reflection result.")
        return result
    }

    /// Loads the saved reflection result from storage.
    static func loadResult() -> OnboardingReflectionResult? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(OnboardingReflectionResult.self, from: data)
    }

    /// Saves the reflection result to storage.
    static func saveResult(_ result: OnboardingReflectionResult) {
        if let encoded = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// Clears the saved reflection result when onboarding is reset or account is deleted.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        logger.info("Cleared onboarding reflection result.")
    }
}
