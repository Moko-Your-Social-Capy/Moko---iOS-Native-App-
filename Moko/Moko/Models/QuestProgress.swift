//
//  QuestProgress.swift
//  Moko
//
//  Shared updates for completed quests: XP, daily streak and debrief insights.
//  Streak is computed from ActivityRecord rows via StreakService — the single
//  source of truth — not from Profile fields.
//

import Foundation
import OSLog
import SwiftData

/// The XP and streak that a completed quest contributes.
struct QuestReward: Equatable {
    var xp: Int
    var streak: Int
}

enum QuestProgress {

    /// Marks the quest complete and awards its XP, streak and activity date once.
    /// Streak comes from `StreakService` which computes it from `ActivityRecord`
    /// rows, so every screen shares the same underlying data.
    @MainActor
    @discardableResult
    static func complete(
        _ quest: Quest,
        in context: ModelContext,
        at date: Date = .now
    ) -> QuestReward {
        if quest.modelContext == nil {
            context.insert(quest)
        }
        let profile = profile(in: context)
        quest.isCompleted = true
        if quest.completedAt == nil { quest.completedAt = date }

        if !quest.xpAwarded {
            // Single source of truth: record the activity and compute streak
            // from ActivityRecord rows via StreakService.
            let stats = StreakService.shared.recordActivity(
                type: .quest,
                referenceID: quest.id,
                in: context,
                at: date
            )

            profile.xp += quest.awardedXP
            profile.currentStreak = stats.currentStreak
            profile.longestStreak = stats.longestStreak
            profile.lastActivityDate = stats.lastActivityDate ?? date
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
        let reward = complete(quest, in: context, at: date)

        guard !quest.debriefRecorded else { return reward }

        // Insights stores a debrief only when every stat has real evidence. Partial
        // score distributions remain available in the calibration store; no baseline is invented.
        if let courage = result.scores[.courage], let clarity = result.scores[.clarity],
           let presence = result.scores[.presence], let warmth = result.scores[.warmth] {
            context.insert(
                InsightsModel(
                    courage: courage,
                    clarity: clarity,
                    presence: presence,
                    warmth: warmth,
                    date: date
                )
            )
        }
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
            Logger.data.error("Quest progress save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
