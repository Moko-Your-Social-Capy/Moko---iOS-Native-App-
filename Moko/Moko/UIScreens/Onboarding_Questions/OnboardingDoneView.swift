//
//  OnboardingDoneView.swift
//  Moko
//
//  The celebration screen after onboarding is complete.
//  Colors come from the active MokoTheme so each theme gets its own look.
//

import SwiftUI

struct OnboardingDoneView: View {
    /// How many reflections the user completed.
    var completed: Int
    /// How many reflections onboarding asked in total.
    var total: Int
    /// Called when the user taps “Get started”.
    var onContinue: () -> Void

    @Environment(\.mokoTheme) private var theme

    init(
        completed: Int = OnboardingCardQuestion.totalSteps,
        total: Int = OnboardingCardQuestion.totalSteps,
        onContinue: @escaping () -> Void = {}
    ) {
        self.completed = completed
        self.total = total
        self.onContinue = onContinue
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 68)

            Text("WELCOME")
                .font(.footnote.weight(.semibold))
                .tracking(3)
                .foregroundStyle(theme.colors.secondaryText)
                .accessibilityAddTraits(.isHeader)

            Text("Onboarding\ncompleted")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-1.2)
                .multilineTextAlignment(.center)
                .lineSpacing(-2)
                .foregroundStyle(theme.colors.ctaAccent)
                .padding(.top, 12)

            OnboardingCompletedEmblem()
                .padding(.top, 54)
                .accessibilityLabel("Onboarding completed")

            Text("You’re ready")
                .font(.title.bold())
                .foregroundStyle(theme.colors.headingText)
                .padding(.top, 42)

            Text("You’re all set to begin your mindful journey.")
                .font(.body)
                .foregroundStyle(theme.colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer(minLength: 48)

            Button(action: onContinue) {
                Text("Get started")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.colors.primaryButtonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(theme.colors.primaryButton, in: Capsule())
            }
            .buttonStyle(.plain)
            .shadow(color: theme.colors.cardShadow.opacity(0.16), radius: 12, y: 6)
            .accessibilityHint("Opens your strengths")
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        // A soft themed gradient keeps the lighter completion background above the main background.
        .background {
            LinearGradient(
                colors: [theme.colors.completionBackground, theme.colors.screenBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(theme.preferredColorScheme)
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(completed) of \(total) reflections completed")
    }
}

/// Circular success mark built from MokoTheme colors.
private struct OnboardingCompletedEmblem: View {
    @Environment(\.mokoTheme) private var theme

    var body: some View {
        ZStack {
            // Outer ring uses the theme’s neutral text/shadow tones for contrast.
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.secondaryText.opacity(0.92),
                            theme.colors.tertiaryText.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: theme.colors.cardShadow.opacity(0.22), radius: 12, y: 8)

            // Inner disc uses semantic success and CTA colors from the active theme.
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.success.opacity(0.82),
                            theme.colors.ctaAccent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(12)

            Circle()
                .stroke(theme.colors.inverseText.opacity(0.35), lineWidth: 2)
                .padding(16)

            Circle()
                .fill(theme.colors.cardSurface)
                .frame(width: 70, height: 70)
                .shadow(color: theme.colors.cardShadow.opacity(0.12), radius: 8, y: 4)

            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(theme.colors.ctaAccent)
                .accessibilityHidden(true)
        }
        .frame(width: 168, height: 168)
        .accessibilityElement(children: .ignore)
    }
}

#Preview {
    OnboardingDoneView()
        .mokoThemeRoot()
}
