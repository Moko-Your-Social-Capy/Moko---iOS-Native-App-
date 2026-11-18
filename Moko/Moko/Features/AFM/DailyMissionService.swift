//
//  DailyMissionService.swift
//  Moko
//
//  Makes sure the Overview always has today's mission (never "No Active Quest").
//  Missions come from the Mission Bank; AFM may freshen the wording
//  (`QuestCardService.freshDailyCard` in MokoMissionInvention.swift).
//
//  How today's mission is chosen:
//    1. No upcoming custom quest → practise the user's LOWEST stat from Insights,
//       rotating through Work, Friends, Dating and Family.
//    2. An upcoming custom quest → daily missions are stepping stones toward it.
//       They alternate between a different life area (general practice) and the
//       quest's own area (close rehearsal), so it never feels like spoon-feeding.
//    3. The debrief still scores all four stats equally either way.
//
//  Called from `MokoRootView`'s `.task`. Debug tip: if missions appear twice,
//  check that nothing else calls `ensureDailyMission` without awaiting it.
//

import Foundation
import SwiftData

@MainActor
enum DailyMissionService {

    /// The four life areas with Mission Bank templates, cycled one per day.
    private static let categoryRotation: [QuestCategory] = [
        .work, .friends, .dating, .family
    ]

    /// Which bank missions practise each stat best.
    private static let templateIDsByStat: [Stat: [String]] = [
        .courage: ["work-speak-up-meeting", "work-introduce-new-job", "dating-first-message",
                   "friends-suggest-hangout", "family-share-small"],
        .clarity: ["work-decline-extra", "dating-suggest-place", "dating-end-it",
                   "friends-turn-down-plan", "family-ask-help", "family-visit-boundary"],
        .presence: ["work-correct-boss", "friends-admit-dont-know", "family-correct-narrative",
                    "dating-exclusivity"],
        .warmth: ["dating-name-what-you-felt", "friends-bring-up-distance", "family-unspoken-thing",
                  "friends-say-hurt", "work-feedback-after-mistake"],
    ]

    // MARK: - Date helpers

    /// 1 on 1 January, 365 (or 366) on 31 December. Used to rotate missions day by day.
    private static func dayOfYear(_ date: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    /// Whole days from today until `quest`'s day, never less than 1.
    private static func daysUntil(_ quest: Quest, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: quest.date)
        return max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
    }

    // MARK: - Template choice

    /// The template for a day when there is nothing more specific to practise.
    private static func templateForDay(_ dayOfYear: Int) -> MissionTemplate {
        let all = MissionBank.all
        let category = categoryRotation[dayOfYear % categoryRotation.count]
        let pool = all.filter { $0.category == category }
        guard !pool.isEmpty else { return all[dayOfYear % all.count] }
        return pool[dayOfYear % pool.count]
    }

    /// Averages every saved Insights record and returns the weakest stat,
    /// or nil if the user has no Insights yet.
    static func lowestScoredStat(in modelContext: ModelContext) -> Stat? {
        let descriptor = FetchDescriptor<InsightsModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else {
            return nil
        }
        let count = Double(records.count)
        let averages: [(Stat, Double)] = [
            (.courage, Double(records.reduce(0) { $0 + $1.courage }) / count),
            (.clarity, Double(records.reduce(0) { $0 + $1.clarity }) / count),
            (.presence, Double(records.reduce(0) { $0 + $1.presence }) / count),
            (.warmth, Double(records.reduce(0) { $0 + $1.warmth }) / count),
        ]
        return averages.min(by: { $0.1 < $1.1 })?.0
    }

    /// A bank mission that practises `stat`, rotating through the matching ones day by day.
    static func templateForStat(_ stat: Stat, dayOfYear: Int) -> MissionTemplate {
        let ids = templateIDsByStat[stat] ?? []
        let matching = MissionBank.all.filter { ids.contains($0.id) }
        guard !matching.isEmpty else { return templateForDay(dayOfYear) }
        return matching[dayOfYear % matching.count]
    }

