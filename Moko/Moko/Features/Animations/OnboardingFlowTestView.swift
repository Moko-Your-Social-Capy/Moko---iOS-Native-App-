//
//  OnboardingFlowTestView.swift
//  Moko
//
//  Test screen to demo the animated OnboardingFlow component.
//  Shows sliding card transitions with mascot mood changes.
//

import SwiftUI

/// Test view to showcase the OnboardingFlow animation component.
struct OnboardingFlowTestView: View {
    @State private var showCompletion = false

    var body: some View {
        ZStack {
            MokoScreenTheme.Colors.canvasTop.ignoresSafeArea()

            if !showCompletion {
                OnboardingFlow(
                    totalSteps: 3,
                    questionView: { step, onNext in
                        VStack(spacing: 20) {
                            Text("Question \(step + 1) of 3")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MokoScreenTheme.Colors.textMuted)

                            Text(questionTitle(step))
                                .font(.title2.bold())
                                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

                            Text(questionSubtitle(step))
                                .font(.body)
                                .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                                .multilineTextAlignment(.center)

                            Spacer()

                            Button(action: { onNext(1) }) {
                                Text(step == 2 ? "Finish" : "Next")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(MokoScreenTheme.Colors.dataVioletDeep, in: Capsule())
                            }
                            .buttonStyle(MokoPressStyle())
                        }
                        .padding(24)
                        .background(MokoScreenTheme.Colors.surfaceWhite, in: RoundedRectangle(cornerRadius: 22))
                    },
                    onFinish: {
                        showCompletion = true
                    }
                )
                .padding()
            } else {
                VStack(spacing: 24) {
                    CompletionCard(
                        title: "Animation Test Complete!",
                        message: "You've tested the smooth onboarding flow transitions.",
                        button: "Back to Test"
                    ) {
                        showCompletion = false
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("OnboardingFlow Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func questionTitle(_ step: Int) -> String {
        switch step {
        case 0: return "What's your name?"
        case 1: return "How do you feel?"
        case 2: return "Ready to begin?"
        default: return ""
        }
    }

    private func questionSubtitle(_ step: Int) -> String {
        switch step {
        case 0: return "We'd love to know what to call you."
        case 1: return "Tell us how you're feeling today."
        case 2: return "Let's start your first quest!"
        default: return ""
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingFlowTestView()
    }
    .background(MokoScreenTheme.Colors.canvasTop)
}
