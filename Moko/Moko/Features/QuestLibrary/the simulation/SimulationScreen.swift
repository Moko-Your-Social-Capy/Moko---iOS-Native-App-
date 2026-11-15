//
//  SimulationScreen.swift
//  Moko
//
//  A self-paced rehearsal before a real quest. Nothing is recorded, scored,
//  or marked complete here. The user returns to the briefing when ready.
//
//  Comment style: every important line has a short, plain-words comment.

import SwiftUI
import SwiftData

/// The main simulation screen. It runs a short video-call-style conversation
/// with Moko, then shows a "conversation done" popup and a deep-dive choice.
struct SimulationScreen: View {
    /// Which quest this simulation belongs to (its title, for the debrief link).
    let questTitle: String

    // Closes practice without changing the saved quest.
    @Environment(\.dismiss) private var dismiss

    /// Which stage the screen is on.
    @State private var stage: Stage = .talking

    /// Which line of the conversation is showing right now.
    @State private var currentLine = 0

    /// True when the "conversation done" popup is showing.
    @State private var showDonePopup = false

    /// The lines Moko "says" during the call, in order.
    private var lines: [String] {
        [
            "Picture this moment: \(questTitle). Take your time to imagine where you are.",
            "Try your opening sentence out loud, or quietly in your head. Nothing is recorded.",
            "Imagine the other person responds. What could you ask to understand them better?",
            "Try one clear, kind sentence that moves toward your goal.",
            "Choose one small step to try in the real moment. You can practice again whenever you like.",
        ]
    }

    /// The stages of the simulation.
    private enum Stage {
        case talking   // The video-call conversation is running
        case done      // The conversation is finished
    }

    var body: some View {
        ZStack {
            MokoBackdrop()

            ScrollView {
              VStack(spacing: 0) {
                // MARK: Video-call style header
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    Text("Guided rehearsal")
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
                    MokoAnimatedMascotView(size: MokoScreenTheme.Size.mascotFlash)
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)

                Text("Step \(currentLine + 1) of \(lines.count) · At your pace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)

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
                         ? "Finish practice" : "Next")
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
            }
            .accessibilityHidden(showDonePopup)
            .allowsHitTesting(!showDonePopup)

            // MARK: "Conversation done" popup
            if showDonePopup {
                ConversationDonePopup(
                    onReviewQuest: { dismiss() },
                    onPracticeAgain: {
                        currentLine = 0
                        stage = .talking
                        showDonePopup = false
                    }
                )
                .transition(.opacity)
            }
        }
    }

    /// Moves to the next conversation line. When the last line ends, shows
    /// the "conversation done" popup.
    private func nextLine() {
        guard stage == .talking else { return }
        if currentLine < lines.count - 1 {
            currentLine += 1
        } else {
            stage = .done
            showDonePopup = true
        }
    }

}

/// The popup that appears when the conversation ends.
private struct ConversationDonePopup: View {
    let onReviewQuest: () -> Void
    let onPracticeAgain: () -> Void

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

                Text("A little more ready")
                    .mokoText(MokoScreenTheme.Typeface.title1)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    .multilineTextAlignment(.center)

                Text("Practice is complete. Return to your quest and try it in real life. Debrief afterward to reflect on what actually happened.")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MokoScreenTheme.Space.page)

                VStack(spacing: MokoScreenTheme.Space.s3) {
                    Button("Back to quest") {
                        onReviewQuest()
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(MokoScreenTheme.Colors.forest)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.pill))

                    Button("Practice again") {
                        onPracticeAgain()
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
