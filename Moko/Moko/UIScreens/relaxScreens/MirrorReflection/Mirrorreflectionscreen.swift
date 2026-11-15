//
//  MirrorReflectionScreen.swift
//  Moko
//
//  Relax → Mirror. The first Mirror screen: a glowing mirror picture, a short
//  explanation, and two choices (use a real mirror, or the front camera).
//  RelaxScreen decides which screen comes next from the choice.
//
//  This file also holds `MirrorHero` and `MirrorFaceIcon`, which the other
//  Mirror screens reuse.
//

import SwiftUI

struct MirrorReflectionScreen: View {
    enum Option: Hashable {
        case mirror
        case camera
    }

    // Runs when the user picks one of the two options.
    var onSelectOption: ((Option) -> Void)? = nil

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let ink = MokoScreenTheme.Colors.textTitle
    private let bodyText = MokoScreenTheme.Colors.textBody

    var body: some View {
        ZStack {
            MokoBackdrop()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 18)

                    MirrorHero()
                        .padding(.top, 28)

                    Text("Meet yourself with kindness")
                        .mokoText(MokoScreenTheme.Typeface.title2)
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                        .padding(.horizontal, MokoScreenTheme.Space.page)

                    Text("Take a moment to look at yourself without judging. You don’t need to be perfect to be proud of who you are. Find one thing you appreciate about yourself and give yourself some credit.")
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(bodyText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 12)
                        .padding(.horizontal, 32)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Options")
                            .mokoText(MokoScreenTheme.Typeface.body)
                            .foregroundStyle(bodyText)
                            .padding(.leading, 8)

                        optionRow("I have access to a mirror") {
                            onSelectOption?(.mirror)
                        }

                        optionRow("I want to continue with my camera") {
                            onSelectOption?(.camera)
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mirror Reflection")
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(ink)

            Text("A self-reflective confidence practice")
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(bodyText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Option row

    /// A white card row with a chevron. The whole row is one button.
    private func optionRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(ink)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.vertical, MokoScreenTheme.Space.cardVertical)
            .frame(minHeight: 58)
            .mokoCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero: glowing arch mirror with a drawn face

/// A rounded mirror with a soft glow behind it and three twinkling sparkles.
struct MirrorHero: View {
    /// 0...1: how bright the glow is. The prep screen raises it as the user gets ready.
    var level: Double = 0.5

    // The phone setting "Reduce Motion". If it is on, the glow and sparkles stay still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Flipped once on appear. `repeatForever` then animates them back and forth on its own.
    @State private var glow = false
    @State private var sparkle = false

    private let frameTop = Color(red: 226/255, green: 238/255, blue: 229/255)
    private let frameBottom = Color(red: 200/255, green: 222/255, blue: 208/255)
    private let glassTop = Color(red: 253/255, green: 254/255, blue: 253/255)
    private let glassBottom = Color(red: 232/255, green: 243/255, blue: 236/255)
    private let accent = MokoScreenTheme.Colors.dataVioletDeep

    var body: some View {
        ZStack {
            // Soft glow that slowly grows and shrinks.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.10 + 0.20 * level), accent.opacity(0)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .scaleEffect(glow ? 1.06 : 0.94)

            // Mirror frame
            RoundedRectangle(cornerRadius: 104, style: .continuous)
                .fill(LinearGradient(colors: [frameTop, frameBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: 212, height: 282)
                .shadow(color: accent.opacity(0.16), radius: 18, x: 0, y: 10)

            // Glass
            RoundedRectangle(cornerRadius: 88, style: .continuous)
                .fill(LinearGradient(colors: [glassTop, glassBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: 176, height: 246)
                .overlay {
                    RoundedRectangle(cornerRadius: 88, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                }
                // Two light streaks across the glass, cut to the glass shape.
                .overlay {
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 26, height: 260)
                            .rotationEffect(.degrees(24))
                            .offset(x: -42)
                        Capsule()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 9, height: 260)
                            .rotationEffect(.degrees(24))
                            .offset(x: -14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 88, style: .continuous))
                }

            MirrorFaceIcon()
                .frame(width: 72, height: 72)

            // Sparkles around the mirror. Two fade in while the other fades out.
            sparkleIcon(size: 18, opacity: 0.55)
                .offset(x: 112, y: -112)
                .opacity(sparkle ? 1 : 0.25)
                .scaleEffect(sparkle ? 1 : 0.7)

            sparkleIcon(size: 12, opacity: 0.45)
                .offset(x: -118, y: 84)
                .opacity(sparkle ? 0.25 : 1)
                .scaleEffect(sparkle ? 0.7 : 1)

            sparkleIcon(size: 9, opacity: 0.4)
                .offset(x: 120, y: 70)
                .opacity(sparkle ? 1 : 0.3)
        }
        .frame(height: 300)
        .accessibilityHidden(true)   // decoration only
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glow = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                sparkle = true
            }
        }
    }

    private func sparkleIcon(size: CGFloat, opacity: Double) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(accent.opacity(opacity))
    }
}

// MARK: - Simple friendly face (closed eyes, soft smile)

/// A small drawn face made only from circles. Drawn on a 72 x 72 frame.
struct MirrorFaceIcon: View {
    private let disc = Color(red: 232/255, green: 243/255, blue: 236/255)
    private let skin = Color(red: 243/255, green: 206/255, blue: 182/255)
    private let hair = Color(red: 92/255, green: 62/255, blue: 48/255)
    private let cheek = Color(red: 236/255, green: 150/255, blue: 140/255)

    var body: some View {
        ZStack {
            Circle().fill(disc)

            // Hair bun
            Circle()
                .fill(hair)
                .frame(width: 16, height: 16)
                .offset(x: -16, y: -22)

            // Face
            Circle()
                .fill(skin)
                .frame(width: 40, height: 40)
                .offset(y: 4)

            // Hair cap: `.trim(from: 0.5, to: 1)` keeps only the top half of the circle.
            Circle()
                .trim(from: 0.5, to: 1)
                .fill(hair)
                .frame(width: 42, height: 42)
                .offset(y: 3)

            // Cheeks
            Circle().fill(cheek.opacity(0.4)).frame(width: 8, height: 8).offset(x: -12, y: 12)
            Circle().fill(cheek.opacity(0.4)).frame(width: 8, height: 8).offset(x: 12, y: 12)

            // Closed eyes: small arcs from the bottom part of a circle.
            eyeArc.offset(x: -8, y: 6)
            eyeArc.offset(x: 8, y: 6)

            // Smile
            Circle()
                .trim(from: 0.12, to: 0.38)
                .stroke(hair, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 16, height: 16)
                .offset(y: 11)
        }
    }

    private var eyeArc: some View {
        Circle()
            .trim(from: 0.05, to: 0.45)
            .stroke(hair, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            .frame(width: 9, height: 9)
    }
}

#Preview {
    MirrorReflectionScreen()
}
