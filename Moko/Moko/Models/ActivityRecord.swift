//
//  ActivityRecord.swift
//  Moko
//
//  The single source of truth for streak data. Every qualifying activity
//  (a completed quest or a finished debrief) is recorded here once per
//  calendar day. Streak, calendar and detail screens all compute their
//  numbers from this table instead of keeping their own copies.
//

import Foundation
import SwiftData

/// The kind of activity that can count toward a streak.
enum ActivityType: String, Codable, CaseIterable {
    case quest      = "quest"
    case debrief    = "debrief"
    case calm       = "calm"
}

/// One completed activity on a particular calendar day. Only completed
/// activities are stored here, so every row counts toward the streak.
@Model
final class ActivityRecord: Identifiable {
    var id: UUID
    /// The calendar day the activity happened on (start of day in the user's calendar).
    var activityDate: Date
    /// What kind of activity it was.
    var activityType: ActivityType
    /// The quest or debrief this activity belongs to, if any.
    var referenceID: UUID?
    /// Always true: only completed activities are recorded.
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        activityDate: Date,
        activityType: ActivityType,
        referenceID: UUID? = nil,
        isCompleted: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.activityDate = activityDate
        self.activityType = activityType
        self.referenceID = referenceID
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
