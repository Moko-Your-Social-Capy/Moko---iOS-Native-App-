import SwiftUI

/// Native loading indicator; larger placements include the Moco mascot.
struct MokoFlossLoadingView: View {
    var size: CGFloat = 112

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            if size >= 60 {
                Image("MocoMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: size * 0.7)
            }
            if reduceMotion {
                Image(systemName: "hourglass")
            } else {
                ProgressView()
                    .tint(MocoScreenTheme.Colors.dataVioletDeep)
            }
        }
        .foregroundStyle(MocoScreenTheme.Colors.dataVioletDeep)
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}
