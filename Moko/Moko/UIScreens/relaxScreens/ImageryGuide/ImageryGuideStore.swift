//
//  ImageryGuideStore.swift
//  Moko
//
//  Loads the Relax > Imagery guides, filter chips and screen copy from Supabase.
//

import Foundation
import Observation
import Supabase

// MARK: - Service

struct ImageryGuideService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    /// Fetches everything the Imagery Guide flow renders in one request round.
    func fetchContent() async throws -> ImageryGuideContent {
        async let guides = fetchGuides()
        async let tags = fetchTags()
        async let screen = fetchScreenContent()

        let (loadedGuides, loadedTags, loadedScreen) = try await (guides, tags, screen)
        return ImageryGuideContent(guides: loadedGuides, tags: loadedTags, screen: loadedScreen)
    }

    private func fetchGuides() async throws -> [ImageryGuide] {
        try await client
            .from("imagery_guides")
            .select()
            .eq("is_active", value: true)
            .order("sort_order")
            .execute()
            .value
    }

    private func fetchTags() async throws -> [ImageryGuideTag] {
        try await client
            .from("imagery_guide_tags")
            .select()
            .eq("is_active", value: true)
            .order("sort_order")
            .execute()
            .value
    }

    private func fetchScreenContent() async throws -> ImageryGuideScreenContent {
        try await client
            .from("imagery_guide_screen_content")
            .select()
            .eq("id", value: 1)
            .single()
            .execute()
            .value
    }
}

// MARK: - Store

@MainActor
@Observable
final class ImageryGuideStore {
    private(set) var content: ImageryGuideContent?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: ImageryGuideService
    private var hasLoaded = false

    nonisolated init(service: ImageryGuideService = ImageryGuideService()) {
        self.service = service
    }

    var guides: [ImageryGuide] { content?.guides ?? [] }
    var tags: [ImageryGuideTag] { content?.tags ?? [] }
    var screen: ImageryGuideScreenContent? { content?.screen }

    /// Loads once when the screen first appears. Pull to refresh calls `load()`.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            content = try await service.fetchContent()
            hasLoaded = true
        } catch {
            print("[ImageryGuide] Failed to load content: \(error)")
            errorMessage = "Couldn't load guides. Check your connection and try again."
        }
    }
}
