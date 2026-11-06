import SwiftUI

/// Optional, momentary self-rating used only to adjust the size of a suggested quest step.
/// It is not a screening tool or diagnosis; its locally stored value expires after 24 hours.
struct MokoSUDSCheckInView: View {
    let onContinue: (Int?) -> Void

    @State private var score = 3.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedScore: Int { Int(score.rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 28)

            Text("A check-in for today")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(MokoTheme.titleBrown)

            Text("How uncomfortable does the thought of a social step feel right now?")
                .font(.system(size: 17))
                .foregroundStyle(MokoTheme.titleBrown.opacity(0.78))
                .lineSpacing(4)
                .padding(.top, 14)

            Text("This is an optional 0–10 self-rating, not a test or diagnosis. You can skip it.")
                .font(.system(size: 14))
                .foregroundStyle(MokoTheme.titleBrown.opacity(0.68))
                .lineSpacing(3)
                .padding(.top, 10)

            VStack(spacing: 16) {
                Text("\(selectedScore)")
                    .font(.system(size: 52, weight: .medium, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(MokoTheme.forestGreen)
                    .accessibilityLabel("\(selectedScore) out of 10")

                Slider(value: $score, in: 0...10, step: 1)
                    .tint(MokoTheme.forestGreen)
                    .accessibilityLabel("Current discomfort rating")
                    .accessibilityValue("\(selectedScore) out of 10")

                HStack(alignment: .top) {
                    Text("0 · At ease")
                    Spacer(minLength: 12)
                    Text("10 · Most uncomfortable right now")
                        .multilineTextAlignment(.trailing)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MokoTheme.titleBrown.opacity(0.7))
            }
            .padding(22)
            .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.top, 32)

            Spacer(minLength: 24)

            Button {
                onContinue(selectedScore)
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(MokoTheme.forestGreen, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Uses this check-in to tailor quest suggestions on this device for up to 24 hours")

            Button("Skip") {
                onContinue(nil)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(MokoTheme.forestGreen)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
            .padding(.top, 8)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MokoTheme.limeBackground.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: selectedScore)
    }
}
