import SwiftUI

/// The "Box Breathing" intro card, shown inside a modal sheet.
struct BoxBreathingInfoView: View {
    var onContinue: () -> Void = {}
    var onNotNow: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // Illustration: fills a 321pt-tall rounded area at the top of the sheet
            Color.clear
                .frame(height: 321)
                .frame(maxWidth: .infinity)
                .overlay(
                    Image("box_breathing_intro")
                        .resizable()
                        .scaledToFill()
                )
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .ignoresSafeArea(edges: .top)
                .accessibilityHidden(true)

            Text("Box Breathing")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 88)

            Text("Breathe in for 4 seconds, hold for 4 seconds.\nBreathe out for 4 seconds, hold for 4 seconds.\nRepeat this cycle for 2–3 minutes, breathing\ncomfortably at your own pace.")
                .font(.system(size: 16))
                .lineSpacing(3.3)
                .multilineTextAlignment(.center)
                .foregroundStyle(BBColor.muted)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 24)
                .padding(.top, 22)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 61)
                    .background(Capsule().fill(BBColor.button))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.top, 35)

            Button(action: onNotNow) {
                Text("Not now")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(BBColor.button)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 23)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}

#Preview {
    BoxBreathingInfoView()
}
