import SwiftUI
import Lottie

struct MokoLottieView: UIViewRepresentable {

    let animationType: MokoAnimationType
    let size: CGFloat?

    init(
        animationType: MokoAnimationType = .hello,
        size: CGFloat? = 280
    ) {
        self.animationType = animationType
        self.size = size
    }

    func makeUIView(context: Context) -> LottieAnimationView {

        let name = animationType.lottieName

        let paths: [String?] = [
            "Resources/Animations",
            "Animations",
            nil
        ]

        for path in paths {

            if let animation = LottieAnimation.named(
                name,
                bundle: .main,
                subdirectory: path
            ) {

                print("MOKO SUCCESS: Loaded \(name)")
                print("MOKO PATH: \(path ?? "Bundle Root")")

                let view = LottieAnimationView(animation: animation)

                view.contentMode = size == nil
                    ? .scaleAspectFill
                    : .scaleAspectFit

                view.loopMode = animationType.loopMode
                view.backgroundBehavior = .pauseAndRestore
                view.backgroundColor = .clear
                view.clipsToBounds = true

                view.play()

                return view
            }
        }

        print("MOKO ERROR: Could not find animation: \(name)")

        return LottieAnimationView()
    }

    func updateUIView(
        _ uiView: LottieAnimationView,
        context: Context
    ) {
        // SwiftUI controls the actual view dimensions.
    }
}
