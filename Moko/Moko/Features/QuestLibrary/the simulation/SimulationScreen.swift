//
//  SimulationScreen.swift
//  Moko
//
//  The Duolingo-style video call simulation. After the flash screen, this
//  shows a video-call-style conversation with Moko. When the conversation
//  ends, a popup says the conversation is done. The user can then deep dive
//  into the debrief now or later. The debrief is linked to the quest card in
//  the Quest Library / Quests section.
//
//  Comment style: every important line has a short, plain-words comment.

import SwiftUI
import SwiftData

/// The main simulation screen. It runs a short video-call-style conversation
/// with Moko, then shows a "conversation done" popup and a deep-dive choice.
struct SimulationScreen: View {
    /// Which quest this simulation belongs to (its title, for the debrief link).
    let questTitle: String

    /// Which stage the screen is on.
    @State private var stage: Stage = .talking

    /// Which line of the conversation is showing right now.
    @State private var currentLine = 0

    /// True when the "conversation done" popup is showing.
    @State private var showDonePopup = false

    /// The lines Moko "says" during the call, in order.
    private let lines = [
        "Hi! I'm Moko. Let's talk about \(questTitle).",
        "How are you feeling right now?",
        "That's okay — lots of people feel that way.",
        "What's one small thing you could try today?",
        "Great idea. I'll check in with you tomorrow.",
    ]

    /// The stages of the simulation.
    private enum Stage {
        case talking   // The video-call conversation is running
        case done      // The conversation is finished
    }

    var body: some View {
        ZStack {
            MokoScreenTheme.Colors.canvasTop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Video-call style header
                HStack {
                    Image(systemName: "video.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    Text("Moko Call")
                        .mokoText(MokoScreenTheme.Typeface.section)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    Spacer()
                    Image(systemName: "person.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                }
                .padding(MokoScreenTheme.Space.page)

                // MARK: Moko mascot (the "video" person)
                ZStack {
                    RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card)
                        .fill(MokoScreenTheme.Colors.surfaceWhite)
                        .frame(height: 320)
                    Image("MokoMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: MokoScreenTheme.Size.mascotFlash)
                        .symbolEffect(.bounce, value: currentLine)
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)

                // MARK: Conversation line
                if stage == .talking {
                    Text(lines[currentLine])
                        .mokoText(MokoScreenTheme.Typeface.title2)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        .multilineTextAlignment(.center)
                        .padding(MokoScreenTheme.Space.page)
                        .contentTransition(.opacity)
                }

                Spacer(minLength: 0)

                // MARK: Continue button
                Button {
                    nextLine()
                } label: {
                    Text(stage == .talking && currentLine == lines.count - 1
                         ? "End call" : "Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(MokoScreenTheme.Colors.forest)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.pill))
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, MokoScreenTheme.Space.s7)
                .disabled(stage == .done)
            }

            // MARK: "Conversation done" popup
            if showDonePopup {
                ConversationDonePopup(
                    onDeepDiveNow: {
                        showDonePopup = false
                        onDeepDive?(.now)
                    },
                    onDeepDiveLater: {
                        showDonePopup = false
                        onDeepDive?(.later)
                    }
                )
                .transition(MokoScreenTheme.Motion.crossfade)
            }
        }
        // `.task` starts the conversation line timer when the screen appears.
        .task {
            await startConversation()
        }
        // When the popup closes, tell the parent what the user chose.
        .onChange(of: showDonePopup) { old, new in
            if !new, old {
                // Popup just closed; parent already got the choice above.
            }
        }
    }

    /// Tells the parent whether the user wants to deep dive now or later.
    var onDeepDive: ((DeepDiveChoice) -> Void)? = nil

    /// Moves to the next conversation line. When the last line ends, shows
    /// the "conversation done" popup.
    private func nextLine() {
        if currentLine < lines.count - 1 {
            currentLine += 1
        } else {
            // Conversation is over. Show the done popup after a short pause.
            stage = .done
            try? Task.sleep(for: .seconds(0.6))
            withAnimation(MokoScreenTheme.Motion.crossfade) {
                showDonePopup = true
            }
        }
    }

    /// Starts the conversation: each line shows for a few seconds, then moves on.
    private func startConversation() async {
        for index in lines.indices {
            currentLine = index
            try? await Task.sleep(for: .seconds(4))
        }
        // After the last line, end the call and show the popup.
        stage = .done
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation(MokoScreenTheme.Motion.crossfade) {
            showDonePopup = true
        }
    }
}

/// What the user chooses when the conversation is done.
enum DeepDiveChoice {
    case now    // Open the debrief right away
    case later  // Save the debrief for later (it stays on the quest card)
}

/// The popup that appears when the conversation ends.
private struct ConversationDonePopup: View {
    let onDeepDiveNow: () -> Void
    let onDeepDiveLater: () -> Void

    var body: some View {
        ZStack {
            // Dim the screen behind the popup.
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: MokoScreenTheme.Space.s4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(MokoScreenTheme.Colors.forest)

                Text("Conversation done")
                    .mokoText(MokoScreenTheme.Typeface.title1)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    .multilineTextAlignment(.center)

                Text("You finished talking with Moko. Your debrief is saved on the quest card.")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MokoScreenTheme.Space.page)

                HStack(spacing: MokoScreenTheme.Space.s3) {
                    Button("Deep dive now") {
                        onDeepDiveNow()
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(MokoScreenTheme.Colors.forest)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.pill))

                    Button("Later") {
                        onDeepDiveLater()
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(MokoScreenTheme.Colors.surfaceLavender)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.pill))
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
            }
            .padding(MokoScreenTheme.Space.s6)
            .background(MokoScreenTheme.Colors.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card))
            .shadow(color: MokoScreenTheme.Elevation.ambientColor,
                    radius: MokoScreenTheme.Elevation.ambientRadius,
                    x: 0, y: MokoScreenTheme.Elevation.ambientOffset)
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Preview

#Preview {
    SimulationScreen(questTitle: "Talk to a friend about how you feel")
}
