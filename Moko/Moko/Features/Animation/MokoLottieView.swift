
import SwiftUI
import Lottie

struct MokoLottieView: UIViewRepresentable {

    let animationType: MokoAnimationType
    let size: CGFloat

    init(
        animationType: MokoAnimationType = .hello,
        size: CGFloat = 280
    ) {
        self.animationType = animationType
        self.size = size
    }

    
    func makeUIView(context: Context) -> LottieAnimationView {

        let animation = LottieAnimation.named(
            animationType.lottieName,
            bundle: .main,
            subdirectory: "Resources/Animations"
        )

        let animationView = LottieAnimationView(
            animation: animation
        )

        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = animationType.loopMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.backgroundColor = .clear

        if animation != nil {
            animationView.play()
            print("MOKO: Animation loaded: \(animationType.lottieName)")
        } else {
            print("MOKO ERROR: Animation not found: \(animationType.lottieName)")
        }

        return animationView
    }

    func updateUIView(
        _ uiView: LottieAnimationView,
        context: Context
    ) {
        // Playback updates can be added here.
    }
}
