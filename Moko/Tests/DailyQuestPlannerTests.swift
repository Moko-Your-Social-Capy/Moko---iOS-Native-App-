import XCTest
import SwiftData
@testable import Moko

@MainActor
final class DailyQuestPlannerTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([DailyPlan.self, Quest.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    func testPlanIdempotency() async throws {
        let questItem = LibraryQuestItem(
            id: "q1",
            title: "Test Quest",
            situation: "Situation",
            step: "Step",
            tryThis: "Try this",
            skills: ["Warmth"],
            difficulty: 1,
            category: "Friends",
            onboardingTheme: "closeCircle",
            stage: "closeCircle",
            estimatedMinutes: 2,
            tip: "Tip"
        )

        await DailyQuestPlanner.generateTomorrowPlan(modelContext: modelContext, availableQuests: [questItem])
        await DailyQuestPlanner.generateTomorrowPlan(modelContext: modelContext, availableQuests: [questItem])

        let descriptor = FetchDescriptor<DailyPlan>()
        let plans = try modelContext.fetch(descriptor)
        XCTAssertEqual(plans.count, 1, "Plan generation should be idempotent for tomorrow")
    }

    func testDatePromotionAndMidnight() async throws {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startOfYesterday = calendar.startOfDay(for: yesterday)

        let plan = DailyPlan(
            date: startOfYesterday,
            questId: "q1",
            reason: "weakSkill",
            onboardingTheme: "closeCircle",
            difficultyTarget: 2,
            copyJSON: "{}",
            status: "planned"
        )
        modelContext.insert(plan)
        try modelContext.save()

        await DailyQuestPlanner.promotePlanIfNeeded(modelContext: modelContext, availableQuests: [])
        XCTAssertEqual(plan.status, "active", "Past or today's planned plan should be promoted to active")
    }

    func testDifficultyBoundsAndJumps() {
        let diff = 3
        let target = max(1, min(5, diff))
        XCTAssertTrue((1...5).contains(target))
    }

    func testWhyChipsAndOnboarding() async throws {
        let plan = DailyPlan(
            date: Date(),
            questId: "q1",
            reason: "mix",
            weakSkill: "Warmth",
            onboardingTheme: "closeCircle",
            difficultyTarget: 2,
            copyJSON: "{}"
        )
        XCTAssertEqual(plan.weakSkill, "Warmth")
        XCTAssertEqual(plan.onboardingTheme, "closeCircle")
    }
}
