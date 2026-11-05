import SwiftUI
import RiveRuntime

/// Reusable vector Moko mascot. Increment wavePulse or celebratePulse to play a one-shot.
struct MokoMascotRiveView: View {
    var size: CGFloat = 220
    var wavePulse: Int = 0
    var celebratePulse: Int = 0
    var mood: Double = 1 // 0 = calm, 1 = content, 2 = joyful
    var calm = false

    @State private var model: ViewModelInstance?

    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(source: .local("MokoMascotRive", Bundle.main), worker: worker)
            let viewModel = try await file.createViewModelInstance(.viewModelDefault(from: .name("Moko Mascot")))
            viewModel.setValue(of: NumberProperty(path: "mood"), to: Float(min(2, max(0, mood))))
            viewModel.setValue(of: BoolProperty(path: "calm"), to: calm)
            let artboard = try await file.createArtboard("Moko Mascot")
            let machine = try await artboard.createStateMachine("Moko Mascot", binding: viewModel)
            model = viewModel
            return try await Rive(file: file, artboard: artboard, stateMachine: machine, fit: .contain(alignment: .center))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Moko the capybara")
        .onChange(of: wavePulse) { _, _ in model?.fire(trigger: TriggerProperty(path: "wave")) }
        .onChange(of: celebratePulse) { _, _ in model?.fire(trigger: TriggerProperty(path: "celebrate")) }
        .onChange(of: mood) { _, value in
            model?.setValue(of: NumberProperty(path: "mood"), to: Float(min(2, max(0, value))))
        }
        .onChange(of: calm) { _, value in model?.setValue(of: BoolProperty(path: "calm"), to: value) }
    }
}

#Preview {
    MokoMascotRiveView(size: 300, mood: 1, calm: true)
}