    /// The soonest unfinished custom quest set for a later day (not today).
    static func upcomingCustomQuest(from existingQuests: [Quest], calendar: Calendar = .current) -> Quest? {
        let now = Date.now
        return existingQuests
            .filter { !$0.isFromLibrary && !$0.isCompleted && !calendar.isDateInToday($0.date) && $0.date > now }
            .min(by: { $0.date < $1.date })
    }

    /// A stepping-stone mission before an upcoming custom quest:
    /// - 1 day left: the quest's own area, as a rehearsal.
    /// - Even days left: a DIFFERENT area, for general social practice.
    /// - Odd days left: the quest's own area, a similar situation.
    static func preparationTemplate(for upcoming: Quest, daysRemaining: Int, dayOfYear: Int) -> MissionTemplate {
        let all = MissionBank.all
        let sameArea = all.filter { $0.category == upcoming.category }
        let otherAreas = all.filter { $0.category != upcoming.category }
        let index = dayOfYear + daysRemaining

        if daysRemaining <= 1 {
            if let rehearsal = sameArea.first { return rehearsal }
        } else if daysRemaining % 2 == 0 {
            if !otherAreas.isEmpty { return otherAreas[index % otherAreas.count] }
        } else if !sameArea.isEmpty {
            return sameArea[index % sameArea.count]
        }
        return templateForDay(dayOfYear)
    }

    // MARK: - Overview daily mission

    /// The run that is creating today's mission right now, if any. A second caller
    /// waits for this one instead of creating a duplicate mission.
    // Share only the saved ID; the quest itself stays in its SwiftData context.
    private static var runningMission: Task<PersistentIdentifier?, Never>?

    /// True while `seedRemainingCategories` is working, so two copies never run at once.
    private static var isSeeding = false

    /// Ensures today's featured (Overview) mission exists in SwiftData.
    /// Returns it immediately if it already exists; otherwise creates one via AFM / bank fallback.
    /// Safe to call from several screens at once: only one mission is ever created.
    @discardableResult
    static func ensureDailyMission(in modelContext: ModelContext, existingQuests: [Quest]) async -> Quest? {
        if let runningMission {
            guard let identifier = await runningMission.value else { return nil }
            // Read the shared quest through the caller's own SwiftData context.
            return modelContext.model(for: identifier) as? Quest
        }
        let run = Task { @MainActor in
            let quest = await makeDailyMission(in: modelContext, existingQuests: existingQuests)
            return quest?.persistentModelID
        }
        runningMission = run
        // `defer` clears the guard when this function finishes, so tomorrow can run again.
        defer { runningMission = nil }
        guard let identifier = await run.value else { return nil }
        // Resolve the ID here so a model is never returned across task boundaries.
        return modelContext.model(for: identifier) as? Quest
    }

    private static func makeDailyMission(in modelContext: ModelContext, existingQuests: [Quest]) async -> Quest? {
        let calendar = Calendar.current
        let today = dayOfYear(calendar: calendar)

        // 1. A quest that is in progress or waiting for its debrief wins.
        if let existing = Quest.overviewMission(from: existingQuests) {
            return existing
        }

        // 2. A custom quest the user set for today.
        if let todaysCustom = existingQuests.first(where: { calendar.isDateInToday($0.date) && !$0.isFromLibrary }) {
            startSeeding(in: modelContext, existingQuests: existingQuests,
                         featuredCategory: todaysCustom.category, dayOfYear: today)
            return todaysCustom
        }

        // 3. Otherwise make a new one: prepare for an upcoming quest, or practise the weakest stat.
        let template: MissionTemplate
        let practiceFor: String?
        let dayNumber: Int
        let totalDays: Int
        let focusStat = lowestScoredStat(in: modelContext)

        if let upcoming = upcomingCustomQuest(from: existingQuests, calendar: calendar) {
            let daysRemaining = daysUntil(upcoming, calendar: calendar)
            totalDays = max(daysRemaining + 1, 3)
            dayNumber = max(1, totalDays - daysRemaining)
            practiceFor = upcoming.title
            template = preparationTemplate(for: upcoming, daysRemaining: daysRemaining, dayOfYear: today)
        } else {
            totalDays = 1
            dayNumber = today
            practiceFor = nil
            template = focusStat.map { templateForStat($0, dayOfYear: today) } ?? templateForDay(today)
        }

        // AFM may invent a fresh version; if not, the bank text is used as is.
        let card = await QuestCardService.freshDailyCard(
            from: template,
            recentTitles: existingQuests.prefix(10).map(\.title),
            seed: "moko-daily-\(today)-\(focusStat?.rawValue ?? "standard")",
            dayNumber: dayNumber,
            totalDays: totalDays,
            practiceFor: practiceFor,
            focusStat: focusStat
        )

        let dailyQuest = makeQuest(from: card)
        modelContext.insert(dailyQuest)
        modelContext.saveOrLog("daily mission")

        startSeeding(in: modelContext, existingQuests: existingQuests + [dailyQuest],
                     featuredCategory: card.category, dayOfYear: today)
        return dailyQuest
    }

