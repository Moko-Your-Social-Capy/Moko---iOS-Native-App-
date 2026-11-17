//
//  StreakService.swift
//  Moko
//
//  The single source of truth for streak data. Every screen (profile,
//  calendar, detail, widgets, Live Activity) computes its streak numbers
//  from ActivityRecord rows via this service instead of keeping its own
//  copy.
//
//  Streak policy (defined here, implemented here, used everywhere):
//  - A calendar day counts as "active" when it has at least one completed
//    qualifying activity. Multiple activities on the same day count once
//    (per-calendar-day deduplication).
//  - Same day: streak stays the same.
//  - Next calendar day: streak extends by 1.
//  - One rest day after every 7 active days: a 1-day gap is allowed when
//    the current streak is a multiple of 7 (7, 14, 21 …); the streak value
//    does not increase but is not reset either.
//  - Any longer gap: streak resets to 1 on the next active day.
//  - All dates are normalised to the start of the calendar day in the
//    user's time zone, so midnight crossings, DST changes and time-zone
//    changes are handled by Calendar.current automatically.
//

import Foundation
import SwiftData
import OSLog

/// The result of a streak computation.
struct StreakStats: Sendable {
    /// Current streak (0 if broken).
    var currentStreak: Int
    /// Best streak ever.
    var longestStreak: Int
    /// Number of distinct active calendar days.
    var totalActiveDays: Int
    /// Start-of-day dates for every active day.
    var activeDates: Set<Date>
    /// Most recent active date.
    var lastActivityDate: Date?
}

/// Centralised streak computation. All streak numbers flow through here.
@MainActor
@Observable
final class StreakService {

    static let shared = StreakService()

    private let calendar = Calendar.current
    private let logger = Logger(subsystem: "Moko", category: "StreakService")

    private init() {}

    // MARK: - Computation

    /// Computes streak statistics from activity records.
    ///
    /// The forward pass simulates how the streak built up day by day,
    /// applying the rest-day rule exactly as `QuestProgress.nextStreak`
    /// did, so the result matches the historic behaviour.
    func stats(from records: [ActivityRecord], at date: Date = .now) -> StreakStats {
        // Normalise to start of day and deduplicate: one active day per calendar day.
        let activeDays = Set(records.map { calendar.startOfDay(for: $0.activityDate) })
        let sortedDates = activeDays.sorted()

        guard !sortedDates.isEmpty else {
            return StreakStats(
                currentStreak: 0,
                longestStreak: 0,
                totalActiveDays: 0,
                activeDates: [],
                lastActivityDate: nil
            )
        }

        let today = calendar.startOfDay(for: date)

        // Forward pass: simulate the streak as it built up.
        var streak = 0
        var longest = 0
        var lastDate: Date?

        for day in sortedDates {
            if let last = lastDate {
                if calendar.isDate(last, inSameDayAs: day) {
                    continue // deduplicated already, but stay safe
                }
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: last),
                   calendar.isDate(nextDay, inSameDayAs: day) {
                    streak += 1
                } else if let twoDaysAfter = calendar.date(byAdding: .day, value: 2, to: last),
                          calendar.isDate(twoDaysAfter, inSameDayAs: day),
                          streak >= 7, streak.isMultiple(of: 7) {
                    // Rest day allowed: streak value stays the same, lastDate advances.
                } else {
                    streak = 1
                }
            } else {
                streak = 1
            }
            lastDate = day
            longest = max(longest, streak)
        }

        // Current streak: is the streak still alive relative to today?
        var currentStreak = streak
        if let last = lastDate {
            let daysSinceLast = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            if daysSinceLast >= 2 {
                if daysSinceLast == 2 && streak >= 7 && streak.isMultiple(of: 7) {
                    // Rest day — streak continues.
                } else {
                    currentStreak = 0
                }
            }
        }

        return StreakStats(
            currentStreak: currentStreak,
            longestStreak: longest,
            totalActiveDays: sortedDates.count,
            activeDates: activeDays,
            lastActivityDate: lastDate
        )
    }

    // MARK: - Recording

    /// Records a qualifying activity for `date`, creating an ActivityRecord
    /// only if this calendar day has no activity yet (per-calendar-day
    /// deduplication). Returns the updated streak statistics.
    func recordActivity(
        type: ActivityType,
        referenceID: UUID?,
        in context: ModelContext,
        at date: Date = .now
    ) -> StreakStats {
        let dayStart = calendar.startOfDay(for: date)

        // Per-calendar-day deduplication: if this day already has a record,
        // do not create another one — the day already counts once.
        let descriptor = FetchDescriptor<ActivityRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.contains(where: { calendar.isDate($0.activityDate, inSameDayAs: date) }) {
            return stats(from: existing, at: date)
        }

        let record = ActivityRecord(
            activityDate: dayStart,
            activityType: type,
            referenceID: referenceID
        )
        context.insert(record)

        do {
            try context.save()
        } catch {
            logger.error("Failed to save activity record: \(error.localizedDescription, privacy: .public)")
        }

        let allRecords = (try? context.fetch(FetchDescriptor<ActivityRecord>())) ?? []
        return stats(from: allRecords, at: date)
    }

    /// Returns true if the given calendar day already has a qualifying activity.
    func hasActivity(on date: Date, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ActivityRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return records.contains { calendar.isDate($0.activityDate, inSameDayAs: date) }
    }
}
