// DailyMissionService.swift
// Ensures a fresh, tailored daily mission is always available for the user.
// Integrates with AFM (QuestCardService.freshDailyCard) and MissionBank so the
// user always has an active mission on the Overview screen instead of "No Active Quest".
//
// ADAPTIVE BEHAVIOR:
//   1. Lowest-Scored Parameter Focus: When no custom quest is upcoming, the daily mission
//      targets the user's lowest-scored parameter from Insights (Courage, Clarity, Presence, or Warmth)
//      across diverse life categories (Work, Dating, Friends, Family).
//   2. Custom Quest Preparation: When an upcoming custom quest exists, daily missions act
//      as stepping stones leading up to it. To prevent boredom and avoid spoon-feeding,
//      categories alternate between different domains (foundational social skills) and
//      similar situations to prepare directly for the event.
//   3. Equal Evaluation: During debrief, all parameters continue to be evaluated with equal importance.

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

    // MARK: - Lowest Scored Parameter

    /// Analyzes the user's Insights records to find their lowest scored parameter.
    static func lowestScoredStat(in modelContext: ModelContext) -> Stat? {
        let descriptor = FetchDescriptor<InsightsModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else {
            return nil
        }
        let count = Double(records.count)
        let courage = Double(records.reduce(0) { $0 + $1.courage }) / count
        let clarity = Double(records.reduce(0) { $0 + $1.clarity }) / count
        let presence = Double(records.reduce(0) { $0 + $1.presence }) / count
        let warmth = Double(records.reduce(0) { $0 + $1.warmth }) / count

        let stats: [(Stat, Double)] = [
            (.courage, courage),
            (.clarity, clarity),
            (.presence, presence),
            (.warmth, warmth)
        ]
        return stats.min(by: { $0.1 < $1.1 })?.0
    }

    /// Template matching a targeted growth parameter across diverse categories
    static func templateForStat(_ stat: Stat, dayOfYear: Int) -> MissionTemplate {
        let matching: [MissionTemplate]
        switch stat {
        case .courage:
            matching = MissionBank.all.filter {
                ["work-speak-up-meeting", "work-introduce-new-job", "dating-first-message", "friends-suggest-hangout", "family-share-small"].contains($0.id)
            }
        case .clarity:
            matching = MissionBank.all.filter {
                ["work-decline-extra", "dating-suggest-place", "dating-end-it", "friends-turn-down-plan", "family-ask-help", "family-visit-boundary"].contains($0.id)
            }
        case .presence:
            matching = MissionBank.all.filter {
                ["work-correct-boss", "friends-admit-dont-know", "family-correct-narrative", "dating-exclusivity"].contains($0.id)
            }
        case .warmth:
            matching = MissionBank.all.filter {
                ["dating-name-what-you-felt", "friends-bring-up-distance", "family-unspoken-thing", "friends-say-hurt", "work-feedback-after-mistake"].contains($0.id)
            }
        }
        guard !matching.isEmpty else { return templateForDay(dayOfYear) }
        return matching[dayOfYear % matching.count]
    }

    // MARK: - Upcoming Custom Quest Prep

    /// Finds the soonest incomplete custom quest scheduled for a future day.
    static func upcomingCustomQuest(from existingQuests: [Quest], calendar: Calendar = .current) -> Quest? {
        let now = Date()
        return existingQuests
            .filter { !$0.isFromLibrary && !$0.isCompleted && !calendar.isDateInToday($0.date) && $0.date > now }
            .min(by: { $0.date < $1.date })
    }

    /// Chooses a stepping-stone template to prepare for an upcoming custom quest.
    /// Rotates categories on alternating days to prevent boredom / spoon-feeding while
    /// scheduling similar-situation tasks on other days to prepare for the real event.
    static func preparationTemplate(for upcoming: Quest, daysRemaining: Int, dayOfYear: Int) -> MissionTemplate {
        let all = MissionBank.all

        if daysRemaining <= 1 {
            // Day right before the event: pick a similar situation in the same category as rehearsal
            let sameCategoryPool = all.filter { $0.category == upcoming.category }
            if let matched = sameCategoryPool.first {
                return matched
            }
        } else if daysRemaining % 2 == 0 {
            // Even days remaining: pick a foundational stepping stone from a DIFFERENT category
            // (e.g. Work or Family if the custom quest is Friends) to build general social comfort without spoon-feeding
            let otherCategoryPool = all.filter { $0.category != upcoming.category }
            if !otherCategoryPool.isEmpty {
                return otherCategoryPool[(dayOfYear + daysRemaining) % otherCategoryPool.count]
            }
        } else {
            // Odd days remaining: pick a similar situation in the same category
            let sameCategoryPool = all.filter { $0.category == upcoming.category }
            if !sameCategoryPool.isEmpty {
                return sameCategoryPool[(dayOfYear + daysRemaining) % sameCategoryPool.count]
            }
        }

        return templateForDay(dayOfYear)
    }

    // MARK: - Overview daily mission

    /// Ensures today's featured (Overview) mission exists in SwiftData.
    /// Returns it immediately if it already exists; otherwise creates one via AFM / bank fallback.
    @discardableResult
    static func ensureDailyMission(in modelContext: ModelContext, existingQuests: [Quest]) async -> Quest? {
        let calendar = Calendar.current
        let now = Date()

        // 1. If an active incomplete quest or a completed quest awaiting debrief exists, use it
        if let existing = Quest.overviewMission(from: existingQuests) {
            return existing
        }

        // 2. If any non-library quest was scheduled for TODAY, return the first one
        let todayCustom = existingQuests.filter { calendar.isDateInToday($0.date) && !$0.isFromLibrary }
        if let firstToday = todayCustom.first {
            // Also seed any missing category quests in the background
            Task {
                await seedRemainingCategories(
                    in: modelContext,
                    existingQuests: existingQuests,
                    featuredCategory: firstToday.category,
                    dayOfYear: calendar.ordinality(of: .day, in: .year, for: now) ?? 1
                )
            }
            return firstToday
        }

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let recentTitles = existingQuests.prefix(10).map(\.title)

        // 3. Check for upcoming custom quest
        let upcoming = upcomingCustomQuest(from: existingQuests, calendar: calendar)

        let template: MissionTemplate
        let practiceFor: String?
        let dayNumber: Int
        let totalDays: Int
        let focusStat: Stat?

        if let upcoming {
            // Preparation mode for upcoming custom quest
            let start = calendar.startOfDay(for: now)
            let end = calendar.startOfDay(for: upcoming.date)
            let daysRemaining = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
            totalDays = max(daysRemaining + 1, 3)
            dayNumber = max(1, totalDays - daysRemaining)
            practiceFor = upcoming.title
            focusStat = lowestScoredStat(in: modelContext)

            template = preparationTemplate(for: upcoming, daysRemaining: daysRemaining, dayOfYear: dayOfYear)
        } else {
            // Standard mode: focus on lowest scored parameter across diverse categories
            let lowest = lowestScoredStat(in: modelContext)
            focusStat = lowest
            practiceFor = nil
            dayNumber = dayOfYear
            totalDays = 1

            if let lowest {
                template = templateForStat(lowest, dayOfYear: dayOfYear)
            } else {
                template = templateForDay(dayOfYear)
            }
        }

        let card = await QuestCardService.freshDailyCard(
            from: template,
            recentTitles: recentTitles,
            seed: "moko-daily-\(dayOfYear)-\(focusStat?.rawValue ?? "standard")",
            dayNumber: dayNumber,
            totalDays: totalDays,
            practiceFor: practiceFor,
            focusStat: focusStat
        )

        let dailyQuest = Quest(
            ownerID: CurrentUser.localID,
            title: card.title,
            notes: card.goal,
            intensity: card.difficulty.intensity,
            category: card.category,
            date: now
        )

        modelContext.insert(dailyQuest)
        try? modelContext.save()

        // Seed remaining categories asynchronously so the Quests list has variety across all life areas
        Task {
            await seedRemainingCategories(
                in: modelContext,
                existingQuests: existingQuests + [dailyQuest],
                featuredCategory: card.category,
                dayOfYear: dayOfYear
            )
        }

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
    static func todayFallbackQuest(existingQuests: [Quest] = [], lowestStat: Stat? = nil) -> Quest {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1

        let template: MissionTemplate
        if let upcoming = upcomingCustomQuest(from: existingQuests, calendar: calendar) {
            let start = calendar.startOfDay(for: Date())
            let end = calendar.startOfDay(for: upcoming.date)
            let daysRemaining = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
            template = preparationTemplate(for: upcoming, daysRemaining: daysRemaining, dayOfYear: dayOfYear)
        } else if let stat = lowestStat {
            template = templateForStat(stat, dayOfYear: dayOfYear)
        } else {
            template = templateForDay(dayOfYear)
        }

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


