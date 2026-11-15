//
//  BoxBreathingInfoView.swift
//  Moko
//
//  The intro sheet before Box Breathing: explains the exercise and lets the
//  user pick how many cycles (1–20) to do.
//

import SwiftUI

/// The "Box Breathing" intro card, shown inside a modal sheet.
struct BoxBreathingInfoView: View {
    // @Binding: the number lives in the parent screen. Changing it here changes it there.
    @Binding var cycles: Int
    var onContinue: () -> Void = {}
    var onNotNow: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Illustration: matches the banner height used by the other session sheets
                Color.clear
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Image("box_breathing_intro")
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
                    .accessibilityHidden(true)

                Text("Box Breathing")
                    .mokoText(MokoScreenTheme.Typeface.title2)
                    .foregroundStyle(BBColor.titleBrown)
                    .padding(.top, 20)

                Text("Breathe in for 4 seconds, hold for 4 seconds.\nBreathe out for 4 seconds, hold for 4 seconds.\nRepeat this cycle at your own pace.")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BBColor.muted)
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 10)

                // Cycle counter: minus and plus keep the number between 1 and 20.
                HStack(spacing: 20) {
                    Button(action: { cycles = max(1, cycles - 1) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(cycles > 1 ? BBColor.button : .gray)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(MokoScreenTheme.Colors.surfaceLavender))
                    }
                    .buttonStyle(.plain)
                    .disabled(cycles <= 1)
                    .accessibilityLabel("Decrease cycles")

                    VStack(spacing: 2) {
                        Text("\(cycles)")
                            .mokoText(MokoScreenTheme.Typeface.title2)
                            .foregroundStyle(BBColor.title)
                        Text(cycles == 1 ? "Cycle" : "Cycles")
                            .mokoText(MokoScreenTheme.Typeface.caption)
                            .foregroundStyle(BBColor.subtitle)
                    }
                    .frame(minWidth: 70)

                    Button(action: { cycles = min(20, cycles + 1) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(cycles < 20 ? BBColor.button : .gray)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(MokoScreenTheme.Colors.surfaceLavender))
                    }
                    .buttonStyle(.plain)
                    .disabled(cycles >= 20)
                    .accessibilityLabel("Increase cycles")
                }
                .padding(.top, 16)

                Button(action: onContinue) {
                    Text("Continue")
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(BBColor.button))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 20)

                Button(action: onNotNow) {
                    Text("Not now")
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(BBColor.button)
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
        }
        // Only bounce when the content is taller than the sheet.
        .scrollBounceBehavior(.basedOnSize)
        .background { MokoBackdrop() }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    BoxBreathingInfoView(cycles: .constant(2))
}
