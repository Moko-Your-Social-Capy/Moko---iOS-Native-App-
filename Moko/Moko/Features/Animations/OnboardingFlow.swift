//
//  OnboardingFlow.swift
//  Moko
//
//  Onboarding screen flow with stationary mascot and sliding question cards.
//  Directional transitions based on forward/backward navigation.
//  Smooth progress bar fill and haptic feedback.
//

import SwiftUI

/// Container for onboarding flow with progress tracking and smooth screen transitions.
/// The mascot stays in place; only the question content slides in/out.
struct OnboardingFlow<QuestionView: View>: View {
    @State private var step = 0
    @State private var goingForward = true
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let totalSteps: Int
    private let questionViewBuilder: (Int, (Int) -> Void) -> QuestionView
    private let onFinish: () -> Void

    init(
        totalSteps: Int,
        @ViewBuilder questionView: @escaping (Int, (Int) -> Void) -> QuestionView,
        onFinish: @escaping () -> Void
    ) {
        self.totalSteps = totalSteps
        self.questionViewBuilder = questionView
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 16) {
            // Progress bar – smooth fill based on step
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MokoScreenTheme.Colors.dataViolet.opacity(0.15))

                    Capsule()
                        .fill(MokoScreenTheme.Colors.dataVioletDeep)
                        .frame(width: g.size.width * Double(step + 1) / Double(totalSteps))
                }
            }
            .frame(height: 10)
            .animation(MokoMotion.snappy, value: step)

            // Mascot – changes mood on first screen
            MokoMascot(
                mood: step == 0 ? .waving : .idle,
                size: 110
            )
            .transition(.opacity)

            // Question content – slides based on direction, with unique id per step
            ZStack {
                questionViewBuilder(step) { delta in
                    go(delta)
                }
                .id(step)  // New id triggers transition
                .transition(slideTransition)
                .clipped()
            }

            // Back button – only show after first step
            if step > 0 {
                Button(action: { go(-1) }) {
                    Text("Back")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                }
                .transition(.opacity)
            }

            Spacer()
        }
        .padding()
    }

    /// Directional slide transition – forward enters from trailing, backward from leading.
    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingForward ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: goingForward ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    /// Navigate forward or backward, triggering completion when appropriate.
    private func go(_ delta: Int) {
        let nextStep = step + delta

        // Last step completed – trigger confetti and completion popup
        if nextStep >= totalSteps {
            onFinish()
            return
        }

        // Update direction first
        goingForward = delta > 0

        // Animate step change
        if !reduceMotion {
            DispatchQueue.main.async {
                withAnimation(MokoMotion.snappy) {
                    step = nextStep
                }
            }
        } else {
            step = nextStep
        }
    }
}

#Preview {
    OnboardingFlow(
        totalSteps: 3,
        questionView: { step, onNext in
            VStack(spacing: 16) {
                Text("Question \(step + 1)")
                    .font(.title2.bold())

                Text("This is step \(step + 1) of your onboarding.")
                    .foregroundStyle(.secondary)

                Button("Next") {
                    onNext(1)
                }
                .buttonStyle(MokoPressStyle())
            }
            .padding()
        },
        onFinish: { }
    )
}
