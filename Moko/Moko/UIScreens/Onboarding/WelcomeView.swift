//
//  WelcomeView.swift
//  Moko
//
//  Personalized intro screen: greets the user by name and starts onboarding reflections.
//

import SwiftUI

struct WelcomeView: View {
    /// The name the user typed on the previous screen.
    let name: String
    /// Called when the user taps “Start reflections”.
    var onStart: () -> Void = {}

    @Environment(\.mokoTheme) private var theme

    /// “Nice to meet you, Sam”, or without the name if it is blank.
    private var greeting: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nice to meet\nyou" : "Nice to meet\nyou, \(trimmed)"
    }

    var body: some View {
        OnboardingJourneyScaffold(
            currentPage: 2,
            buttonTitle: "Start reflections",
            footer: "Moko will shape the practice around your answers.",
            action: onStart
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Label("WELCOME", systemImage: "sun.max.fill")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(theme.colors.ctaAccentText.opacity(0.75))

                Text(greeting)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .tracking(-1.2)
                    .lineSpacing(-2)
                    .foregroundStyle(theme.colors.ctaAccentText)
                    .padding(.top, 16)

                Text("A few quick questions help Moko understand how you move through social moments.")
                    .font(.subheadline.weight(.medium))
                    .lineSpacing(3)
                    .foregroundStyle(theme.colors.ctaAccentText.opacity(0.82))
                    .padding(.top, 14)

                Spacer(minLength: 22)

                // Capybara mascot waving, hidden from VoiceOver.
                WavingMokoMascot(size: 205)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                Spacer(minLength: 22)

                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.bold))
                    Text("Your answers stay personal to you.")
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(theme.colors.ctaAccentText.opacity(0.86))
                .padding(12)
                .background(theme.colors.inverseText.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView(name: "Aditi")
    }
    .mokoThemeRoot()
}
