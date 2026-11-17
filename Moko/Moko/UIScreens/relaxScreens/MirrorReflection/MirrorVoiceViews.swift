//
//  MirrorVoiceViews.swift
//  Moko
//
//  The small views that make Mirror Reflection feel alive:
//  Moko in the mirror, a listening pill, and the gentle nudge that appears
//  when the user stops saying the affirmation.
//

import SwiftUI

// MARK: - Moko in the mirror

/// The Moko mascot, used wherever the old drawn face appeared.
/// Moko breathes a little when the microphone hears the user's voice.
struct MokoMirrorMascot: View {
    var size: CGFloat = 96
    var isSpeaking: Bool = false
    var level: Double = 0

    // The phone setting "Reduce Motion". If it is on, Moko stays still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image("MokoMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            // A small, soft pulse while the user speaks.
            .scaleEffect(reduceMotion ? 1 : CGFloat(isSpeaking ? 1.04 + level * 0.06 : 1))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSpeaking)
            // Smooth the small size changes as the voice gets louder or softer.
            .animation(.easeOut(duration: 0.12), value: level)
            // The picture is decoration; the words next to it carry the meaning.
            .accessibilityHidden(true)
    }
}

// MARK: - Listening pill

/// A tiny pill that shows whether Moko can hear the user.
struct MirrorVoicePill: View {
    let state: MirrorVoiceState
    let isSpeaking: Bool
    let level: Double

    private var text: String {
        switch state {
        case .idle:
            return "Moko will listen"
        case .preparing:
            return "Turning on mic…"
        case .ready:
            return "Moko is ready"
        case .listening:
            return isSpeaking ? "I hear you" : "Listening"
        case .unavailable:
            return "Voice is off"
        }
    }

    private var icon: String {
        switch state {
        case .unavailable:
            return "mic.slash.fill"
        case .listening:
            return isSpeaking ? "waveform" : "mic.fill"
        default:
            return "mic.fill"
        }
    }

    private var tint: Color {
        if case .unavailable = state { return MirrorPalette.subtext }
        return MirrorPalette.accent
    }

    var body: some View {
        HStack(spacing: 6) {
            if state == .listening {
                MirrorListeningBars(level: level, isActive: isSpeaking)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(text)
                .mokoText(MokoScreenTheme.Typeface.caption)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(Capsule().fill(MirrorPalette.track.opacity(0.8)))
        // VoiceOver reads the pill as one short sentence.
        .accessibilityElement(children: .combine)
    }
}

/// Three tiny bars that move with the microphone level.
struct MirrorListeningBars: View {
    let level: Double
    let isActive: Bool

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(MirrorPalette.accent)
                    .frame(width: 3, height: height(for: index))
            }
        }
        .frame(height: 16)
        .animation(.easeOut(duration: 0.12), value: level)
        .opacity(isActive ? 1 : 0.35)
        .accessibilityHidden(true)
    }

    private func height(for index: Int) -> CGFloat {
        guard isActive else { return 5 }
        // Different heights make the three bars look like a tiny waveform.
        let shapes = [0.55, 1.0, 0.75]
        return 5 + CGFloat(level * 18 * shapes[index])
    }
}

// MARK: - Mirror nudge

/// A small speech bubble that appears near Moko when the user goes quiet.
struct MirrorNudgeBubble: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image("MokoMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)

            Text(text)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MirrorPalette.title)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: MirrorPalette.accent.opacity(0.16), radius: 10, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MirrorPalette.track, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Camera nudge

/// A notification-style banner for the camera version.
/// The camera shows the user's real face, so there is no Moko picture to
/// attach a speech bubble to. This banner slides in at the top instead.
struct CameraNudgeBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(MirrorPalette.accent.opacity(0.14))

                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MirrorPalette.accent)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("Moko")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MirrorPalette.subtext)

                Text(text)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MirrorPalette.title)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("Moko in the mirror") {
    ZStack {
        MokoBackdrop()
        MokoMirrorMascot(size: 180)
    }
}

#Preview("Listening pill") {
    VStack(spacing: 14) {
        MirrorVoicePill(state: .listening, isSpeaking: true, level: 0.7)
        MirrorVoicePill(state: .listening, isSpeaking: false, level: 0.08)
        MirrorVoicePill(state: .unavailable("Microphone access is off"), isSpeaking: false, level: 0)
    }
    .padding()
    .background(MokoBackdrop())
}

#Preview("Nudges") {
    VStack(spacing: 18) {
        MirrorNudgeBubble(text: "Continue saying.")
        CameraNudgeBanner(text: "Continue saying.")
    }
    .padding()
    .background(MokoBackdrop())
}
