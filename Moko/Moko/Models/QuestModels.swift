//
//  QuestModels.swift
//  Moko
//
//  Custom quest data: model, local storage, and shared styling/formatting.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Model
nonisolated enum QuestIntensity: String, CaseIterable, Identifiable, Codable, Hashable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    /// XP shown on the quest card
    var xp: Int {
        switch self {
        case .easy:   return 100
        case .medium: return 150
        case .hard:   return 200
        }
    }
}

nonisolated enum QuestCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case work = "Work"
    case dating = "Dating"
    case friends = "Friends"
    case family = "Family"
    case others = "Others"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .work:    return "briefcase.fill"
        case .dating:  return "heart.fill"
        case .friends: return "person.2.fill"
        case .family:  return "person.3.fill"
        case .others:  return "ellipsis"
        }
    }
}

/// A custom quest saved in the SwiftData database. Every quest belongs to one user (`ownerID`).
@Model
final class Quest {
    @Attribute(.unique) var id: UUID
    /// Which user this quest belongs to
    var ownerID: String
    var title: String
    var notes: String
    var intensity: QuestIntensity
    var category: QuestCategory
    /// Scheduled day and time
    var date: Date
    var createdAt: Date
    /// Set when the user taps the check on the quest card. The default value lets SwiftData
    /// add this column to quests that were saved before it existed.
    var isCompleted: Bool = false
    /// Actual completion time, used for streak and time-based achievements.
    var completedAt: Date?
    /// True once this quest's XP and streak have been added to the Profile.
    var xpAwarded: Bool = false
    /// True once this quest's debrief scores have been saved as an Insights entry.
    var debriefRecorded: Bool = false
    /// Quests from the library award a specific XP amount. Nil means use the
    /// intensity's default, which is what custom quests do.
    var xp: Int?

    /// XP shown wherever the quest is listed.
    var awardedXP: Int { xp ?? intensity.xp }

    init(ownerID: String,
         title: String,
         notes: String,
         intensity: QuestIntensity,
         category: QuestCategory,
         date: Date,
         xp: Int? = nil) {
        self.id = UUID()
        self.ownerID = ownerID
        self.title = title
        self.notes = notes
        self.intensity = intensity
        self.category = category
        self.date = date
        self.createdAt = Date()
        self.isCompleted = false
        self.completedAt = nil
        self.xpAwarded = false
        self.debriefRecorded = false
        self.xp = xp
    }
}

extension Quest {
    /// Library scenarios award a specific XP amount. Custom quests leave `xp` nil.
    var isFromLibrary: Bool { xp != nil }

    /// The quest the Overview shows: the earliest completed quest that still needs
    /// a debrief, otherwise the soonest incomplete quest for today (or overdue). Only this device's user.
    /// Library scenarios are started from Explore and never become the daily mission.
    /// Future scheduled custom quests trigger daily preparation missions instead.
    static func overviewMission(
        from quests: [Quest],
        ownerID: String = CurrentUser.localID
    ) -> Quest? {
        let mine = quests.filter { $0.ownerID == ownerID && !$0.isFromLibrary }

        if let awaitingDebrief = mine
            .filter({ $0.isCompleted && !$0.debriefRecorded })
            .min(by: { $0.date < $1.date }) {
            return awaitingDebrief
        }

        let calendar = Calendar.current
        return mine
            .filter { !$0.isCompleted && (calendar.isDateInToday($0.date) || $0.date < .now) }
            .min(by: { $0.date < $1.date })
    }
}

// MARK: - Current user
/// Who is using the app. There's no login yet, so this is a profile ID created on first
/// launch and kept on the device. When real accounts exist, return the signed-in user's
/// ID here and every quest query and new quest follows automatically.
enum CurrentUser {
    private static let storageKey = "moko.currentUserID"

    static var localID: String {
        if let existing = UserDefaults.standard.string(forKey: storageKey) {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: storageKey)
        return created
    }

    /// Forgets the device's local user, e.g. after the account is deleted.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - Database
enum MokoDatabase {
    /// The real on-device database
    static let shared: ModelContainer = make(inMemory: false)
    /// Throwaway database for Xcode previews
    static let preview: ModelContainer = make(inMemory: true)

    private static func make(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: Quest.self, configurations: configuration)
        } catch {
            fatalError("Could not create the database: \(error)")
        }
    }
}

// MARK: - Shared style
enum QuestStyle {
    static let screenBg = MocoScreenTheme.Colors.canvasTop  // #F6FAE8
    static let green = MocoScreenTheme.Colors.dataVioletDeep        // #365948
    static let deepGreen = MocoScreenTheme.Colors.dataVioletDeep    // #1B422F
    static let title = MocoScreenTheme.Colors.textTitle        // #5C4330
    static let subtext = MocoScreenTheme.Colors.textBody    // #6F6762
    static let chipSelectedFill = MocoScreenTheme.Colors.surfaceLavender
    static let chipSelectedBorder = MocoScreenTheme.Colors.dataGrid
    static let divider = Color.black.opacity(0.08)
}

// MARK: - Formatting
nonisolated enum QuestFormat {
    /// Tomorrow at 9:30 AM
    static func defaultSchedule() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 9, minute: 30, second: 0, of: tomorrow) ?? tomorrow
    }

    /// "Tomorrow, Oct 15"
    static func dateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let short = date.formatted(.dateTime.month(.abbreviated).day())

        if calendar.isDateInToday(date) { return "Today, \(short)" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow, \(short)" }

        let weekday = date.formatted(.dateTime.weekday(.abbreviated))
        return "\(weekday), \(short)"
    }

    /// "9:30 AM"
    static func timeText(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// Section header: "Tomorrow" or "Friday, 16th October"
    static func groupTitle(_ day: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }

        let weekday = day.formatted(.dateTime.weekday(.wide))
        let month = day.formatted(.dateTime.month(.wide))
        let number = calendar.component(.day, from: day)
        return "\(weekday), \(ordinal(number)) \(month)"
    }

    private static func ordinal(_ number: Int) -> String {
        let suffix: String
        switch number % 100 {
        case 11, 12, 13:
            suffix = "th"
        default:
            switch number % 10 {
            case 1:  suffix = "st"
            case 2:  suffix = "nd"
            case 3:  suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(number)\(suffix)"
    }
}
