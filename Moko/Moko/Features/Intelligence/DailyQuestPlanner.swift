import Foundation
import SwiftData

struct LibraryQuestItem: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var situation: String
    var step: String
    var tryThis: String
    var skills: [String]
    var difficulty: Int // 1-5
    var category: String
    var onboardingTheme: String
    var stage: String // closeCircle | newGroups | withinGroup | family
    var estimatedMinutes: Int
    var tip: String
}

enum DailyQuestPlannerConstants {
    static let weakSkillRatio: Double = 0.6
    static let onboardingPathRatio: Double = 0.4
    static let minSessionsFor7Day: Int = 3
}

enum DailyQuestPlanner {

    /// Compute and store tomorrow's DailyPlan immediately after a debrief is saved (idempotent).
    @MainActor
    static func generateTomorrowPlan(modelContext: ModelContext, availableQuests: [LibraryQuestItem], replaceExisting: Bool = true) async {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)

        // Safe to call repeatedly: an existing plan is only replaced when today's
        // lowest-scoring skill has changed and tomorrow's plan hasn't been started.
        let newWeakSkill = determineWeakSkill(modelContext: modelContext)
        let descriptor = FetchDescriptor<DailyPlan>(predicate: #Predicate { $0.date == startOfTomorrow })
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            let started = existing.contains { $0.status != "planned" }
            let upToDate = existing.allSatisfy { $0.weakSkill == newWeakSkill }
            guard replaceExisting, !started, !upToDate else { return }
            existing.forEach { modelContext.delete($0) }
        }

        let plan = await computePlan(for: startOfTomorrow, modelContext: modelContext, availableQuests: availableQuests)
        modelContext.insert(plan)
        try? modelContext.save()
    }

    @MainActor
    static func promotePlanIfNeeded(modelContext: ModelContext, availableQuests: [LibraryQuestItem]) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyPlan>(sortBy: [SortDescriptor(\.date)])
        guard let plans = try? modelContext.fetch(descriptor) else { return }

        // Plans for today or earlier that were only "planned" become active
        var changed = false
        for plan in plans where plan.date <= today && plan.status == "planned" {
            plan.status = "active"
            changed = true
        }
        if changed { try? modelContext.save() }

        // No plan for today yet: create one on demand
        let todayDescriptor = FetchDescriptor<DailyPlan>(predicate: #Predicate { $0.date == today })
        let todaysPlans = (try? modelContext.fetch(todayDescriptor)) ?? []
        if todaysPlans.isEmpty {
            let plan = await computePlan(for: today, modelContext: modelContext, availableQuests: availableQuests)
            plan.status = "active"
            modelContext.insert(plan)
            try? modelContext.save()
        }
    }

    @MainActor
    private static func computePlan(for targetDate: Date, modelContext: ModelContext, availableQuests: [LibraryQuestItem]) async -> DailyPlan {
        let weakSkill = determineWeakSkill(modelContext: modelContext)
        let onboardingTheme = determineOnboardingPath(modelContext: modelContext)

        let reason: String
        let chosenQuest: LibraryQuestItem

        let userStage = onboardingTheme.isEmpty ? "closeCircle" : onboardingTheme

        if let weakSkill {
            // Auto-generate a quest for the lowest-scoring skill in today's insights
            chosenQuest = await DailyQuestTemplateGenerator.generateQuest(forSkill: weakSkill, stage: userStage)
            reason = "weakSkill"
        } else if let q = availableQuests.first(where: { $0.stage == userStage }) {
            reason = "onboardingPath"
            chosenQuest = q
        } else {
            reason = "onboardingPath"
            chosenQuest = availableQuests.first ?? LibraryQuestItem(
                id: "default",
                title: "Gentle Connection",
                situation: "A quiet moment with someone nearby.",
                step: "Smile and say hello.",
                tryThis: "Hello!",
                skills: ["Warmth"],
                difficulty: 1,
                category: "Friends",
                onboardingTheme: "closeCircle",
                stage: "closeCircle",
                estimatedMinutes: 2,
                tip: "Take a deep breath first."
            )
        }

        let difficultyTarget = determineDifficulty(modelContext: modelContext, questDifficulty: chosenQuest.difficulty)
        let copy = await DailyQuestTemplateGenerator.generate(
            title: chosenQuest.title,
            situation: chosenQuest.situation,
            step: chosenQuest.step,
            tryThis: chosenQuest.tryThis,
            estimatedMinutes: chosenQuest.estimatedMinutes,
            category: chosenQuest.category,
            difficulty: difficultyTarget
        )

        let copyData = (try? JSONEncoder().encode(copy)) ?? Data()
        let copyJSON = String(data: copyData, encoding: .utf8) ?? "{}"

        return DailyPlan(
            date: targetDate,
            questId: chosenQuest.id,
            reason: reason,
            weakSkill: weakSkill,
            onboardingTheme: userStage,
            difficultyTarget: difficultyTarget,
            copyJSON: copyJSON
        )
    }

    /// Lowest of the four skills in today's saved insights. If nothing was saved today it uses
    /// the most recent day with insights in the last 7 days. Returns nil when there are none.
    private static func determineWeakSkill(modelContext: ModelContext) -> String? {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        let descriptor = FetchDescriptor<InsightsModel>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let recent = try? modelContext.fetch(descriptor), let latest = recent.first else { return nil }
        let rows = recent.filter { calendar.isDate($0.date, inSameDayAs: latest.date) }

        let n = Double(rows.count)
        let averages: [(name: String, value: Double)] = [
            ("Courage", rows.reduce(0.0) { $0 + Double($1.courage) } / n),
            ("Clarity", rows.reduce(0.0) { $0 + Double($1.clarity) } / n),
            ("Presence", rows.reduce(0.0) { $0 + Double($1.presence) } / n),
            ("Warmth", rows.reduce(0.0) { $0 + Double($1.warmth) } / n)
        ]
        return averages.min { $0.value < $1.value }?.name
    }

    // TODO: read the real onboarding stage from OnboardingState once its fields are known.
    private static func determineOnboardingPath(modelContext: ModelContext) -> String {
        return "closeCircle"
    }

    private static func determineDifficulty(modelContext: ModelContext, questDifficulty: Int) -> Int {
        return max(1, min(5, questDifficulty))
    }
}
