import SwiftUI

struct AgeEntryView: View {
    var progress: CGFloat = 0.903          // 352 / 390 in the design
    var initialAge: Int = 20
    var ageRange: ClosedRange<Int> = 13...100
    var onBack: () -> Void = {}
    var onContinue: (Int) -> Void = { _ in }

    @State private var selected: Int?

    private let rowHeight: CGFloat = 48.5
    private let wheelHeight: CGFloat = 291

    init(
        progress: CGFloat = 0.903,
        initialAge: Int = 20,
        ageRange: ClosedRange<Int> = 13...100,
        onBack: @escaping () -> Void = {},
        onContinue: @escaping (Int) -> Void = { _ in }
    ) {
        self.progress = progress
        self.initialAge = initialAge
        self.ageRange = ageRange
        self.onBack = onBack
        self.onContinue = onContinue
        _selected = State(initialValue: initialAge)
    }

    private var currentAge: Int { selected ?? initialAge }

    var body: some View {
        VStack(spacing: 0) {
            header

            Text("How old are you?")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 28)

            wheel
                .padding(.horizontal, 40)
                .padding(.top, 92)

            Spacer()

            continueButton
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
        .background(Color.white.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: Header (back button + progress bar)

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.track)
                    Capsule().fill(Color.forestLight)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Age wheel

    private var wheel: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardFill)

            // Highlight behind the selected number
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .frame(height: 58)
                .padding(.horizontal, 15)

            // Scrolling numbers
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(ageRange), id: \.self) { age in
                        AgeRow(age: age, distance: abs(age - currentAge))
                            .frame(height: rowHeight)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selected = age
                                }
                            }
                            .id(age)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selected, anchor: .center)
            .contentMargins(.vertical, (wheelHeight - rowHeight) / 2, for: .scrollContent)
            .animation(.easeOut(duration: 0.15), value: currentAge)
        }
        .frame(height: wheelHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Age")
        .accessibilityValue("\(currentAge)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: selected = min(currentAge + 1, ageRange.upperBound)
            case .decrement: selected = max(currentAge - 1, ageRange.lowerBound)
            @unknown default: break
            }
        }
    }

    // MARK: Continue button

    private var continueButton: some View {
        Button { onContinue(currentAge) } label: {
            HStack(spacing: 8) {
                Text("Continue")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.forest, in: Capsule())
        }
    }
}

// MARK: - One number in the wheel

private struct AgeRow: View {
    let age: Int
    let distance: Int       // how many rows away from the selected one

    var body: some View {
        Text("\(age)")
            .font(.system(size: distance == 0 ? 38 : 26,
                          weight: distance == 0 ? .bold : .semibold))
            .foregroundStyle(Color.ink)
            .opacity(opacity)
            .monospacedDigit()
    }

    private var opacity: Double {
        switch distance {
        case 0:  return 1
        case 1:  return 0.75
        default: return 0.45
        }
    }
}

#Preview {
    AgeEntryView(onContinue: { print("Age:", $0) })
}
