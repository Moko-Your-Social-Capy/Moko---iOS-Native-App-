import Foundation
import WidgetKit

/// Small widget-only snapshot format shared with the main app’s saved JSON.
struct MokoStreakWidgetSnapshot: Codable, Sendable {
    struct Day: Codable, Sendable, Identifiable {
        var id: String { isoDate }
        let isoDate: String
        let shortLabel: String
        let status: Status

        enum Status: String, Codable, Sendable {
            case completed
            case missed
            case upcoming
            case todayPending
        }
    }

    let currentStreak: Int
    let longestStreak: Int
    let totalActiveDays: Int
    let lastUpdated: Date
    let week: [Day]

    static let empty = MokoStreakWidgetSnapshot(
        currentStreak: 0,
        longestStreak: 0,
        totalActiveDays: 0,
        lastUpdated: .now,
        week: []
    )

    private static let defaults = UserDefaults.standard
    private static let key = "moko.streak.widget.snapshot.v1"

    static func load() -> MokoStreakWidgetSnapshot {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(MokoStreakWidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
