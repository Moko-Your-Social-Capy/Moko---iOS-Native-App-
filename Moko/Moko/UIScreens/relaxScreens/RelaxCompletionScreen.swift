//
//  RelaxCompletionScreen.swift
//  Moko
//
//  Brief completion overlay shown after a Relax exercise finishes.
//  Plays Confetti 2, shows "Completed" and the exercise name, then auto-dismisses.
//

import SwiftUI
import Lottie

/// Full-screen blurred completion overlay for Relax exercises.
struct RelaxCompletionScreen: View {
    // The completed Relax exercise's actual title, e.g. "Box Breathing".
    let exerciseTitle: String
    // Runs after the overlay is dismissed (return to Relax home / continue flow).
    var onContinue: () -> Void = {}

    // Kept for call-site compatibility; the overlay always auto-returns.
    var accent: Color = MokoScreenTheme.Colors.dataVioletDeep
    var title: String = "Completed"
    var subtitle: String = ""
    var buttonLabel: String = "Complete"

    @Environment(\.mokoTheme) private var theme
    // Prevents duplicate completion callbacks/navigation from multiple triggers.
    @State private var hasCompleted = false
    // Remembers whether the success sound has played, so it only happens once.
    @State private var hasPlayedSound = false

    var body: some View {
        ZStack {
            // Very light translucent blur so the Relax home remains clearly visible underneath.
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.55))
                .ignoresSafeArea()
            // Soft tint keeps it readable without heavy frosting.
            theme.colors.screenBackground.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                // Confetti 2 plays immediately in the centre.
                MokoLottieView(animation: .confetti2, loopMode: .playOnce)
                    .frame(width: 260, height: 260)

                Text("Completed")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(exerciseTitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, MokoScreenTheme.Space.page)
        }
        .transition(.opacity)
        .onAppear {
            guard !hasPlayedSound else { return }
            hasPlayedSound = true
            // Play the celebration chime once when the completion overlay appears.
            DebriefSoundPlayer.shared.playSuccess()
        }
        // Show briefly on Relax home, then dismiss automatically.
        .task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, !hasCompleted else { return }
            hasCompleted = true
            onContinue()
        }
    }
}

#Preview {
    ZStack {
        MokoBackdrop()
        RelaxCompletionScreen(exerciseTitle: "Box Breathing")
    }
}
