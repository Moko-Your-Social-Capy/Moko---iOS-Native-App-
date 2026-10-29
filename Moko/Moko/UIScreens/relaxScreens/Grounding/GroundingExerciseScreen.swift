import SwiftUI

struct GroundingExerciseScreen: View {

    var onExit: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var currentStep = 0
    @State private var selectedNumbers: Set<Int> = []

    private let accent = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let primaryText = Color(red: 47/255, green: 42/255, blue: 40/255)
    private let secondaryText = Color(red: 111/255, green: 103/255, blue: 98/255)
    private let screenBg = Color(red: 244/255, green: 244/255, blue: 249/255)

    private let steps: [GroundingStep] = [
        GroundingStep(
            number: 5,
            title: "See",
            subtitle: "Notice five things you can clearly see around you right now.",
            cardTitle: "Everyday Anchors",
            cardDescription: "Look for subtle contours: morning light across a wall, texture on a notebook, or a leafy plant.",
            icon: "eye"
        ),
        GroundingStep(
            number: 4,
            title: "Touch",
            subtitle: "Notice four things you can feel around you right now.",
            cardTitle: "Notice the Details",
            cardDescription: "Feel your feet on the floor, the fabric of your clothes, the chair beneath you, or the texture of an object.",
            icon: "hand.point.up.left"
        ),
        GroundingStep(
            number: 3,
            title: "Hear",
            subtitle: "Notice three things you can hear around you right now.",
            cardTitle: "Listen Closely",
            cardDescription: "Listen for nearby sounds, distant voices, birds, a fan, or the gentle hum of your surroundings.",
            icon: "ear"
        ),
        GroundingStep(
            number: 2,
            title: "Smell",
            subtitle: "Notice two things you can smell around you right now.",
            cardTitle: "Breathe In",
            cardDescription: "Notice the scent of the air, your surroundings, or a familiar object nearby. If you can't detect a scent, simply notice the air as you breathe.",
            icon: "wind"
        ),
        GroundingStep(
            number: 1,
            title: "Taste",
            subtitle: "Notice one thing you can taste, or focus on one slow, steady breath.",
            cardTitle: "Return to the Present",
            cardDescription: "Take a gentle breath. Notice how your body feels in this moment, without needing to change anything.",
            icon: "heart"
        )
    ]

    private var step: GroundingStep {
        steps[currentStep]
    }

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    HStack {
                        Button(action: {
                            if currentStep > 0 {
                                currentStep -= 1
                                selectedNumbers = []
                            } else {
                                onExit()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle().fill(
                                        Color(red: 237/255, green: 237/255, blue: 237/255)
                                    )
                                )
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    progressBar
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    numberCircle
                        .padding(.top, 20)

                    Text(step.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(primaryText)
                        .padding(.top, 12)

                    Text(step.subtitle)
                        .font(.system(size: 16))
                        .foregroundStyle(secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)

                    everydayAnchorsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    HStack {
                        Text("Tap each as you spot it")
                            .foregroundStyle(primaryText)

                        Spacer()

                        Text("\(selectedNumbers.count) of \(step.number)")
                            .fontWeight(.semibold)
                            .foregroundStyle(accent)
                    }
                    .font(.system(size: 14))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    numberButtons
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selectedNumbers.count == step.number {
                Button(action: advanceStep) {
                    Text(currentStep == steps.count - 1 ? "Finish" : "Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(accent)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .offset(y: -25)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedNumbers.count)
        .animation(.easeInOut(duration: 0.25), value: currentStep)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Grounding Exercise")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(primaryText)

            Text("5-4-3-2-1 SENSORY RESET")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressBar: some View {
        HStack(spacing: 7) {
            ForEach(0..<step.number, id: \.self) { number in
                Capsule()
                    .fill(
                        selectedNumbers.contains(number + 1)
                            ? accent
                            : Color.gray.opacity(0.16)
                    )
                    .frame(height: 5)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedNumbers)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(selectedNumbers.count) of \(step.number) completed")
    }

    private var numberCircle: some View {
        ZStack {
            Circle()
                .fill(Color(red: 225/255, green: 238/255, blue: 229/255))
                .frame(width: 150, height: 150)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 114, height: 114)

            Text("\(step.number)")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(accent)

            Image(systemName: step.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)
                .background(.white, in: Circle())
                .offset(x: 31, y: 31)
        }
        .frame(maxWidth: .infinity)
    }

    private var everydayAnchorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(step.cardTitle, systemImage: "lightbulb.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(accent)

            Text(step.cardDescription)
                .font(.system(size: 15))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.035), radius: 10, x: 0, y: 3)
    }

    private var numberButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...step.number, id: \.self) { number in
                let isSelected = selectedNumbers.contains(number)

                Button {
                    toggleNumber(number)
                } label: {
                    Text("\(number)")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            isSelected ? accent : Color.white,
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Number \(number)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func toggleNumber(_ number: Int) {
        if selectedNumbers.contains(number) {
            selectedNumbers.remove(number)
        } else {
            selectedNumbers.insert(number)
        }
    }

    private func advanceStep() {
        if currentStep < steps.count - 1 {
            selectedNumbers = []
            currentStep += 1
        } else {
            onContinue()
        }
    }
}

private struct GroundingStep {
    let number: Int
    let title: String
    let subtitle: String
    let cardTitle: String
    let cardDescription: String
    let icon: String
}

#Preview {
    GroundingExerciseScreen()
}
