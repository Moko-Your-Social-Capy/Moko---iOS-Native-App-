//
//  OnboardingReflectionServiceTests.swift
//  Moko
//
//  Comprehensive verification suite for OnboardingReflectionService.
//  Covers all 12 requirements from Section 10 of the specification:
//  1. All Yes
//  2. All No
//  3. Alternating Yes/No
//  4. Four Yes followed by four No
//  5. Four No followed by four Yes
//  6. Mixed answer combinations
//  7. Equal-score tie-breaking
//  8. Missing answers
//  9. Exactly four results in each group
//  10. No duplicate categories
//  11. Deterministic results across repeated executions
//  12. Persistence and retrieval without recalculation
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.SRMIST.MokoApp", category: "OnboardingReflectionTests")

struct OnboardingReflectionServiceTests {

    static func runAllTests() {
        testAllYes()
        testAllNo()
        testAlternating()
        testFourYesFourNo()
        testFourNoFourYes()
        testMixedCombinations()
        testEqualScoreTieBreaking()
        testMissingAnswers()
        testExactlyFourInEachGroup()
        testNoDuplicateCategories()
        testDeterministicAcrossRepeatedExecutions()
        testPersistenceAndRetrieval()
        logger.info("All 12 OnboardingReflectionService tests passed successfully.")
    }

    // 1. All Yes
    static func testAllYes() {
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .yes, 3: .yes, 4: .yes,
            5: .yes, 6: .yes, 7: .yes, 8: .yes
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testAllYes failed to calculate")
        }

        // Q1-Q4 win tie-break -> strengths (always resolved to strength categories)
        let expectedStrengths = [
            "honest_expression",
            "trusted_vulnerability",
            "thoughtful_presence",
            "social_initiative"
        ]
        // Q5-Q8 -> areas to grow (always resolved to growth/weakness categories)
        let expectedGrowth = [
            "conflict_avoidance",
            "boundary_softening",
            "post_chat_overthinking",
            "emotional_suppression"
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testAllYes strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testAllYes growth mismatch")
    }

    // 2. All No
    static func testAllNo() {
        let answers: [Int: OnboardingAnswer] = [
            1: .no, 2: .no, 3: .no, 4: .no,
            5: .no, 6: .no, 7: .no, 8: .no
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testAllNo failed to calculate")
        }

        // Q1-Q4 win tie-break -> strengths
        let expectedStrengths = [
            "honest_expression",
            "trusted_vulnerability",
            "thoughtful_presence",
            "social_initiative"
        ]
        // Q5-Q8 -> areas to grow
        let expectedGrowth = [
            "conflict_avoidance",
            "boundary_softening",
            "post_chat_overthinking",
            "emotional_suppression"
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testAllNo strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testAllNo growth mismatch")
    }

    // 3. Alternating Yes/No (Case C from Section 8)
    static func testAlternating() {
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .no, 3: .yes, 4: .no,
            5: .yes, 6: .no, 7: .yes, 8: .no
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testAlternating failed to calculate")
        }

        let expectedStrengths = [
            "trusted_vulnerability",
            "social_initiative",
            "boundary_awareness",
            "calm_self_expression"
        ]
        let expectedGrowth = [
            "unexpressed_thoughts",
            "hesitant_participation",
            "conflict_avoidance",
            "post_chat_overthinking"
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testAlternating strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testAlternating growth mismatch")
    }

    // 4. Four Yes followed by four No (Case D from Section 8)
    static func testFourYesFourNo() {
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .yes, 3: .yes, 4: .yes,
            5: .no, 6: .no, 7: .no, 8: .no
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testFourYesFourNo failed to calculate")
        }

        let expectedStrengths = [
            "deep_loyalty",
            "boundary_awareness",
            "present_moment_confidence",
            "calm_self_expression"
        ]
        let expectedGrowth = [
            "unexpressed_thoughts",
            "emotional_guardedness",
            "hesitant_participation",
            "social_hesitation"
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testFourYesFourNo strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testFourYesFourNo growth mismatch")
    }

    // 5. Four No followed by four Yes
    static func testFourNoFourYes() {
        let answers: [Int: OnboardingAnswer] = [
            1: .no, 2: .no, 3: .no, 4: .no,
            5: .yes, 6: .yes, 7: .yes, 8: .yes
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testFourNoFourYes failed to calculate")
        }

        let expectedStrengths = [
            "honest_expression",
            "trusted_vulnerability",
            "thoughtful_presence",
            "social_initiative"
        ]
        let expectedGrowth = [
            "conflict_avoidance",
            "boundary_softening",
            "post_chat_overthinking",
            "emotional_suppression"
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testFourNoFourYes strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testFourNoFourYes growth mismatch")
    }

    // 6. Mixed answer combinations
    static func testMixedCombinations() {
        // Q1: No, Q2: No, Q3: Yes, Q4: Yes, Q5: No, Q6: Yes, Q7: No, Q8: Yes
        let answers: [Int: OnboardingAnswer] = [
            1: .no, 2: .no, 3: .yes, 4: .yes,
            5: .no, 6: .yes, 7: .no, 8: .yes
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testMixedCombinations failed to calculate")
        }

        // Questions with score 100: Q1, Q2, Q5, Q7 -> strengths
        let expectedStrengths = [
            "honest_expression",
            "trusted_vulnerability",
            "deep_loyalty",
            "present_moment_confidence"
        ]
        // Questions with score 0: Q3, Q4, Q6, Q8 -> areas to grow
        let expectedGrowth = [
            "hesitant_participation",
            "social_hesitation",
            "boundary_softening",
            "emotional_suppression"
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testMixedCombinations strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testMixedCombinations growth mismatch")
    }

    // 7. Equal-score tie-breaking
    static func testEqualScoreTieBreaking() {
        // Two with score 100 (Q3, Q7), six with score 0 (Q1, Q2, Q4, Q5, Q6, Q8)
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .yes, 3: .no, 4: .yes,
            5: .yes, 6: .yes, 7: .no, 8: .yes
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testEqualScoreTieBreaking failed")
        }

        // Top 2: Q3, Q7 (score 100)
        // Next 2 from score 0: tie-break by ID gives Q1, Q2 (resolved to strength categories)
        let expectedStrengths = [
            "thoughtful_presence", // Q3
            "present_moment_confidence", // Q7
            "honest_expression", // Q1
            "trusted_vulnerability" // Q2
        ]
        // Remaining 4: Q4, Q5, Q6, Q8
        let expectedGrowth = [
            "social_hesitation", // Q4
            "conflict_avoidance", // Q5
            "boundary_softening", // Q6
            "emotional_suppression" // Q8
        ]

        assert(result.strengthCategoryIDs == expectedStrengths, "testEqualScoreTieBreaking strengths mismatch")
        assert(result.developmentCategoryIDs == expectedGrowth, "testEqualScoreTieBreaking growth mismatch")
    }

    // 8. Missing answers
    static func testMissingAnswers() {
        let partialAnswers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .no, 3: .yes // missing 4...8
        ]

        do {
            _ = try OnboardingReflectionService.calculate(from: partialAnswers)
            fatalError("testMissingAnswers should have thrown an error")
        } catch let OnboardingReflectionError.incompleteAnswers(expected, actual, missing) {
            assert(expected == 8, "Expected 8 questions")
            assert(actual == 3, "Expected 3 answered")
            assert(missing == [4, 5, 6, 7, 8], "Expected missing [4, 5, 6, 7, 8]")
        } catch {
            fatalError("Unexpected error thrown: \(error)")
        }
    }

    // 9. Exactly four results in each group
    static func testExactlyFourInEachGroup() {
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .no, 3: .no, 4: .yes,
            5: .yes, 6: .no, 7: .no, 8: .yes
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testExactlyFourInEachGroup failed")
        }

        assert(result.strengthCategoryIDs.count == 4, "Must have exactly 4 strengths")
        assert(result.developmentCategoryIDs.count == 4, "Must have exactly 4 development areas")
    }

