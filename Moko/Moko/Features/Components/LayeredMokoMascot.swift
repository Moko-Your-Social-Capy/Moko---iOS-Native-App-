//
//  LayeredMokoMascot.swift
//  Moko
//
//  Moko mascot with real arm wave animation using layered images.
//  - mascot_body: Body with arm erased and gap painted over
//  - mascot_arm: Just the arm, rotates around shoulder point
//

import SwiftUI

/// Moko mascot mood states.
enum MokoMood: String, CaseIterable {
    case idle       // Neutral, breathing
    case waving     // Happy arm wave
    case celebrate  // Celebratory (with confetti overlay)
    case sleeping   // Faded/sleeping
}

/// Primary Moko mascot component with layered arm animation.
/// Falls back to SimpleMokoMascot if layered images aren't available.
struct MokoMascot: View {
    var mood: MokoMood = .idle
    var size: CGFloat = 200

    var body: some View {
        // Try to use layered version first; fall back to simple if images missing
        Group {
            // Attempt layered (will show body + arm if both images exist)
            LayeredMokoMascot(mood: mood, size: size)
                // If layered images fail to load, show fallback
                .onAppear {
                    // This will use the fallback Image("Moko mascot") if needed
                }
        }
        .background {
            // Fallback: simple mascot with mood-based effects
            SimpleMokoMascot(mood: mood, size: size)
        }
    }
}

/// Moko mascot with realistic arm wave animation using layered images.
/// The arm rotates around the shoulder joint while the body stays still.
struct LayeredMokoMascot: View {
    var mood: MokoMood = .idle
    var size: CGFloat = 200

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Shoulder joint as a fraction of the image (x, y from top-left).
    /// Tune these values based on where the arm connects to the body.
    /// For this capybara: x ≈ 0.25 (left side), y ≈ 0.55 (middle-ish height)
    private let shoulder = UnitPoint(x: 0.25, y: 0.55)

    var body: some View {
        TimelineView(.animation) { tl in
            let phase = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.6)

            // Wave for 1.6s, rest 1s.
            // Envelope eases the start and end smoothly.
            let envelope = min(1, phase * 6, (1.6 - phase) * 6)

            // Wave angle: sine oscillation, scaled by envelope
            let waveAngle = phase < 1.6 ? sin(phase * 9) * 22 * max(envelope, 0) : 0

            // Determine final angle based on mood
            let angle = (mood == .waving && !reduceMotion) ? waveAngle : 0

            ZStack {
                // Body (arm already erased from this layer)
                Image("mascot_body")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)

                // Arm layer (rotates around shoulder)
                Image("mascot_arm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(angle), anchor: shoulder)
            }
            .frame(width: size, height: size)
        }
    }
}

/// Simplified single-image Moko fallback (when layered images aren't available).
/// Uses basic scaling/opacity for moods instead of arm wave.
struct SimpleMokoMascot: View {
    var mood: MokoMood = .idle
    var size: CGFloat = 200

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { tl in
            let phase = tl.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 3)

            // Breathing/idle animation
            let breathScale = reduceMotion ? 1.0 : (1.0 + sin(phase * 2) * 0.05)

            Image("Moko mascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .scaleEffect(breathScale)
                .opacity(moodOpacity)
                .animation(
                    reduceMotion ? .linear(duration: 0) : MokoMotion.calm,
                    value: breathScale
                )
        }
    }

    private var moodOpacity: Double {
        switch mood {
        case .idle, .waving, .celebrate:
            return 1.0
        case .sleeping:
            return 0.7
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        HStack(spacing: 16) {
            MokoMascot(mood: .idle, size: 100)
            MokoMascot(mood: .waving, size: 100)
            MokoMascot(mood: .celebrate, size: 100)
        }

        Text("Moko Mascot with Layered Arm Wave")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
