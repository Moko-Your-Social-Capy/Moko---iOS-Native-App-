import SwiftUI
import Lottie

/// A Lottie animation centered inside a fixed square viewport.
struct MokoLottieView: View {
    let animationType: MokoAnimationType
    let size: CGFloat?

    init(
        animationType: MokoAnimationType = .hello,
        size: CGFloat? = 200
    ) {
        self.animationType = animationType
        self.size = size
    }

    var body: some View {
        MokoLottieRepresentable(animationType: animationType)
            .frame(width: size ?? 200, height: size ?? 200)
            .clipped()
            .accessibilityLabel("Moko animation")
    }
}

private struct MokoLottieRepresentable: UIViewRepresentable {
    let animationType: MokoAnimationType

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true

        let name = animationType.lottieName
        let paths: [String?] = [
            "Resources/Animations",
            "Animations",
            nil
        ]

        for path in paths {
            guard let animation = LottieAnimation.named(
                name,
                bundle: .main,
                subdirectory: path
            ) else {
                continue
            }

            print("MOKO SUCCESS: Loaded \(name)")
            print("MOKO PATH: \(path ?? "Bundle Root")")

            let animationView = LottieAnimationView(
                animation: animation,
                configuration: LottieConfiguration(renderingEngine: .mainThread)
            )
            animationView.translatesAutoresizingMaskIntoConstraints = false
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = animationType.loopMode
            animationView.backgroundBehavior = .pauseAndRestore
            animationView.backgroundColor = .clear
            animationView.clipsToBounds = true

            container.addSubview(animationView)
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: container.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            animationView.play()
            return container
        }

        print("MOKO ERROR: Could not find animation: \(name)")
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // The representable stays constrained to the fixed SwiftUI viewport.
    }
}
