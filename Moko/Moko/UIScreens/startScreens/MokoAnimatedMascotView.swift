import SwiftUI
import RiveRuntime

/// Rive-powered Moko mascot: holds a friendly hello pose, then hops every two seconds.
struct MokoAnimatedMascotView: View {
    var size: CGFloat = 220

    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(
                source: .local("MokoWelcomeRive", Bundle.main),
                worker: worker
            )
            return try await Rive(file: file)
        }
        .frame(width: size, height: size * (560.0 / 512.0))
        .accessibilityLabel("Moko greets you, then jumps and lands every two seconds.")
    }
}

#Preview {
    ZStack {
        MokoTheme.background.ignoresSafeArea()
        MokoAnimatedMascotView(size: 220)
    }
}
