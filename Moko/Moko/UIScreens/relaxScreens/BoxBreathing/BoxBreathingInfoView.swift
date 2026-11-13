import SwiftUI

/// The "Box Breathing" intro card, shown inside a modal sheet.
struct BoxBreathingInfoView: View {
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
                    .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                    .accessibilityHidden(true)

                Text("Box Breathing")
                    .mocoText(MocoScreenTheme.Typeface.title2)
                    .foregroundStyle(BBColor.titleBrown)
                    .padding(.top, 20)

                Text("Breathe in for 4 seconds, hold for 4 seconds.\nBreathe out for 4 seconds, hold for 4 seconds.\nRepeat this cycle at your own pace.")
                    .mocoText(MocoScreenTheme.Typeface.body)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BBColor.muted)
                    .padding(.horizontal, MocoScreenTheme.Space.page)
                    .padding(.top, 10)

                // Cycle Counter with Plus and Minus Buttons
                HStack(spacing: 20) {
                    Button(action: { cycles = max(1, cycles - 1) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(cycles > 1 ? BBColor.button : .gray)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(MocoScreenTheme.Colors.surfaceLavender))
                    }
                    .buttonStyle(.plain)
                    .disabled(cycles <= 1)
                    .accessibilityLabel("Decrease cycles")

                    VStack(spacing: 2) {
                        Text("\(cycles)")
                            .mocoText(MocoScreenTheme.Typeface.title2)
                            .foregroundStyle(BBColor.title)
                        Text(cycles == 1 ? "Cycle" : "Cycles")
                            .mocoText(MocoScreenTheme.Typeface.caption)
                            .foregroundStyle(BBColor.subtitle)
                    }
                    .frame(minWidth: 70)

                    Button(action: { cycles = min(20, cycles + 1) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(cycles < 20 ? BBColor.button : .gray)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(MocoScreenTheme.Colors.surfaceLavender))
                    }
                    .buttonStyle(.plain)
                    .disabled(cycles >= 20)
                    .accessibilityLabel("Increase cycles")
                }
                .padding(.top, 16)

                Button(action: onContinue) {
                    Text("Continue")
                        .mocoText(MocoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(BBColor.button))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.top, 20)

                Button(action: onNotNow) {
                    Text("Not now")
                        .mocoText(MocoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(BBColor.button)
                        .padding(.horizontal, MocoScreenTheme.Space.page)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { MocoBackdrop() }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    BoxBreathingInfoView(cycles: .constant(2))
}
