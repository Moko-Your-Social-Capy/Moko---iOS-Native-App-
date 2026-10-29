
import SwiftUI

struct GroundingExerciseScreen: View {
    var onExit: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var selectedNumbers: Set<Int> = []

    private let accent = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let primaryText = Color(red: 47/255, green: 42/255, blue: 40/255)
    private let secondaryText = Color(red: 111/255, green: 103/255, blue: 98/255)
    private let screenBg = Color(red: 244/255, green: 244/255, blue: 249/255)

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: onExit) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle().fill(Color(red: 237/255, green: 237/255, blue: 237/255))
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

                    Text("See")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(primaryText)
                        .padding(.top, 12)

                    Text("Notice five things you can clearly see around you right now.")
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

                        Text("\(selectedNumbers.count) of 5")
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
            if selectedNumbers.count == 5 {
                Button(action: onContinue) {
                    Text("Continue")
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
            ForEach(1...5, id: \.self) { number in
                Capsule()
                    .fill(
                        selectedNumbers.contains(number)
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
        .accessibilityValue("\(selectedNumbers.count) of 5 completed")
    }

    private var numberCircle: some View {
        ZStack {
            Circle()
                .fill(Color(red: 225/255, green: 238/255, blue: 229/255))
                .frame(width: 150, height: 150)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 114, height: 114)

            Text("5")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(accent)

            Image(systemName: "eye")
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
            Label("Everyday Anchors", systemImage: "lightbulb.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(accent)

            Text("Look for subtle contours: morning light across a wall, texture on a notebook, or a leafy plant.")
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
            ForEach(1...5, id: \.self) { number in
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
}

#Preview {
    GroundingExerciseScreen()
}
