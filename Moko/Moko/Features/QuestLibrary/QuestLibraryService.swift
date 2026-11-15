//
//  QuestLibraryService.swift
//  Moko
//
//  Loads the Quest Library from Supabase and exposes it to the view.
//
//  Two pieces:
//  - `QuestLibraryService` only talks to the database (one query).
//  - `QuestLibraryStore` holds what the screen shows: sections, loading, error.
//  Debug tip: failures are logged under the "Network" category in the Xcode console.
//

import Foundation
import OSLog
import Observation
import Supabase

// MARK: - Service

/// Reads the `quest_library` table. It keeps no state, so it is a simple struct.
struct QuestLibraryService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    /// Fetches every active library quest, ordered by category and then by the
    /// position inside that category. Content is managed from the Supabase table.
    func fetchQuests() async throws -> [LibraryQuest] {
        // `.value` decodes the JSON rows straight into `[LibraryQuest]`.
        try await client
            .from("quest_library")
            .select()
            .eq("is_active", value: true)
            .order("category_sort_order")
            .order("sort_order")
            .execute()
            .value
    }
}

// MARK: - Store

/// What the Explore screen reads. `@Observable` redraws the screen whenever
/// one of these values changes. `private(set)` means only this class can change them.
@MainActor
@Observable
final class QuestLibraryStore {
    /// The quests grouped by category, ready to draw.
    private(set) var sections: [QuestSection] = []
    /// True while a download is running. Stops a second download starting.
    private(set) var isLoading = false
    /// Friendly message shown when the last download failed. nil = no error.
    private(set) var errorMessage: String?
    /// False until the first download starts, so the screen shows the loader instead of "No quests yet".
    private(set) var hasAttemptedLoad = false

    private let service: QuestLibraryService
    /// True after one successful download, so switching tabs doesn't download again.
    private var hasLoaded = false

    // Build the service on the same main actor as the screens that use it.
    init(service: QuestLibraryService? = nil) {
        self.service = service ?? QuestLibraryService()
    }

    /// Loads once on entry. The Quest Library refresh button also calls `load()`.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    /// Downloads the quests and groups them into sections.
    func load() async {
        guard !isLoading else { return }

        let loadingStartedAt = ContinuousClock.now
        hasAttemptedLoad = true
        isLoading = true
        errorMessage = nil
        // `defer` runs when the function exits, on every path (success, error or cancel).
        defer { isLoading = false }

        do {
            let quests = try await service.fetchQuests()
            try await keepLoaderVisible(since: loadingStartedAt)
            sections = QuestSection.grouped(from: quests)
            hasLoaded = true
        } catch is CancellationError {
            // The user left the screen. Not a real error, so show nothing.
            return
        } catch {
            do {
                try await keepLoaderVisible(since: loadingStartedAt)
            } catch {
                return   // cancelled while waiting
            }
            // Shows in the Xcode console under the "Network" category.
            Logger.network.error("Failed to load quests: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load quests. Check your connection and try again."
        }
    }

    /// Waits until the loading animation has played for at least 5 seconds, so it
    /// never flashes for a split second. Throws if the task is cancelled meanwhile.
    private func keepLoaderVisible(since start: ContinuousClock.Instant) async throws {
        let minimumDuration = Duration.seconds(5)
        let elapsed = start.duration(to: .now)
        if elapsed < minimumDuration {
            try await Task.sleep(for: minimumDuration - elapsed)
        }
    }
}
