//
//  CompletionCard.swift
//  Moko
//
//  Completion card that springs in with confetti and fades out smoothly.
//  Used after quest completion, onboarding finish, and similar celebrations.
//

import SwiftUI

/// Centered completion card with title, message, and action button.
struct CompletionCard: View {
    let title: String
    let message: String
    var button: String = "Continue"
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Mascot celebration mood
            MokoMascot(mood: .celebrate, size: 120)

            Text(title)
                .font(.title2.bold())
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            Text(message)
                .font(.body)
                .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                .multilineTextAlignment(.center)

            Button(action: onContinue) {
                Text(button)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MokoScreenTheme.Colors.dataVioletDeep, in: Capsule())
            }
            .buttonStyle(MokoPressStyle())
            .padding(.top, 6)
        }
        .padding(24)
        .background(MokoScreenTheme.Colors.surfaceWhite, in: RoundedRectangle(cornerRadius: 28))
        .shadow(
            color: Color.black.opacity(0.18),
            radius: 24,
            y: 10
        )
    }
}

/// Modifier to present a completion popup with dimmed background.
/// Scales in and fades out smoothly using MokoMotion.bouncy.
extension View {
    func completionPopup<Popup: View>(
        isPresented: Bool,
        @ViewBuilder content: () -> Popup
    ) -> some View {
        ZStack {
            self

            if isPresented {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)

                content()
                    .padding(32)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    // Slide-up variant: .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(MokoMotion.bouncy, value: isPresented)
    }
}

#Preview {
    CompletionCard(
        title: "Quest Complete!",
        message: "Great job staying present today.",
        button: "Next"
    ) { }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
}
