//
//  GroundingExerciseScreen.swift
//  Moko
//
//  Guided 5-4-3-2-1 sensory grounding exercise.
//  Consistent layout and smooth transitions between all five steps.
//  Completion badge styling matches BreathingSessionScreen.
//  When the exercise finishes, the time spent (stopwatch from start to finish)
//  is saved to SwiftData as a CalmDownModel, which the Summary screen shows.
//

import SwiftUI
import SwiftData

struct GroundingExerciseScreen: View {
    var onExit: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var currentStepIndex = 0
    @State private var selectedNumbers: Set<Int> = []
    @State private var isCompleted = false

    // Stopwatch: starts when the screen opens, stops when the exercise is finished
    @Environment(\.modelContext) private var modelContext
    @State private var startDate: Date?

    // MARK: - Colors

    private let screenBg = Color(
        red: 242 / 255,
        green: 242 / 255,
        blue: 247 / 255
    )

    private let cardGreen = Color(
        red: 54 / 255,
        green: 89 / 255,
        blue: 72 / 255
    )

    private let trackGreen = Color(
        red: 203 / 255,
        green: 230 / 255,
        blue: 211 / 255
    )

    private let subtextGray = Color(
        red: 111 / 255,
        green: 103 / 255,
        blue: 98 / 255
    )

    private let chipBg = Color(
        red: 237 / 255,
        green: 237 / 255,
        blue: 237 / 255
    )

    private let cream = Color(
        red: 252 / 255,
        green: 248 / 255,
        blue: 240 / 255
    )

    // MARK: - Grounding Steps

    private struct GroundingStep {
        let number: Int
        let title: String
        let instruction: String
        let examples: String
    }

    private let steps: [GroundingStep] = [
        GroundingStep(
            number: 5,
            title: "See",
            instruction: "Notice five things you can see around you.",
            examples: "Look for colors, shapes, light, shadows, or objects nearby."
        ),
        GroundingStep(
            number: 4,
            title: "Touch",
            instruction: "Notice four things you can physically feel.",
            examples: "Feel your feet on the floor, your clothes, or the chair beneath you."
        ),
        GroundingStep(
            number: 3,
            title: "Hear",
            instruction: "Notice three things you can hear.",
            examples: "Listen for voices, distant traffic, a fan, or birds outside."
        ),
        GroundingStep(
            number: 2,
            title: "Smell",
            instruction: "Notice two things you can smell.",
            examples: "Notice the air around you, the scent of your surroundings, or your clothing."
        ),
        GroundingStep(
            number: 1,
            title: "Taste",
            instruction: "Notice one thing you can taste.",
            examples: "Notice the taste in your mouth. You can take a gentle breath and pay attention to the sensation."
        )
    ]

    private var currentStep: GroundingStep {
        steps[currentStepIndex]
    }

    private var requiredCount: Int {
        currentStep.number
    }

    private var isCurrentStepComplete: Bool {
        selectedNumbers.count == requiredCount
    }

    // MARK: - Animation

    private let stepAnimation = Animation.easeInOut(duration: 0.25)

    // MARK: - Body

    var body: some View {
        ZStack {
            screenBg
                .ignoresSafeArea()

            if isCompleted {
                completionScreen
                    .transition(.opacity)
            } else {
                exerciseScreen
                    .transition(.opacity)
            }
        }
        .animation(
            .spring(response: 0.55, dampingFraction: 0.72),
            value: isCompleted
        )
        .onAppear {
            // Only start the stopwatch once
            if startDate == nil { startDate = Date() }
        }
    }

    // MARK: - Exercise Screen

    private var exerciseScreen: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            header
                .padding(.horizontal, 24)
                .padding(.top, 18)

            progressBars
                .padding(.horizontal, 24)
                .padding(.top, 24)

            // Keep the main sensory content in a fixed layout area.
            // This prevents the final step from shifting vertically.
            Spacer(minLength: 4)

            sensoryContent
                .padding(.horizontal, 24)
                .offset(y: -16)

            everydayAnchorsCard
                .padding(.horizontal, 24)
                .padding(.top, 1)

            numberButtons
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Spacer(minLength: 20)

