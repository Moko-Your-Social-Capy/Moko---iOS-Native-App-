import SwiftUI
import RiveRuntime

/// Rive-powered Moko mascot: holds a friendly hello pose, then hops every two seconds.
struct MokoAnimatedMascotView: View {
    var size: CGFloat = 220
    var wavePulse: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ViewModelInstance?

    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(
                source: .local("MokoWelcomeRive", Bundle.main),
                worker: worker
            )
            let model = try await file.createViewModelInstance(.viewModelDefault(from: .name("Moko Welcome")))
            model.setValue(of: BoolProperty(path: "idle"), to: true)
            let artboard = try await file.createArtboard("Moko Welcome")
            let machine = try await artboard.createStateMachine("Moko Welcome", binding: model)
            viewModel = model
            if !reduceMotion {
                model.fire(trigger: TriggerProperty(path: "start"))
            }
            return try await Rive(file: file, artboard: artboard, stateMachine: machine, fit: .contain(alignment: .center))
        }
        .frame(width: size, height: size * (560.0 / 512.0))
        .accessibilityLabel("Moko greets you with a jump, waves, then rests.")
        .onChange(of: wavePulse) { _, _ in
            guard !reduceMotion else { return }
            viewModel?.fire(trigger: TriggerProperty(path: "wave"))
        }
    }
}

#Preview {
    ZStack {
        MokoTheme.background.ignoresSafeArea()
        MokoAnimatedMascotView(size: 220)
    }
}