    // 10. No duplicate categories & no group overlap
    static func testNoDuplicateCategories() {
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .no, 3: .yes, 4: .no,
            5: .yes, 6: .no, 7: .yes, 8: .no
        ]
        guard let result = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testNoDuplicateCategories failed")
        }

        let strengthSet = Set(result.strengthCategoryIDs)
        let growthSet = Set(result.developmentCategoryIDs)

        assert(strengthSet.count == 4, "No duplicates within strengths")
        assert(growthSet.count == 4, "No duplicates within growth areas")
        assert(strengthSet.isDisjoint(with: growthSet), "Strengths and growth areas must not overlap")
    }

    // 11. Deterministic results across repeated executions
    static func testDeterministicAcrossRepeatedExecutions() {
        let answers: [Int: OnboardingAnswer] = [
            1: .no, 2: .yes, 3: .no, 4: .yes,
            5: .no, 6: .yes, 7: .no, 8: .yes
        ]
        guard let first = try? OnboardingReflectionService.calculate(from: answers),
              let second = try? OnboardingReflectionService.calculate(from: answers) else {
            fatalError("testDeterministicAcrossRepeatedExecutions failed")
        }

        assert(first.strengthCategoryIDs == second.strengthCategoryIDs, "Results must be identical")
        assert(first.developmentCategoryIDs == second.developmentCategoryIDs, "Results must be identical")
    }

    // 12. Persistence and retrieval without recalculation
    static func testPersistenceAndRetrieval() {
        let answers: [Int: OnboardingAnswer] = [
            1: .yes, 2: .no, 3: .no, 4: .yes,
            5: .yes, 6: .no, 7: .yes, 8: .no
        ]

        OnboardingReflectionService.clear()
        assert(OnboardingReflectionService.loadResult() == nil, "Store must be empty after clear")

        guard let generated = try? OnboardingReflectionService.generateAndSave(from: answers) else {
            fatalError("generateAndSave failed")
        }

        guard let loaded = OnboardingReflectionService.loadResult() else {
            fatalError("loadResult returned nil")
        }

        assert(loaded.answers == generated.answers, "Persisted answers mismatch")
        assert(loaded.strengthCategoryIDs == generated.strengthCategoryIDs, "Persisted strengths mismatch")
        assert(loaded.developmentCategoryIDs == generated.developmentCategoryIDs, "Persisted growth mismatch")
        assert(loaded.selectedCategoryIDs == generated.selectedCategoryIDs, "Persisted categories mismatch")
        assert(loaded.version == 1, "Persisted version mismatch")
    }
}
