//
//  Profile.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//


import Foundation
import SwiftData

@Model
final class Profile : Identifiable {
    var userID = UUID()

    var username: String
    var age: Int

    @Attribute(.externalStorage)
    var profileImageData: Data?

    var xp: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?

    var createdAt: Date
    var updatedAt: Date

    init(
        userID: UUID = UUID(),
        username: String = "",
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
