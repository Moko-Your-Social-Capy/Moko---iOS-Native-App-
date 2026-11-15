//
//  Profile.swift
//  Moko
//
//  The user's profile: name, photo, XP and streaks. The app keeps one Profile.
//
//  Careful: this is a SwiftData model. Renaming or removing a property changes
//  the saved database and needs a migration.
//

import Foundation
import SwiftData

/// `@Model` tells SwiftData to save this class to the phone's database.
@Model
final class Profile: Identifiable {
    var userID = UUID()

    /// The display name shown on the Profile tab.
    var username: String
    /// Optional @username.
    var handle: String?
    /// One of "13–17", "18–24", ... or `nil` if the user prefers not to say.
    var ageRange: String?
    var age: Int

    /// `.externalStorage` saves big data (the photo) in a separate file instead of inside the database.
    @Attribute(.externalStorage)
    var profileImageData: Data?

    /// Experience points. They decide the level and which Moko costumes are unlocked.
    var xp: Int
    /// Days in a row with practice, now and the best ever.
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?

    var createdAt: Date
    var updatedAt: Date

    init(
        userID: UUID = UUID(),
        username: String = "",
        handle: String? = nil,
        ageRange: String? = nil,
        age: Int,
        profileImageData: Data? = nil,
        xp: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActivityDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.userID = userID
        self.username = username
        self.handle = handle
        self.ageRange = ageRange
        self.age = age
        self.profileImageData = profileImageData
        self.xp = xp
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