            continueButton
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
        }
    }

    // MARK: - Sensory Content

    private var sensoryContent: some View {
        VStack(spacing: 12) {
            numberCircle

            // Reserve the same title height for every step.
            Text(currentStep.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 34)

            // Reserve a consistent instruction area even when text wraps.
            Text(currentStep.instruction)
                .font(.system(size: 16))
                .foregroundColor(subtextGray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .frame(height: 44, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .contentTransition(.opacity)
        .animation(stepAnimation, value: currentStepIndex)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                if currentStepIndex > 0 {
                    changeStep(to: currentStepIndex - 1)
                } else {
                    onExit()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(chipBg))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("STEP \(currentStepIndex + 1) OF \(steps.count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(cardGreen)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(
                    Capsule().fill(trackGreen.opacity(0.7))
                )
                .contentTransition(.numericText())
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Grounding Exercise")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)

            Text("5-4-3-2-1 SENSORY RESET")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundColor(subtextGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress Bars

    private var progressBars: some View {
        HStack(spacing: 6) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= currentStepIndex
                        ? cardGreen
                        : trackGreen
                    )
                    .frame(height: 5)
            }
        }
        .animation(stepAnimation, value: currentStepIndex)
    }

    // MARK: - Number Circle

    private var numberCircle: some View {
        ZStack {
            Circle()
                .fill(trackGreen.opacity(0.65))
                .frame(width: 140, height: 140)

            Circle()
                .fill(cardGreen)
                .frame(width: 100, height: 100)

            Text("\(currentStep.number)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(cream)
                .contentTransition(.numericText())
        }
        .frame(width: 160, height: 160)
        .animation(stepAnimation, value: currentStepIndex)
    }

    // MARK: - Everyday Anchors Card

    private var everydayAnchorsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "leaf")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(cardGreen)

                Text("Everyday anchors")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }

            Text(currentStep.examples)
                .font(.system(size: 14))
                .foregroundColor(subtextGray)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 54, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(trackGreen.opacity(0.7), lineWidth: 1)
        )
        .animation(stepAnimation, value: currentStepIndex)
    }

    // MARK: - Number Buttons

    private var numberButtons: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Choose each one as you notice it")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(subtextGray)
                .frame(height: 20)

            HStack(spacing: 10) {
                ForEach(1...requiredCount, id: \.self) { number in
                    Button {
                        toggleSelection(number)
                    } label: {
                        Text("\(number)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(
                                selectedNumbers.contains(number)
                                ? .white
                                : cardGreen
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        selectedNumbers.contains(number)
                                        ? cardGreen
                                        : .white
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedNumbers.contains(number)
                                        ? cardGreen
                                        : trackGreen,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 48)
        }
        .frame(maxWidth: .infinity)
        .animation(stepAnimation, value: currentStepIndex)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            advanceStep()
        } label: {
            Text(
                currentStepIndex == steps.count - 1
                ? "Finish"
                : "Continue"
            )
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        isCurrentStepComplete
                        ? cardGreen
                        : cardGreen.opacity(0.35)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isCurrentStepComplete)
        .animation(stepAnimation, value: isCurrentStepComplete)
    }

    // MARK: - Selection

    private func toggleSelection(_ number: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedNumbers.contains(number) {
                selectedNumbers.remove(number)
            } else {
                selectedNumbers.insert(number)
            }
        }
    }

    // MARK: - Completion Screen

    private var completionScreen: some View {
        VStack(spacing: 0) {
            topBarCompletion
                .padding(.horizontal, 20)
                .padding(.top, 8)

            header
                .padding(.horizontal, 24)
                .padding(.top, 18)

            Spacer(minLength: 16)

            // Match the breathing completion ring dimensions and colors.
            ZStack {
                Circle()
                    .stroke(trackGreen, lineWidth: 14)

                ZStack {
                    Circle()
                        .fill(trackGreen)
                        .frame(width: 200, height: 200)

                    Circle()
                        .fill(cardGreen)
                        .frame(width: 156, height: 156)

                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 86, weight: .regular))
                        .foregroundColor(cream)
                }
                .transition(
                    .scale(scale: 0.6).combined(with: .opacity)
                )
            }
            .frame(width: 270, height: 270)

            VStack(spacing: 8) {
                Text("Well done")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black)

                Text("You completed the 5-4-3-2-1 sensory reset")
                    .font(.system(size: 15))
                    .foregroundColor(subtextGray)
                    .multilineTextAlignment(.center)
                    .frame(height: 40, alignment: .top)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 36)

            Spacer(minLength: 16)

            Button {
                // The parent should dismiss grounding and reveal Relax home.
                onContinue()
            } label: {
                Text("Complete")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(cardGreen))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }

    private var topBarCompletion: some View {
        HStack {
            Button {
                onExit()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(chipBg))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("COMPLETE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(cardGreen)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(
                    Capsule().fill(trackGreen.opacity(0.7))
                )
        }
    }

    // MARK: - Navigation

    private func changeStep(to index: Int) {
        guard steps.indices.contains(index) else { return }

        withAnimation(stepAnimation) {
            currentStepIndex = index
            selectedNumbers.removeAll()
        }
    }

    private func advanceStep() {
        guard isCurrentStepComplete else { return }

        if currentStepIndex < steps.count - 1 {
            changeStep(to: currentStepIndex + 1)
        } else {
            logSession()
            withAnimation(
                .spring(response: 0.55, dampingFraction: 0.72)
            ) {
                isCompleted = true
            }
        }
    }

    // MARK: - Save to SwiftData

    /// Saves the elapsed time (start until finish) as one calm down record.
    private func logSession() {
        guard !isCompleted, let startDate else { return }   // never log twice
        let seconds = Date().timeIntervalSince(startDate)
        modelContext.logCalmDown("Grounding Exercise", seconds: seconds)
    }
}

#Preview {
    GroundingExerciseScreen()
        .modelContainer(for: CalmDownModel.self, inMemory: true)
}
