import SwiftUI

/// Full-screen loading experience using the CI2 MOKO full-loading SVG.
/// Use for initial launch, large library loads, and major initialization only.
struct MokoFullScreenLoader: View {
    var message: String? = nil

    @Environment(\.mokoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            theme.colors.loadingBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                MokoSVGAnimationView(name: MokoAnimationAssets.fullScreenLoadingSVG)
                    .frame(width: 300, height: 300)
                    .scaleEffect(reduceMotion ? 1 : (appeared ? 1.0 : 0.96))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (appeared ? 0 : 8))

                if let message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.easeInOut(duration: 0.8)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}
