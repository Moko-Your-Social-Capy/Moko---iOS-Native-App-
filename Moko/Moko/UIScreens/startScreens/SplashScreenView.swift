//
//  SplashScreenView.swift
//  Moko
//
//  The first screen people see: the "Moko" name fades in and the
//  mascot pops up from the bottom edge. Tap anywhere to skip it.
//

import SwiftUI

struct SplashScreenView: View {
    /// When true the splash moves on by itself. Previews turn this off.
    var autoAdvance = true
    /// Called once when the splash is done, so the app can show the next screen.
    var onFinished: () -> Void = {}

    // The phone setting "Reduce Motion". If it is on, we fade instead of sliding.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mokoTheme) private var theme

    // False at the start, true after the entrance plays.
    // Flipping it inside withAnimation is what makes things move.
    @State private var hasAppeared = false

    // Remembers that we already left, so a tap and the timer can't both fire.
    @State private var didFinish = false

    /// How long the splash stays on screen after the mascot arrives.
    private let holdDuration: Duration = .milliseconds(1_500)

    var body: some View {
        // The whole screen is one big button so a tap skips the wait.
        Button(action: finish) {
            // GeometryReader tells us the screen size so the mascot fits any phone.
            GeometryReader { geometry in
                SplashLayout(size: geometry.size, hasAppeared: hasAppeared, reduceMotion: reduceMotion, theme: theme)
            }
            .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Moko")
        .accessibilityHint("Continue to the app")
        // .task runs when the screen shows up. It is cancelled by itself
        // if the screen goes away, so the timer never fires late.
        .task {
            await playEntranceThenFinish()
        }
    }

    /// Plays the entrance, waits a moment, then moves on.
    private func playEntranceThenFinish() async {
        do {
            // A tiny pause so the first frame is a clean screen.
            try await Task.sleep(for: .milliseconds(80))

            withAnimation(reduceMotion ? MokoScreenTheme.Motion.crossfade : MokoScreenTheme.Motion.mascotEntrance) {
                hasAppeared = true
            }

            guard autoAdvance else { return }
            try await Task.sleep(for: holdDuration)
            finish()
        } catch {
            // Task.sleep throws only when the splash was closed early. Nothing to do.
        }
    }

    /// Leaves the splash exactly once.
    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

/// Draws the name and the mascot. Kept apart so the splash `body` stays short.
private struct SplashLayout: View {
    let size: CGSize
    let hasAppeared: Bool
    let reduceMotion: Bool
    let theme: MokoResolvedTheme

    private var isLandscape: Bool { size.width > size.height }

    /// In portrait the mascot is a little wider than the screen, so it peeks up from the bottom.
    private var mascotWidth: CGFloat {
        min(size.width * (isLandscape ? 0.47 : 1.06),
            size.height * (isLandscape ? 0.72 : 0.62))
    }

    private var mascotHeight: CGFloat { mascotWidth * MokoScreenTheme.Size.mascotAspect }

    var body: some View {
        ZStack {
            MokoBackdrop()

            // The app name. A fixed size on purpose: it is the logo, not reading text.
            Text("Moko")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .tracking(-3)
                .foregroundStyle(theme.colors.ctaAccent)
                .opacity(hasAppeared ? 1 : 0)
                .position(x: size.width * (isLandscape ? 0.27 : 0.5),
                          y: size.height * (isLandscape ? 0.44 : 0.30))

            // The mascot starts one full height below its spot, then springs up.
            // With Reduce Motion it stays in place and only fades in.
            Image("MokoMascot")
                .resizable()
                .scaledToFit()
                .frame(width: mascotWidth, height: mascotHeight)
                .position(x: size.width * (isLandscape ? 0.74 : 0.5),
                          y: size.height - mascotHeight * 0.28)
                .offset(y: hasAppeared || reduceMotion ? 0 : mascotHeight)
                .opacity(hasAppeared ? 1 : 0)
                .accessibilityHidden(true)
        }
        .frame(width: size.width, height: size.height)
        // Hides the parts of the mascot that hang off the screen.
        .clipped()
    }
}

#Preview("Splash") {
    SplashScreenView(autoAdvance: false)
}
