import SwiftUI

/// Plays the supplied animated Moko Tick Complete SVG for completion moments.
/// Uses the SVG's SMIL animation directly for smooth, blendable rendering.
struct MokoTickCompleteView: View {
    // How big the animation should appear on screen.
    var size: CGFloat = 240

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MokoSVGAnimationView(name: MokoAnimationAssets.tickCompleteSVG)
            .frame(width: size, height: size)
            .background(Color.clear)
            .accessibilityHidden(true)
    }
}

/// Reusable completion experience used across Relax, Debrief, and Onboarding.
struct MokoCompletionView: View {
    var title: String
    var subtitle: String? = nil
    var illustrationSize: CGFloat = 240
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    @Environment(\.mokoTheme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            MokoTickCompleteView(size: illustrationSize)
                .frame(maxWidth: .infinity)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if let actionTitle, let onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                }
                .mokoPrimaryCTA()
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 24)
        .background(theme.colors.completionBackground.ignoresSafeArea())
    }
}
