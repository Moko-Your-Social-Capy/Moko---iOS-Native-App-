// DailyMissionService.swift
// Ensures a fresh, tailored daily mission is always available for the user.
// Integrates with AFM (QuestCardService.freshDailyCard) and MissionBank so the
// user always has an active mission on the Overview screen instead of "No Active Quest".
//
// DESIGN:
//   • Overview daily mission  → round-robin across categories (work/friends/dating/family), one per day.
//   • Quests list             → seeded with one mission per remaining category so all 4 are visible.
//     Both use the bank + AFM invention, but only the Overview mission is the "active" mission.

import Foundation
import SwiftData

@MainActor
enum DailyMissionService {

    // Category rotation order — 4 life areas that have Mission Bank templates, cycling day by day.
    // Pattern: work → friends → dating → family → work → friends → …
    private static let categoryRotation: [QuestCategory] = [
        .work, .friends, .dating, .family
    ]

    /// Returns the template to use for a given day's featured (Overview) mission.
    private static func templateForDay(_ dayOfYear: Int) -> MissionTemplate {
        let all = MissionBank.all
        let category = categoryRotation[dayOfYear % categoryRotation.count]
        let pool = all.filter { $0.category == category }
        guard !pool.isEmpty else { return all[dayOfYear % all.count] }
        return pool[dayOfYear % pool.count]
    }

    // MARK: - Overview daily mission

    /// Ensures today's featured (Overview) mission exists in SwiftData.
    /// Returns it immediately if it already exists; otherwise creates one via AFM / bank fallback.
    @discardableResult
    static func ensureDailyMission(in modelContext: ModelContext, existingQuests: [Quest]) async -> Quest? {
        let calendar = Calendar.current

        // If an active incomplete quest or a completed quest awaiting debrief exists, use it
        if let existing = Quest.overviewMission(from: existingQuests) {
            return existing
        }

        // If any non-library quest was scheduled for today, return the first one
        let todayCustom = existingQuests.filter { calendar.isDateInToday($0.date) && !$0.isFromLibrary }
        if let firstToday = todayCustom.first {
            // Also seed any missing category quests in the background
            Task { await seedRemainingCategories(in: modelContext, existingQuests: existingQuests, featuredCategory: firstToday.category, dayOfYear: calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1) }
            return firstToday
        }

        // No quest for today yet — create the featured (Overview) mission
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let template = templateForDay(dayOfYear)
        let recentTitles = existingQuests.prefix(10).map(\.title)

        let card = await QuestCardService.freshDailyCard(
            from: template,
            recentTitles: recentTitles,
            seed: "moko-daily-\(dayOfYear)",
            dayNumber: dayOfYear
        )

        let dailyQuest = Quest(
            ownerID: CurrentUser.localID,
            title: card.title,
            notes: card.goal,
            intensity: card.difficulty.intensity,
            category: card.category,
            date: Date()
        )

        modelContext.insert(dailyQuest)
        try? modelContext.save()

        // Seed remaining categories asynchronously so the Quests list has variety
        Task { await seedRemainingCategories(in: modelContext, existingQuests: existingQuests + [dailyQuest], featuredCategory: card.category, dayOfYear: dayOfYear) }

        return dailyQuest
    }

    // MARK: - Quests list variety seeding

    /// Creates one quest per category (excluding the featured category already created) so the
    /// Quests tab shows missions from all life areas, not just today's featured one.
    private static func seedRemainingCategories(
        in modelContext: ModelContext,
        existingQuests: [Quest],
        featuredCategory: QuestCategory,
        dayOfYear: Int
    ) async {
        let calendar = Calendar.current
        let todayCategories = Set(
            existingQuests
                .filter { calendar.isDateInToday($0.date) && !$0.isFromLibrary }
                .map { $0.category }
        )

        let recentTitles = existingQuests.prefix(15).map(\.title)
        let remaining = categoryRotation.filter { !todayCategories.contains($0) }

        for (offset, category) in remaining.enumerated() {
            let all = MissionBank.all
            let pool = all.filter { $0.category == category }
            guard !pool.isEmpty else { continue }
            // Offset seed per category so each gets a distinct bank template
            let seedIndex = (dayOfYear + offset + 1) % pool.count
            let template = pool[seedIndex]

            let card = await QuestCardService.freshDailyCard(
                from: template,
                recentTitles: recentTitles,
                seed: "moko-variety-\(dayOfYear)-\(category.rawValue)",
                dayNumber: dayOfYear + offset + 1
            )

            let quest = Quest(
                ownerID: CurrentUser.localID,
                title: card.title,
                notes: card.goal,
                intensity: card.difficulty.intensity,
                category: card.category,
                date: Date()
            )
            modelContext.insert(quest)
        }
        try? modelContext.save()
    }

    // MARK: - Synchronous fallback

    /// Instant synchronous fallback quest from the Mission Bank to guarantee
    /// the Overview UI never shows an empty placeholder.
    static func todayFallbackQuest() -> Quest {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let template = templateForDay(dayOfYear)

        return Quest(
            ownerID: CurrentUser.localID,
            title: template.title,
            notes: template.goal,
            intensity: template.difficulty.intensity,
            category: template.category,
            date: Date()
        )
    }
}


