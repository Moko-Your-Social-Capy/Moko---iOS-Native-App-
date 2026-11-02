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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(BBColor.titleBrown)
                    .padding(.top, 20)

                Text("Breathe in for 4 seconds, hold for 4 seconds.\nBreathe out for 4 seconds, hold for 4 seconds.\nRepeat this cycle at your own pace.")
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BBColor.muted)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                // Cycle Counter with Plus and Minus Buttons
                HStack(spacing: 20) {
                    Button(action: { cycles = max(1, cycles - 1) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(cycles > 1 ? BBColor.button : .gray)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(red: 237/255, green: 237/255, blue: 237/255)))
                    }
                    .buttonStyle(.plain)
                    .disabled(cycles <= 1)

                    VStack(spacing: 2) {
                        Text("\(cycles)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(BBColor.title)
                        Text(cycles == 1 ? "CYCLE" : "CYCLES")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BBColor.subtitle)
                    }
                    .frame(minWidth: 70)

                    Button(action: { cycles = min(20, cycles + 1) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(cycles < 20 ? BBColor.button : .gray)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(red: 237/255, green: 237/255, blue: 237/255)))
                    }
                    .buttonStyle(.plain)
                    .disabled(cycles >= 20)
                }
                .padding(.top, 16)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(BBColor.button))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.top, 20)

                Button(action: onNotNow) {
                    Text("Not now")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(BBColor.button)
                        .padding(.horizontal, 24)
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
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    BoxBreathingInfoView(cycles: .constant(2))
}
