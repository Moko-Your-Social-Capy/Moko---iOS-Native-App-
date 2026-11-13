import SwiftUI

/// The supplied mascot, revealed once without a continuously running animation.
struct MokoAnimatedMascotView: View {
    var size: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        Image("MocoMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * (758.0 / 592.0))
            .offset(y: appeared || reduceMotion ? 0 : size * 0.12)
            .opacity(appeared ? 1 : 0)
            .accessibilityLabel("Moco waves hello")
            .onAppear {
                withAnimation(reduceMotion ? MocoScreenTheme.Motion.crossfade : MocoScreenTheme.Motion.mascotEntrance) {
                    appeared = true
                }
            }
    }
}
