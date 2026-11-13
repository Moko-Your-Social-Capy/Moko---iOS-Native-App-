import SwiftUI

struct SplashScreenView: View {
    var autoAdvance = true
    var onFinished: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @State private var didFinish = false

    var body: some View {
        Button(action: finish) {
            GeometryReader { geometry in
                let size = geometry.size
                let landscape = size.width > size.height
                let mascotWidth = min(size.width * (landscape ? 0.47 : 1.06),
                                      size.height * (landscape ? 0.72 : 0.62))
                let mascotHeight = mascotWidth * (758.0 / 592.0)

                ZStack {
                    MocoScreenTheme.Colors.tileLilac

                    VStack(spacing: MocoScreenTheme.Space.s4) {
                      
                        Text("Moko")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .tracking(-3)
                            .foregroundStyle(MocoScreenTheme.Colors.dataVioletDeep)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .position(x: size.width * (landscape ? 0.27 : 0.5),
                              y: size.height * (landscape ? 0.44 : 0.30))

                    Image("MocoMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: mascotWidth, height: mascotHeight)
                        .position(x: size.width * (landscape ? 0.74 : 0.5),
                                  y: size.height - mascotHeight * 0.28)
                        .offset(y: hasAppeared || reduceMotion ? 0 : mascotHeight)
                        .opacity(hasAppeared ? 1 : 0)
                }
                .frame(width: size.width, height: size.height)
                .clipped()
            }
            .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Moko")
        .accessibilityHint("Continue to the app")
        .task {
            do {
                try await Task.sleep(for: .milliseconds(80))
                withAnimation(reduceMotion ? MocoScreenTheme.Motion.crossfade : MocoScreenTheme.Motion.mascotEntrance) {
                    hasAppeared = true
                }
                guard autoAdvance else { return }
                try await Task.sleep(for: .milliseconds(1_500))
                try Task.checkCancellation()
                finish()
            } catch { /* Leaving the splash cancels its pending navigation. */ }
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

#Preview("Splash") {
    SplashScreenView(autoAdvance: false)
}
