import SwiftUI

struct MokoAnimatedMascotView: View {
    /// How wide and tall Moko is. Both pictures are square.
    var size: CGFloat = 220

    // The phone setting "Reduce Motion". If it is on, the arm stays still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // False at the start, true once Moko has shown up.
    @State private var appeared = false

    // The shoulder point, as a fraction of the picture.
    // (0, 0) is the top-left corner and (1, 1) is the bottom-right corner.
    private let shoulder = UnitPoint(x: 0.347, y: 0.518)

    var body: some View {
        ZStack {
            // The body is drawn first, so the arm sits on top of it.
            Image("MokoBody")
                .resizable()
                .scaledToFit()

            // PhaseAnimator plays these arm angles once each time its trigger changes.
            // 0 is the raised pose from the picture. Positive angles lift the paw higher.
            PhaseAnimator([0.0, 14.0, 2.0, 14.0, 0.0], trigger: appeared) { angle in
                Image("MokoArm")
                    .resizable()
                    .scaledToFit()
                    // Turn the arm around the shoulder. Rotating keeps its shape, so it never stretches.
                    .rotationEffect(.degrees(reduceMotion ? 0 : angle), anchor: shoulder)
            } animation: { _ in
                // Each swing eases in and out, so the wave feels soft.
                .easeInOut(duration: 0.35)
            }
        }
        .frame(width: size, height: size)
        // Starts a little small and a little low, then grows into place.
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : size * 0.12)
        // VoiceOver reads this instead of the pictures.
        .accessibilityLabel("Moko waves hello")
        // .onAppear runs when Moko first shows on screen. It starts the entrance and the wave.
        .onAppear {
            // withAnimation plays the change smoothly. Reduce Motion gets a plain fade.
            withAnimation(reduceMotion ? MokoScreenTheme.Motion.crossfade : MokoScreenTheme.Motion.mascotEntrance) {
                appeared = true
            }
        }
    }
}

#Preview {
    MokoAnimatedMascotView()
}