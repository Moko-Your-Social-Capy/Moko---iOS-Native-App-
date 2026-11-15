//
//  ImageryGuideStore.swift
//  Moko
//
//  Loads the Relax > Imagery guides, filter chips and screen copy from Supabase.
//  - `ImageryGuideService` talks to Supabase (no UI code).
//  - `ImageryGuideStore` keeps the result for the screens and tracks loading/errors.
//

import Foundation
import OSLog
import Observation
import Supabase

// MARK: - Service

/// Reads the three Imagery Guide tables from Supabase.
struct ImageryGuideService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    /// Fetches everything the Imagery Guide flow renders in one request round.
    /// `async let` starts all three downloads at the same time instead of one after another.
    func fetchContent() async throws -> ImageryGuideContent {
        async let guides = fetchGuides()
        async let tags = fetchTags()
        async let screen = fetchScreenContent()

        let (loadedGuides, loadedTags, loadedScreen) = try await (guides, tags, screen)
        return ImageryGuideContent(guides: loadedGuides, tags: loadedTags, screen: loadedScreen)
    }

    /// SELECT * FROM imagery_guides WHERE is_active = true ORDER BY sort_order
    /// `.value` decodes the JSON rows into `[ImageryGuide]`.
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

    /// The single row (id = 1) that holds every label used on the screens.
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

/// Holds the downloaded guides for the screens.
/// `@Observable` makes every screen that reads these properties redraw when they change.
@MainActor
@Observable
final class ImageryGuideStore {
    // `private(set)` means screens can read these, but only the store can change them.
    private(set) var content: ImageryGuideContent?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: ImageryGuideService
    // True after the first successful load, so we do not download again on every screen.
    private var hasLoaded = false

    // Build the service on the same main actor as the screens that use it.
    init(service: ImageryGuideService? = nil) {
        self.service = service ?? ImageryGuideService()
    }

    var guides: [ImageryGuide] { content?.guides ?? [] }
    var tags: [ImageryGuideTag] { content?.tags ?? [] }
    var screen: ImageryGuideScreenContent? { content?.screen }

    /// Loads once when the screen first appears. Pull to refresh calls `load()`.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    /// Always downloads again (used by pull to refresh and "Try Again").
    func load() async {
        // Ignore extra taps while a download is already running.
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            content = try await service.fetchContent()
            hasLoaded = true
        } catch {
            // Write the real error to the Xcode console; show a friendly message on screen.
            Logger.network.error("Failed to load imagery guides: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load guides. Check your connection and try again."
        }
    }
}
