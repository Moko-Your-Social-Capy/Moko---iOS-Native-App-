//
//  MokoAnimationCoordinator.swift
//  Moko
//
//  Coordinates Lottie animation playback and provides reusable preset views.
//  Uses the Swift 6 / iOS 17 @Observable pattern — no ObservableObject needed.
//

import SwiftUI
import Lottie

// MARK: - Coordinator

/// Shared object that lets any screen trigger a named animation overlay.
/// Observed with @Environment so views don't need to reach for a singleton.
@Observable
@MainActor
final class MokoAnimationCoordinator {

    // The coordinator is injected via .environment — no singleton needed.
    // Individual screens can still create a local instance for isolated use.

    /// Bump this to restart the overlay animation (e.g. on a new celebration).
    var celebrationVersion = 0

    /// Whether the global confetti overlay should be visible right now.
    var showCelebration = false

    // Trigger a confetti burst and auto-hide after the animation duration.
    func celebrate() {
        showCelebration = true
        celebrationVersion += 1
        // Auto-hide after 3 s — confetti is play-once so it is effectively
        // invisible after it finishes, but removing the view frees resources.
        Task {
            try? await Task.sleep(for: .seconds(3))
            showCelebration = false
        }
    }
}

// MARK: - Overlay modifier

/// Layers a full-screen Lottie overlay that fires when `coordinator.showCelebration` is true.
struct MokoAnimationOverlay: ViewModifier {
    @Environment(MokoAnimationCoordinator.self) private var coordinator

    func body(content: Content) -> some View {
        content
            .overlay {
                if coordinator.showCelebration {
                    MokoLottieView(animation: .confetti, loopMode: .playOnce)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        // Re-trigger whenever celebrationVersion changes.
                        .id(coordinator.celebrationVersion)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: coordinator.showCelebration)
    }
}

extension View {
    /// Attaches the full-screen celebration overlay to any screen.
    func withMokoAnimations() -> some View {
        modifier(MokoAnimationOverlay())
    }
}

// MARK: - Preset views

/// Ready-made animation compositions for common moments in the app.
enum MokoAnimationPresets {

    /// Success check + confetti burst — used on onboarding completion.
    static var onboardingCompletion: some View {
        ZStack {
            // Confetti rains on top of the check mark.
            MokoLottieView(animation: .confetti, loopMode: .playOnce)
                .frame(width: 240, height: 240)
                .allowsHitTesting(false)

            MokoLottieView(animation: .successCheck, loopMode: .playOnce)
                .frame(width: 120, height: 120)
        }
    }

    /// Confetti with a sparkle accent — used on quest completion.
    static var questCompletion: some View {
        ZStack {
            MokoLottieView(animation: .confetti, loopMode: .playOnce)
                .frame(width: 240, height: 240)

            MokoLottieView(animation: .sparkles, loopMode: .loop)
                .frame(width: 160, height: 160)
                .opacity(0.7)
        }
        .allowsHitTesting(false)
    }

    /// Looping flame for streak counters; adds sparkles at milestone counts.
    static func streakHero(currentStreak: Int) -> some View {
        ZStack {
            if currentStreak >= 7 {
                // Sparkles behind the flame for milestone streaks.
                MokoLottieView(animation: .sparkles, loopMode: .loop)
                    .frame(width: 120, height: 120)
                    .opacity(0.55)
            }
            MokoLottieView(animation: .streakFlame, loopMode: .loop)
                .frame(width: 100, height: 100)
        }
    }

    /// Subtle looping animation for screens with no content yet.
    static var emptyState: some View {
        MokoLottieView(animation: .empty, loopMode: .loop)
            .frame(width: 160, height: 160)
    }
}
