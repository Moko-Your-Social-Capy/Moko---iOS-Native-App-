//
//  RelaxCompletionScreen.swift
//  Moko
//
//  One shared "well done" screen used by every relax exercise.
//  Each exercise passes its own title, subtitle and button label so the
//  content stays different even though the layout is identical.
//
//  The GPay success sound plays once when the user taps the Continue button.
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

    var body: some View {
        ZStack {
            // The soft off-white gradient background used across all Moko screens.
            MokoBackdrop()

            VStack(spacing: 0) {
                // Small "Complete" pill aligned to the right, same as Grounding.
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

                Spacer(minLength: 16)

                // The animated ring with Moko inside – same component every exercise uses.
                MokoCompletionAnimation(ringDiameter: 190)
                    .transition(.opacity)

                VStack(spacing: 8) {
                    // Exercise-specific headline.
                    Text(title)
                        .mokoText(MokoScreenTheme.Typeface.title2)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)

                    // Exercise-specific description.
                    Text(subtitle)
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .padding(.top, 36)

                Spacer(minLength: 16)

                // Primary button – plays the GPay success chime then hands off to the caller.
                Button(action: {
                    // Play the celebration sound the moment the user taps Continue.
                    DebriefSoundPlayer.shared.playSuccess()
                    onContinue()
                }) {
                    Text(buttonLabel)
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 28)
            }
        }
        // Keep the tab bar hidden – immersive experience until the user taps Complete.
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    RelaxCompletionScreen(
        title: "Well done",
        subtitle: "You completed the 5-4-3-2-1 sensory reset"
    )
}

