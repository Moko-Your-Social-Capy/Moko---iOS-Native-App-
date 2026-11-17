//
//  MokoLog.swift
//  Moko
//
//  One place for the app's debug messages. Use these instead of `print`.
//
//  Beginner tip: messages show up in Xcode's console (and in the Mac
//  "Console" app). Type the category name, for example "Audio", in the
//  console's filter box to see only those lines.
//
//  Usage:
//      Logger.audio.error("Could not play: \(error)")
//      Logger.data.info("Saved the session")
//

import OSLog
import SwiftData

extension Logger {
    // The "subsystem" groups all of Moko's messages together. It matches the app's bundle id.
    private static let subsystem = "com.mahik.MokoApp"

    /// Sounds and the audio session.
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    /// Saving and loading SwiftData records on the phone.
    static let data = Logger(subsystem: subsystem, category: "Data")
    /// Talking to Supabase (quests, imagery guides, account).
    static let network = Logger(subsystem: subsystem, category: "Network")
    /// Apple Foundation Models and intelligence logging.
    static let afm = Logger(subsystem: subsystem, category: "AFM")
}

extension ModelContext {
    /// Saves SwiftData changes. If saving fails, the reason is written to the
    /// "Data" log instead of being silently ignored like `try? save()` would.
    ///
    ///     modelContext.saveOrLog("new quest")
    func saveOrLog(_ what: String) {
        do {
            try save()
        } catch {
            Logger.data.error("Saving \(what, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
