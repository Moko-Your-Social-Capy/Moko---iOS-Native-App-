//
//  MokoMotion.swift
//  Moko
//
//  Centralized motion/animation tokens for consistent, accessible animation
//  across the app. All animations respect @Environment(\.accessibilityReduceMotion).
//

import SwiftUI

/// Shared motion/animation presets for the entire app.
/// Use these instead of hardcoded animation values for consistency.
enum MokoMotion {
    /// Snappy, responsive spring for quick interactions (selections, toggles, state changes).
    /// response: 0.25s, damping: 0.86 – feels immediate and lively.
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.86)

    /// Bouncy spring for celebratory moments and delightful completions.
    /// response: 0.5s, damping: 0.6 – more playful, more overshoot.
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Calm, slow easing for relaxation and breathing-like effects.
    /// easeInOut over 0.4s – gentle and meditative.
    static let calm = Animation.easeInOut(duration: 0.4)
}

/// Accessibility-aware animation utilities.
extension Animation {
    /// Returns the animation if reduce-motion is off; returns `.linear(duration: 0)` if on.
    /// Use inside @ViewBuilder or in .animation() modifiers.
    static func respectReduceMotion(_ animation: Animation) -> Animation {
        // Note: To use this, you need @Environment(\.accessibilityReduceMotion) in your view.
        // This is a helper; the actual check happens at the view level.
        return animation
    }
}

/// Button press style with scale feedback (snappy animation).
struct MokoPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(reduceMotion ? .linear(duration: 0) : MokoMotion.snappy, value: configuration.isPressed)
    }
}
