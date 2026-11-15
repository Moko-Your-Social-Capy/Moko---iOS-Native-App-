//
//  GroundingExerciseScreen.swift
//  Moko
//
//  Relax → Grounding. The 5-4-3-2-1 senses exercise:
//  5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.
//
//  Rules for the number buttons (good place to start debugging):
//  - Numbers must be picked in order: 1, then 2, then 3 …
//  - Only the last picked number can be tapped again to undo it.
//  - Continue stays disabled until every number in the step is picked.
//
//  When the user finishes, the time from opening the screen to finishing is
//  saved to SwiftData as a CalmDownModel. The Summary screen shows it.
//

import SwiftUI
import SwiftData

struct GroundingExerciseScreen: View {
    // Runs when the user taps "Complete" on the done screen.
    var onContinue: () -> Void = {}

    // Which of the 5 steps is showing (0 = "See", 4 = "Taste").
    @State private var currentStepIndex = 0
    // The numbers picked in the current step, e.g. [1, 2, 3].
    @State private var selectedNumbers: Set<Int> = []
    // True once the last step is finished. Swaps in the done screen.
    @State private var isCompleted = false
    // Stopwatch start. @State keeps the first value, so it is set once when the screen opens.
    @State private var startDate = Date()

    // The SwiftData database. Used to save the finished session.
    @Environment(\.modelContext) private var modelContext

    // MARK: - Colors

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let track = MokoScreenTheme.Colors.surfaceLavender
    private let ink = MokoScreenTheme.Colors.textTitle
    private let bodyText = MokoScreenTheme.Colors.textBody

    // MARK: - Steps

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

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    private var isCurrentStepComplete: Bool {
        selectedNumbers.count == currentStep.number
    }

    /// The only number that can be added right now: "how many are picked, plus one".
    private var nextNumber: Int {
        selectedNumbers.count + 1
    }

    private func isSelected(_ number: Int) -> Bool {
        selectedNumbers.contains(number)
    }

    /// Tappable = the next number in order, or the last picked one (to undo a mis-tap).
    private func isAvailable(_ number: Int) -> Bool {
        number == nextNumber || number == selectedNumbers.count
    }

    // Used for step changes. `withAnimation(stepAnimation)` animates everything that changes.
    private let stepAnimation = Animation.easeInOut(duration: 0.25)

    // MARK: - Body

