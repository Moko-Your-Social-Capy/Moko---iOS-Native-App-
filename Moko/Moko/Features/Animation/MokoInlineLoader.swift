import SwiftUI
import Lottie

/// Small inline loading indicator using the supplied `loading.json` Lottie animation.
/// Use for localized async operations (cards, sheets, fields) — not for full screens.
struct MokoInlineLoader: View {
    // Size of the loader; adapts to different component contexts.
    var size: CGFloat = 44
    // Optional tint override; when nil uses the active theme's primary/accent.
    var tint: Color? = nil

    @Environment(\.mokoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                ProgressView()
                    .tint(tint ?? theme.colors.primary)
                    .scaleEffect(max(0.6, size / 44))
            } else if let animation = MokoAnimationManager.shared.inlineLoader ?? MokoAnimationAssets.inlineLoaderAnimation {
                LottieView(animation: animation)
                    .configure { view in
                        view.loopMode = .loop
                        view.backgroundBehavior = .pauseAndRestore
                        view.shouldRasterizeWhenIdle = true
                    }
                    .play()
                    .colorMultiply(tint ?? theme.colors.primary)
            } else {
                ProgressView()
                    .tint(tint ?? theme.colors.primary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Loading")
    }
}
