//
//  MokoCostume.swift
//  Moko
//
//  Custom costume assets for the Moko mascot.
//

import Foundation
import SwiftData

@Model final class MokoCostumeRecord: Identifiable {
    @Attribute(.unique) var id: UUID

    /// Human-readable name for the costume
    var name: String

    /// Asset filename in Assets.xcassets
    var assetName: String

    /// Display level of this costume (1, 2, 3...)
    var level: Int

    /// Description or notes about the costume
    var costumeDescription: String?

    /// Unlocked date
    var unlockedDate: Date

    init(name: String, assetName: String, level: Int, description: String? = nil, unlockedDate: Date = .now) {
        self.id = UUID()
        self.name = name
        self.assetName = assetName
        self.level = level
        self.costumeDescription = description
        self.unlockedDate = unlockedDate
    }
}

// MARK: - Costume Library

/// Sample costumes for preview purposes. In production, these would come from SwiftData.
extension MokoCostumeRecord {
    static let all: [MokoCostumeRecord] = [
        MokoCostumeRecord(
            name: "Classic Green",
            assetName: "moko_sitting_raw",
            level: 1,
            description: "The original Moko - sitting quietly in the forest",
            unlockedDate: .now
        ),
        MokoCostumeRecord(
            name: "Waving Greeting",
            assetName: "moko_waving_raw",
            level: 2,
            description: "Saying hello to friends across the landscape",
            unlockedDate: .now
        ),
        MokoCostumeRecord(
            name: "Capybara Friends",
            assetName: "capybara_peek",
            level: 3,
            description: "A peek into capybara culture",
            unlockedDate: .now
        ),
    ]

    static func costumeForLevel(_ level: Int) -> MokoCostumeRecord? {
        all.first { $0.level >= level } ?? all.first
    }
}
