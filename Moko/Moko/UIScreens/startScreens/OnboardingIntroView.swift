//
//  OnboardingIntroView.swift
//  Moko
//
//  The welcome screen after the splash: the mascot says hello,
//  a short line explains the app, and "Let's Begin" starts sign-in.
//

import SwiftUI
import Lottie

struct OnboardingIntroView: View {
    /// Called when the user taps "Let's Begin".
    var onLetsBegin: () -> Void = {}

    // False at the start, true once the text and button have faded in.
    @State private var hasAppeared = false

    // The phone setting "Reduce Motion". If it is on, text fades but does not slide.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // GeometryReader gives us the screen width, so the mascot fits small phones too.
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Capybara mascot waving welcomes the user on the intro screen.
                WavingMokoMascot(size: min(geometry.size.width * 0.62, 250))
                    .padding(.bottom, 16)

                Text("Hello, I'm Moko.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .modifier(RiseIn(isVisible: hasAppeared, distance: 12, reduceMotion: reduceMotion))

                Text("Small daily nudges, an honest chat\nafter, that's it!")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .padding(.horizontal, 32)
                    .modifier(RiseIn(isVisible: hasAppeared, distance: 16, reduceMotion: reduceMotion))

                Spacer(minLength: 40)

                letsBeginButton
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.bottom, 20)
                    .modifier(RiseIn(isVisible: hasAppeared, distance: 20, reduceMotion: reduceMotion))
            }
            .multilineTextAlignment(.center)
            // Phones without a notch or home bar get a little extra breathing room.
            .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 16)
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MokoBackdrop())
            // .onAppear runs when the screen first shows. It starts the fade-in.
            .onAppear {
                withAnimation(MokoScreenTheme.Motion.crossfade) {
                    hasAppeared = true
                }
            }
        }
    }

    private var letsBeginButton: some View {
        Button {
            // A small tap you can feel, so the button feels pressed.
            MokoTheme.playFeedback(.medium)
            onLetsBegin()
        } label: {
            Text("Let's Begin")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MokoScreenTheme.Colors.dataVioletDeep, in: Capsule())
        }
        .buttonStyle(MokoPrimaryButtonStyle())
    }
}

// MARK: - Waving Moko Mascot

/// Shows MokoMascot.png with a continuous waving animation driven by TimelineView.
/// The image sways left-right anchored at the bottom centre, like a figure waving.
/// Entrance: scales up from 0.85 and fades in. Reduce Motion: entrance fades only, no sway.
private struct WavingMokoMascot: View {
    var size: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
            let t = reduceMotion ? 0.0
                : tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100)

            // Cycle = 3.4 s: 2.4 s of waving (3 swings) then 1 s rest.
            let cycle = t.truncatingRemainder(dividingBy: 3.4)
            let waving = cycle < 2.4

            // Smooth ramp-up / ramp-down in 0.15 s so the motion starts and ends softly.
            let envelope: Double = waving
                ? min(1.0, min(cycle / 0.15, (2.4 - cycle) / 0.15))
                : 0.0

            let angle = waving ? sin(cycle * .pi * 2.5) * 18.0 * envelope : 0.0

            Image("MokoMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                // Rotate around the bottom-centre so the mascot sways upright.
                .rotationEffect(.degrees(angle), anchor: .bottom)
        }
        // Entrance animation matching the original mascot view.
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0.0)
        .offset(y: appeared || reduceMotion ? 0 : size * 0.12)
        .accessibilityLabel("Moko waves hello")
        .onAppear {
            withAnimation(reduceMotion
                ? MokoScreenTheme.Motion.crossfade
                : MokoScreenTheme.Motion.mascotEntrance
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Rise-in modifier

/// Fades a view in and lifts it up a few points. With Reduce Motion it only fades.
private struct RiseIn: ViewModifier {
    let isVisible: Bool
    let distance: CGFloat
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : distance)
    }
}

#Preview {
    OnboardingIntroView()
}