    // MARK: - Quests list variety seeding

    /// Starts `seedRemainingCategories` in the background, unless it is already running.
    /// `Task { }` lets today's mission show right away instead of waiting for the extra quests.
    private static func startSeeding(in modelContext: ModelContext,
                                     existingQuests: [Quest],
                                     featuredCategory: QuestCategory,
                                     dayOfYear: Int) {
        guard !isSeeding else { return }
        isSeeding = true
        Task {
            defer { isSeeding = false }
            await seedRemainingCategories(in: modelContext, existingQuests: existingQuests,
                                          featuredCategory: featuredCategory, dayOfYear: dayOfYear)
        }
    }

    /// Creates one quest for each life area that has none today, so the Quests tab
    /// shows variety and not just today's featured mission.
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
                .map(\.category)
        )
        let recentTitles = existingQuests.prefix(15).map(\.title)
        let remaining = categoryRotation.filter { !todayCategories.contains($0) }
        guard !remaining.isEmpty else { return }

        for (offset, category) in remaining.enumerated() {
            guard !Task.isCancelled else { return }
            let pool = MissionBank.all.filter { $0.category == category }
            guard !pool.isEmpty else { continue }
            // A different offset per category, so each one gets a different bank mission.
            let template = pool[(dayOfYear + offset + 1) % pool.count]

            let card = await QuestCardService.freshDailyCard(
                from: template,
                recentTitles: recentTitles,
                seed: "moko-variety-\(dayOfYear)-\(category.rawValue)",
                dayNumber: dayOfYear + offset + 1
            )
            modelContext.insert(makeQuest(from: card))
            // Brief pause between background category generations to yield to interactive turns.
            try? await Task.sleep(for: .milliseconds(300))
        }
        modelContext.saveOrLog("category quests")
    }

    /// A new, unsaved quest for today from an AFM / bank card.
    private static func makeQuest(from card: QuestCard) -> Quest {
        Quest(
            ownerID: CurrentUser.localID,
            title: card.title,
            notes: card.goal,
            intensity: card.difficulty.intensity,
            category: card.category,
            date: .now
        )
    }

    // MARK: - Synchronous fallback

    /// An instant (no AFM) mission from the bank, so the Overview is never empty while
    /// the real one is being made. NOT saved: it is a new, unsaved `Quest` on every call.
    static func todayFallbackQuest(existingQuests: [Quest] = [], lowestStat: Stat? = nil) -> Quest {
        let today = dayOfYear()

        let template: MissionTemplate
        if let upcoming = upcomingCustomQuest(from: existingQuests) {
            template = preparationTemplate(for: upcoming, daysRemaining: daysUntil(upcoming), dayOfYear: today)
        } else if let lowestStat {
            template = templateForStat(lowestStat, dayOfYear: today)
        } else {
            template = templateForDay(today)
        }

        return Quest(
            ownerID: CurrentUser.localID,
            title: template.title,
            notes: template.goal,
            intensity: template.difficulty.intensity,
            category: template.category,
            date: .now
        )
    }
}
