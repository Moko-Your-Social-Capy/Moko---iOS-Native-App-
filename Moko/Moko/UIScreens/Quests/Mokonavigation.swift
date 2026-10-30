//
//  MokoNavigation.swift
//  Moko
//
//  Lets a screen that is deep inside a full-screen cover (like the debrief) send the user
//  to a particular version of the Overview tab. MokoRootView provides `openOverview`.
//

import SwiftUI

/// Which version of the Overview tab to show
enum OverviewMode: String {
    case todo          // Overview: today's mission
    case resume        // OverviewResumeScreen: pick up an unfinished debrief
    case debriefDone   // OverviewDebriefDone: debrief finished
}

private struct OpenOverviewKey: EnvironmentKey {
    static let defaultValue: ((OverviewMode) -> Void)? = nil
}

extension EnvironmentValues {
    /// Switches to the Overview tab showing the given version. Nil when nothing provides it.
    var openOverview: ((OverviewMode) -> Void)? {
        get { self[OpenOverviewKey.self] }
        set { self[OpenOverviewKey.self] = newValue }
    }
}

/// Remembers the quest whose debrief was left unfinished, so "Slide to resume" can reopen it.
enum PendingDebriefStore {
    private static let key = "moko.pendingDebriefQuestID"

    static var questID: UUID? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        return UUID(uuidString: raw)
    }

    static func save(_ quest: Quest) {
        UserDefaults.standard.set(quest.id.uuidString, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
