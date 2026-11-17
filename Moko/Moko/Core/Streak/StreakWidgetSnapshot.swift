import Foundation
import WidgetKit
#if canImport(SwiftData)
import SwiftData
#endif

/// Shared streak snapshot for Home Screen widgets.
/// Written by the main app and read by the widget extension from the same source-of-truth logic.
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

    static let appGroupID = "group.com.SRMIST.MokoAppFinalv2"
    private static let key = "moko.streak.widget.snapshot.v1"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults?.set(data, forKey: Self.key)
        WidgetCenter.shared.reloadTimelines(ofKind: "MokoStreakWidget")
    }

    static func load() -> MokoStreakWidgetSnapshot {
        guard let data = defaults?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(MokoStreakWidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    @MainActor
    static func update(from records: [ActivityRecord], at date: Date = .now) {
        let service = StreakService.shared
        let stats = service.stats(from: records, at: date)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]

        var days: [Day] = []
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let start = calendar.startOfDay(for: day)
            let label = day.formatted(.dateTime.weekday(.abbreviated)).uppercased()
            let isActive = stats.activeDates.contains(where: { calendar.isDate($0, inSameDayAs: start) })
            let status: Day.Status
            if isActive {
                status = .completed
            } else if calendar.isDate(start, inSameDayAs: today) {
                status = .todayPending
            } else if start < today {
                status = .missed
            } else {
                status = .upcoming
            }
            days.append(Day(isoDate: iso.string(from: start), shortLabel: label, status: status))
        }

        let snapshot = MokoStreakWidgetSnapshot(
            currentStreak: stats.currentStreak,
            longestStreak: stats.longestStreak,
            totalActiveDays: stats.totalActiveDays,
            lastUpdated: date,
            week: days
        )
        snapshot.save()
    }

    #if canImport(SwiftData)
    @MainActor
    static func refreshFromSharedStore() {
        // Best-effort: read from app's SwiftData store (shared container if configured).
        do {
            let config = ModelConfiguration(groupContainer: .identifier(appGroupID))
            let container = try ModelContainer(for: ActivityRecord.self, configurations: config)
            let context = ModelContext(container)
            let records = (try? context.fetch(FetchDescriptor<ActivityRecord>())) ?? []
            update(from: records)
        } catch {
            // Fallback: keep existing snapshot.
        }
    }
    #endif
}
