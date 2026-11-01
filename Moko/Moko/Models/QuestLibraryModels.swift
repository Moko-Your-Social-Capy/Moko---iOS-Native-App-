//
//  QuestLibraryModels.swift
//  Moko
//
//  Read-only quest library content served by Supabase.
//

import SwiftUI

// MARK: - Quest
/// One card in the Quest Library. Rows live in the `quest_library` table in Supabase.
struct LibraryQuest: Identifiable, Hashable, Decodable {
    let id: UUID
    let category: String
    let title: String
    let imageName: String?
    /// Public URL in the `quest-library` Supabase Storage bucket. Nil until artwork is uploaded.
    let imageURL: String?
    let xp: Int
    let tintHex: String

    /// The saved quest's intensity, chosen from the XP the library awards.
    var intensity: QuestIntensity {
        switch xp {
        case ...100: return .easy
        case 101...200: return .medium
        default: return .hard
        }
    }

    /// Card artwork tint. Falls back to the original Work tint if a row has a bad hex value.
    var tint: Color {
        Color(hexString: tintHex) ?? Color(hex: 0xFAEDD9)
    }

    var artworkURL: URL? {
        guard let imageURL else { return nil }
        return URL(string: imageURL)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case xp
        case imageName = "image_name"
        case imageURL = "image_url"
        case tintHex = "tint_hex"
    }
}

// MARK: - Section
/// A category heading and the quests inside it. Sections follow the order the
/// `category_sort_order` column gives them in Supabase.
struct QuestSection: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let category: QuestCategory
    var quests: [LibraryQuest]

    /// Groups an ordered list of rows into category sections while keeping the
    /// order Supabase returned. New categories automatically become new sections;
    /// saved quests use `.others` when the app doesn't know the category yet.
    static func grouped(from quests: [LibraryQuest]) -> [QuestSection] {
        var sections: [QuestSection] = []

        for quest in quests {
            if let index = sections.firstIndex(where: { $0.title == quest.category }) {
                sections[index].quests.append(quest)
            } else {
                sections.append(
                    QuestSection(
                        title: quest.category,
                        category: QuestCategory(rawValue: quest.category) ?? .others,
                        quests: [quest]
                    )
                )
            }
        }

        return sections
    }
}

// MARK: - Hex colour
extension Color {
    /// Parses `#FAEDD9` or `FAEDD9` from the quest library's `tint_hex` column.
    init?(hexString: String) {
        var value = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6, let hex = UInt32(value, radix: 16) else {
            return nil
        }

        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
