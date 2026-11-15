//
//  MokoFlashScreen.swift
//  Moko
//
//  The first screen of "the simulation". It shows the Moko mascot flash
//  (appear and disappear quickly, like a blink), then the selected quest's
//  task name shows for a few seconds, then fades away. After that the app
//  moves on to the Duolingo-style video call simulation.
//
//  Comment style: every important line has a short, plain-words comment.

import SwiftUI

/// The flash screen that opens when the user picks a quest from the library.
/// It runs through three stages: flash → task text → done.
struct MokoFlashScreen: View {
    /// Which quest the user tapped. Its title shows as the "task name".
    let questTitle: String

    /// What stage the screen is on. Starts at .flash, then .task, then .done.
    @State private var stage: Stage = .flash

    /// True while the Moko image is showing (so it can blink on and off).
    @State private var mokoIsVisible = true

    /// The three stages, in order.
    private enum Stage {
        case flash      // Moko blinks on and off
        case task       // Task name shows for a few seconds
        case done       // Ready to start the simulation
    }

    var body: some View {
        ZStack {
            // Background from the shared theme.
            MokoScreenTheme.Colors.canvasTop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Moko mascot area
                ZStack {
                    if mokoIsVisible {
                        // The mascot picture from Assets.xcassets.
                        Image("MokoMascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: MokoScreenTheme.Size.mascotFlash,
                                   height: MokoScreenTheme.Size.mascotFlash)
                            .symbolEffect(.bounce, value: mokoIsVisible)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: Task text area
                if stage == .task {
                    Text(questTitle)
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        .multilineTextAlignment(.center)
                        .padding(MokoScreenTheme.Space.page)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        // `.task` runs when the screen first shows up. It drives the stages.
        .task {
            await runStages()
        }
        // When all stages are done, the parent screen starts the simulation.
        .onChange(of: stage) { old, new in
            if new == .done {
                onFinished?()
            }
        }
    }

    /// Called by the parent when the flash + task stages finish.
    var onFinished: (() -> Void)? = nil

    /// Runs the three stages one after another with pauses between them.
    private func runStages() async {
        // Stage 1: flash the Moko image on and off three times.
        for _ in 0..<3 {
            try? await Task.sleep(for: .seconds(0.35))
            mokoIsVisible.toggle()
            try? await Task.sleep(for: .seconds(0.35))
            mokoIsVisible.toggle()
        }

        // Leave the mascot visible at the end of the flash.
        mokoIsVisible = true

        // Stage 2: show the task name for a few seconds.
        withAnimation(MokoScreenTheme.Motion.crossfade) {
            stage = .task
        }
        try? await Task.sleep(for: .seconds(4))

        // Stage 3: hide the task name and mark the screen as done.
        withAnimation(MokoScreenTheme.Motion.crossfade) {
            stage = .done
        }
    }
}

// MARK: - Preview

#Preview {
    MokoFlashScreen(questTitle: "Talk to a friend about how you feel")
}