    var body: some View {
        ZStack {
            MokoBackdrop()

            if isCompleted {
                completionScreen
                    .transition(.opacity)
            } else {
                exerciseScreen
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Immersive session: keep the tab bar out of the way.
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Exercise screen

    private var exerciseScreen: some View {
        ScrollView {
            VStack(spacing: 0) {
                pill("Step \(currentStepIndex + 1) of \(steps.count)")
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 8)

                header
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 18)

                progressBars
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 24)

                Spacer(minLength: 4)

                sensoryContent
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .offset(y: -16)

                everydayAnchorsCard
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 1)

                numberButtons
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 24)

                Spacer(minLength: 20)

                continueButton
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.bottom, 28)
            }
        }
        // Only bounce when the content is taller than the screen.
        .scrollBounceBehavior(.basedOnSize)
    }

    /// The small rounded label in the top-right corner ("Step 2 of 5", "Complete").
    private func pill(_ text: String) -> some View {
        HStack {
            Spacer()

            Text(text)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(accent)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(Capsule().fill(track.opacity(0.7)))
                // Digits roll up/down instead of snapping when the step changes.
                .contentTransition(.numericText())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Grounding Exercise")
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(ink)

            Text("5-4-3-2-1 sensory reset")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(bodyText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Five short bars. The ones up to the current step are filled.
    private var progressBars: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStepIndex ? accent : track)
                    .frame(height: 5)
            }
        }
    }

    /// Big number, the sense ("See") and the instruction.
    private var sensoryContent: some View {
        VStack(spacing: 12) {
            numberCircle

            // Minimum heights keep the layout from jumping between steps.
            Text(currentStep.title)
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 34)

            Text(currentStep.instruction)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        // Fade the text when it changes instead of snapping.
        .contentTransition(.opacity)
    }

    private var numberCircle: some View {
        ZStack {
            Circle()
                .fill(track.opacity(0.65))
                .frame(width: 140, height: 140)

            Circle()
                .fill(accent)
                .frame(width: 100, height: 100)

            Text("\(currentStep.number)")
                .mokoText(MokoScreenTheme.Typeface.numeral)
                .foregroundStyle(MokoScreenTheme.Colors.surfaceWhite)
                .contentTransition(.numericText())
        }
        .frame(width: 160, height: 160)
        .padding(.top, 15)
    }

    /// Card with example ideas for the current sense.
    private var everydayAnchorsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "leaf")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)

                Text("Everyday anchors")
                    .mokoText(MokoScreenTheme.Typeface.slider)
                    .foregroundStyle(ink)
            }

            Text(currentStep.examples)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MokoScreenTheme.Space.cardHorizontal)
        .mokoCard()
    }

    // MARK: - Number buttons

    private var numberButtons: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Choose each one as you notice it")
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(1...currentStep.number, id: \.self) { number in
                    numberButton(number)
                }
            }
            .frame(height: 48)
        }
        .frame(maxWidth: .infinity)
    }

    private func numberButton(_ number: Int) -> some View {
        let picked = isSelected(number)
        let shape = RoundedRectangle(cornerRadius: 14)

        return Button {
            selectNumber(number)
        } label: {
            Text("\(number)")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(picked ? .white : accent)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(shape.fill(picked ? accent : .white))
                .overlay(shape.stroke(picked ? accent : track, lineWidth: 1))
                // Numbers further ahead are dimmed so the next one stands out.
                // We do not use `.disabled`: SwiftUI would also dim the picked ones.
                // `selectNumber` ignores out-of-order taps anyway.
                .opacity(picked || isAvailable(number) ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var continueButton: some View {
        Button(action: advanceStep) {
            Text(isLastStep ? "Finish" : "Continue")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(isCurrentStepComplete ? accent : accent.opacity(0.35)))
        }
        .buttonStyle(.plain)
        .disabled(!isCurrentStepComplete)
        .animation(stepAnimation, value: isCurrentStepComplete)
    }

    // MARK: - Done screen

    private var completionScreen: some View {
        VStack(spacing: 0) {
            pill("Complete")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            header
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 18)

            Spacer(minLength: 16)

            MokoCompletionAnimation(ringDiameter: 190)
                .transition(.scale(scale: 0.6).combined(with: .opacity))

            VStack(spacing: 8) {
                Text("Well done")
                    .mokoText(MokoScreenTheme.Typeface.title2)
                    .foregroundStyle(ink)

                Text("You completed the 5-4-3-2-1 sensory reset")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(bodyText)
                    .multilineTextAlignment(.center)
                    .frame(height: 40, alignment: .top)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 36)

            Spacer(minLength: 16)

            // RelaxScreen pops this screen and shows the Relax tab again.
            Button(action: onContinue) {
                Text("Complete")
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

    // MARK: - Actions

    /// Adds the next number, removes the last picked one, and ignores anything else.
    private func selectNumber(_ number: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if number == nextNumber {
                selectedNumbers.insert(number)
            } else if number == selectedNumbers.count {
                selectedNumbers.remove(number)
            }
        }
    }

    /// Continue / Finish: go to the next step, or save and show the done screen.
    private func advanceStep() {
        guard isCurrentStepComplete else { return }

        if isLastStep {
            logSession()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                isCompleted = true
            }
        } else {
            withAnimation(stepAnimation) {
                currentStepIndex += 1
                selectedNumbers.removeAll()
            }
        }
    }

    /// Saves the time from opening the screen until finishing as one calm-down record.
    private func logSession() {
        guard !isCompleted else { return }   // never save twice
        let seconds = Date().timeIntervalSince(startDate)
        modelContext.logCalmDown("Grounding Exercise", seconds: seconds)
    }
}

#Preview {
    GroundingExerciseScreen()
        .modelContainer(for: CalmDownModel.self, inMemory: true)
}
