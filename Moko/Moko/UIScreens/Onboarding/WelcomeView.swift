//
//  WelcomeView.swift
//  Moko
//
//  Intro step 4 (last): greets the user by name and starts the reflection questions.
//

import SwiftUI

struct WelcomeView: View {
    /// The name the user typed on NameEntryView.
    let name: String
    /// Called when the user taps "Start reflections".
    var onStart: () -> Void = {}

    /// "Nice to meet you, Sam", or without the name if it is blank.
    private var greeting: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nice to meet you" : "Nice to meet you, \(trimmed)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Last intro step, so the bar is full.
            OnboardingProgressBar(progress: 1)
                .padding(.horizontal, 20)

            Text(greeting)
                .font(.system(size: 25, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 57)

            Text("Moko has a few quick questions to personalize your daily practice.")
                .font(.system(size: 17))
                .lineSpacing(3)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: 300, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 32)

            Image("welcome_moko")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .accessibilityHidden(true)

            Spacer(minLength: 16)

            OnboardingContinueButton(title: "Start reflections", action: onStart)
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
        }
        .background(MokoTheme.limeBackground.ignoresSafeArea())
    }
}

#Preview {
    WelcomeView(name: "Aditi")
}
