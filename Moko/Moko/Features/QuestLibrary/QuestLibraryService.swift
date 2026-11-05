//
//  QuestLibraryService.swift
//  Moko
//
//  Loads the Quest Library from Supabase and exposes it to the view.
//

import Foundation
import Observation
import Supabase

// MARK: - Service
struct QuestLibraryService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    /// Fetches every active library quest, ordered by category and then by the
    /// position inside that category. Content is managed from the Supabase table.
    func fetchQuests() async throws -> [LibraryQuest] {
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
@MainActor
@Observable
final class QuestLibraryStore {
    private(set) var sections: [QuestSection] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var hasAttemptedLoad = false

    private let service: QuestLibraryService
    private var hasLoaded = false

    nonisolated init(service: QuestLibraryService = QuestLibraryService()) {
        self.service = service
    }

    /// Loads once on entry. The Quest Library refresh button also calls `load()`.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }

        let loadingStartedAt = ContinuousClock.now
        hasAttemptedLoad = true
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let quests = try await service.fetchQuests()
            try await keepLoaderVisible(since: loadingStartedAt)
            sections = QuestSection.grouped(from: quests)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            do {
                try await keepLoaderVisible(since: loadingStartedAt)
            } catch {
                return
            }
            print("[QuestLibrary] Failed to load quests: \(error)")
            errorMessage = "Couldn't load quests. Check your connection and try again."
        }
    }

    private func keepLoaderVisible(since start: ContinuousClock.Instant) async throws {
        let minimumDuration = Duration.seconds(5)
        let elapsed = start.duration(to: .now)
        if elapsed < minimumDuration {
            try await Task.sleep(for: minimumDuration - elapsed)
        }
    }
}
