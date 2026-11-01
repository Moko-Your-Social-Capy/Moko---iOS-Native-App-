//
//  QuestProgress.swift
//  Moko
//
//  Shared updates for completed quests: XP, daily streak and debrief insights.
//

import Foundation
import SwiftData

/// The XP and streak that a completed quest contributes.
struct QuestReward: Equatable {
    var xp: Int
    var streak: Int
}

enum QuestProgress {

    /// The streak after activity on `date`: same day keeps the streak,
    /// the next day extends it, one rest day is allowed after seven active days,
    /// and a longer gap starts a new one.
    static func nextStreak(
        current: Int,
        lastActivity: Date?,
        at date: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard let lastActivity else { return 1 }

        if calendar.isDate(lastActivity, inSameDayAs: date) {
            return max(current, 1)
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
           calendar.isDate(lastActivity, inSameDayAs: yesterday) {
            return max(current, 0) + 1
        }

        // One missed calendar day is a rest day once the user has built a week-long streak.
        if current >= 7, current.isMultiple(of: 7),
           let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: date),
           calendar.isDate(lastActivity, inSameDayAs: twoDaysAgo) {
            return current
        }

        return 1
    }

    /// Marks the quest complete and awards its XP, streak and activity date once.
    @MainActor
    @discardableResult
    static func complete(
        _ quest: Quest,
        in context: ModelContext,
        at date: Date = .now,
        calendar: Calendar = .current
    ) -> QuestReward {
        let profile = profile(in: context)
        quest.isCompleted = true
        if quest.completedAt == nil { quest.completedAt = date }

        if !quest.xpAwarded {
            let streak = nextStreak(
                current: profile.currentStreak,
                lastActivity: profile.lastActivityDate,
                at: date,
                calendar: calendar
            )

            profile.xp += quest.awardedXP
            profile.currentStreak = streak
            profile.longestStreak = max(profile.longestStreak, streak)
            profile.lastActivityDate = date
            profile.updatedAt = date
            quest.xpAwarded = true
        }

        save(context)
        return QuestReward(xp: quest.awardedXP, streak: profile.currentStreak)
    }

    /// Saves a finished debrief as an Insights entry and makes sure the quest
    /// has been awarded. Reopening the same debrief cannot duplicate either.
    @MainActor
    @discardableResult
    static func saveDebrief(
        _ result: DebriefResult,
        for quest: Quest,
        in context: ModelContext,
        at date: Date = .now,
        calendar: Calendar = .current
    ) -> QuestReward {
        let reward = complete(quest, in: context, at: date, calendar: calendar)

        guard !quest.debriefRecorded else { return reward }

        context.insert(
            InsightsModel(
                courage: result.scores[.courage] ?? 0,
                clarity: result.scores[.clarity] ?? 0,
                presence: result.scores[.presence] ?? 0,
                warmth: result.scores[.warmth] ?? 0,
                date: date
            )
        )
        quest.debriefRecorded = true
        save(context)

        return reward
    }

    private static func profile(in context: ModelContext) -> Profile {
        if let existing = (try? context.fetch(FetchDescriptor<Profile>()))?.first {
            return existing
        }

        let newProfile = Profile(username: "", age: 0)
        context.insert(newProfile)
        return newProfile
    }

    private static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("Quest progress save failed:", error)
        }
    }
}
