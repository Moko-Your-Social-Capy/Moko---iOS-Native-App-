import SwiftUI
import RiveRuntime
import UIKit

/// Plays the earned badge scene and configures its Rive view model.
struct BadgeUnlockRiveView: View {
    let achievement: Achievement

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didSettle = false
    @State private var tiltDegrees = 0.0
    @State private var modelInstance: ViewModelInstance?

    private var tierColor: RiveRuntime.Color {
        switch achievement.tier {
        case .one: RiveRuntime.Color(red: 61, green: 148, blue: 168)
        case .two: RiveRuntime.Color(red: 166, green: 177, blue: 183)
        case .three: RiveRuntime.Color(red: 217, green: 164, blue: 65)
        }
    }

    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(source: .local("BadgeUnlock", Bundle.main), worker: worker)
            let model = try await file.createViewModelInstance(.viewModelDefault(from: .name("BadgeUnlock")))
            let glyphFormat = UIGraphicsImageRendererFormat()
            glyphFormat.scale = 1
            let glyphData = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: glyphFormat).pngData { _ in
                let config = UIImage.SymbolConfiguration(pointSize: 58, weight: .regular)
                UIImage(systemName: achievement.symbol, withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                    .draw(in: CGRect(x: 32, y: 32, width: 64, height: 64))
            }
            let glyph = try await worker.decodeImage(from: glyphData)
            model.setValue(of: ImageProperty(path: "badgeFace"), to: glyph)
            model.setValue(of: BoolProperty(path: "locked"), to: !achievement.unlocked)
            model.setValue(of: BoolProperty(path: "reduceMotion"), to: reduceMotion)
            model.setValue(of: NumberProperty(path: "tier"), to: Float(achievement.tier.rawValue))
            model.setValue(of: ColorProperty(path: "tierColor"), to: tierColor)
            model.setValue(of: StringProperty(path: "badgeName"), to: achievement.title)
            model.setValue(of: NumberProperty(path: "angle"), to: 0)
            let artboard = try await file.createArtboard("BadgeUnlock")
            let machine = try await artboard.createStateMachine("BadgeUnlock", binding: model)
            modelInstance = model
            return try await Rive(file: file, artboard: artboard, stateMachine: machine)
        }
        .frame(width: 244, height: 244)
        .accessibilityLabel("\(achievement.title), \(achievement.unlocked ? "badge earned" : "badge locked")")
        .sensoryFeedback(.success, trigger: didSettle)
        .onChange(of: tiltDegrees) { _, value in
            modelInstance?.setValue(of: NumberProperty(path: "angle"), to: Float(value))
        }
        .gesture(DragGesture(minimumDistance: 8)
            .onChanged { gesture in
                guard didSettle else { return }
                tiltDegrees = min(25, max(-25, gesture.translation.width / 4))
            }
            .onEnded { _ in springTiltBack() }
        )
        .task {
            guard achievement.unlocked else { return }
            while modelInstance == nil && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(20))
            }
            guard !Task.isCancelled, let modelInstance else { return }
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            modelInstance.fire(trigger: TriggerProperty(path: "unlock"))
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 400 : 1_300))
            guard !Task.isCancelled else { return }
            didSettle = true
        }
    }

    private func springTiltBack() {
        let startingAngle = tiltDegrees
        Task { @MainActor in
            for step in 1...24 {
                let progress = Double(step) / 24
                tiltDegrees = startingAngle * exp(-5.5 * progress) * cos(9 * progress)
                try? await Task.sleep(for: .milliseconds(16))
            }
            tiltDegrees = 0
        }
    }
}
