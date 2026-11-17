//
//  RelaxCompletionScreen.swift
//  Moko
//
//  One shared "well done" screen used by every relax exercise.
//  Each exercise passes its own title, subtitle and button label so the
//  content stays different even though the layout is identical.
//
//  The GPay success sound plays once when the checkmark screen appears.
//

import SwiftUI

/// The standard completion screen for all relax exercises.
struct RelaxCompletionScreen: View {
    // The big headline, e.g. "Well done" or "You did it!"
    let title: String
    // The smaller line under the headline – exercise specific message.
    let subtitle: String
    // Label on the primary action button, e.g. "Complete" or "Done".
    var buttonLabel: String = "Complete"
    // Accent colour for the button (defaults to the shared design-system violet).
    var accent: Color = MokoScreenTheme.Colors.dataVioletDeep
    // Called when the user taps the primary button.
    var onContinue: () -> Void = {}
    
    @State private var showCelebration = false
    // Remembers whether the success sound has played, so it only happens once.
    @State private var hasPlayedSound = false

    var body: some View {
        ZStack {
            // The soft off-white gradient background used across all Moko screens.
            MokoBackdrop()

            VStack(spacing: 0) {
                // Small "Complete" pill aligned to the right
                HStack {
                    Spacer()
                    Text("Complete")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(Capsule().fill(MokoScreenTheme.Colors.surfaceLavender.opacity(0.7)))
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 8)

                Spacer(minLength: 20)

                // The tick animation celebrates the completed relax session.
                MokoTickCompleteView(size: 260)
                    .frame(height: 280)

                Spacer(minLength: 28)

                // Larger headline and better formatted subtitle
                VStack(spacing: 12) {
                    // Exercise-specific headline (larger and bolder)
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    // Exercise-specific description (better spaced)
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .lineSpacing(5)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(4)
                }

                Spacer(minLength: 32)

                // Primary button – hands off to caller to dismiss or navigate.
                Button(action: onContinue) {
                    Text(buttonLabel)
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 36)
            }
        }
        // Keep the tab bar hidden – immersive experience until the user taps Complete
        .toolbar(.hidden, for: .tabBar)
        // Hide the back button for immersive completion experience
        .navigationBarBackButtonHidden(true)
        .celebration($showCelebration, style: .confetti, duration: 3.5)
        .onAppear {
            showCelebration = true
            // Play the celebration chime when the checkmark screen is displayed.
            if !hasPlayedSound {
                hasPlayedSound = true
                DebriefSoundPlayer.shared.playSuccess()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RelaxCompletionScreen(
            title: "Well done",
            subtitle: "You completed the 5-4-3-2-1 sensory reset"
        )
    }
}
