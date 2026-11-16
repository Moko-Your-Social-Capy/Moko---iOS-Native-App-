//
//  AgeEntryView.swift
//  Moko
//
//  Intro step 3: the user picks their age on a snapping scroll wheel.
//
//  How the wheel works: a vertical ScrollView of numbers that snaps one row
//  at a time (`.viewAligned`). `.scrollPosition(id:)` keeps `selected` in sync
//  with whichever row sits in the middle, and tapping a row scrolls to it.
//

import SwiftUI

struct AgeEntryView: View {
    /// How full the top progress bar is (0...1).
    var progress: CGFloat = 0.903
    var initialAge: Int = 20
    var ageRange: ClosedRange<Int> = 13...100
    /// Called with the chosen age when the user taps Continue.
    var onContinue: (Int) -> Void = { _ in }

    /// The row currently centered in the wheel. Optional because
    /// `.scrollPosition(id:)` sets it to nil mid-scroll.
    @State private var selected: Int?

    private let rowHeight: CGFloat = 48.5
    private let wheelHeight: CGFloat = 291

    init(
        progress: CGFloat = 0.903,
        initialAge: Int = 20,
        ageRange: ClosedRange<Int> = 13...100,
        onContinue: @escaping (Int) -> Void = { _ in }
    ) {
        self.progress = progress
        self.initialAge = initialAge
        self.ageRange = ageRange
        self.onContinue = onContinue
        // Start the wheel on the saved age instead of the top of the list.
        _selected = State(initialValue: initialAge)
    }

    /// The selected age, falling back to the starting age while scrolling.
    private var currentAge: Int { selected ?? initialAge }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(progress: progress)
                .padding(.horizontal, 20)

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

            OnboardingContinueButton { onContinue(currentAge) }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
        .background(MokoBackdrop())
        // A small haptic "tick" every time the selected age changes.
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: Age wheel

    private var wheel: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardFill)

            // White highlight behind the selected (middle) number
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
                            // The id `.scrollPosition` uses to find this row.
                            .id(age)
                    }
                }
                // Marks the rows as snap targets for `.viewAligned` below.
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selected, anchor: .center)
            // Empty space above/below so the first and last ages can reach the middle.
            .contentMargins(.vertical, (wheelHeight - rowHeight) / 2, for: .scrollContent)
            .animation(.easeOut(duration: 0.15), value: currentAge)
        }
        .frame(height: wheelHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        // VoiceOver: treat the wheel as one control the user swipes up/down to adjust.
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
}

// MARK: - One number in the wheel

/// A single age. It gets bigger and darker the closer it is to the middle row.
private struct AgeRow: View {
    let age: Int
    /// How many rows away from the selected one (0 = selected).
    let distance: Int

    var body: some View {
        Text("\(age)")
            .font(.system(size: distance == 0 ? 38 : 26,
                          weight: distance == 0 ? .bold : .semibold))
            .foregroundStyle(Color.ink)
            .opacity(opacity)
            .monospacedDigit()                           // stops digits jiggling while scrolling
    }

    private var opacity: Double {
        switch distance {
        case 0:  1
        case 1:  0.75
        default: 0.45
        }
    }
}

#Preview {
    AgeEntryView(onContinue: { _ in })
}
