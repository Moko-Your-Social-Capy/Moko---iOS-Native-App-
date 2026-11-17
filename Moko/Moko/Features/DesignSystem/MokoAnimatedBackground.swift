import SwiftUI

/// Subtle Metal-based water-flow background used in dark mode only.
/// Rendered only in the top half of the screen so content below stays static.
struct MokoWaterFlowBackground: View {
    @Environment(\.mokoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    // Fixed start time avoids resetting animation on view redraws.
    private let startDate = Date()

    private var shaderPalette: (Color, Color, Color) {
        switch theme.id {
        case .default:
            return (Color(hex: 0x163323), Color(hex: 0x2F6E4A), Color(hex: 0x7FE3B0))
        case .lavender:
            return (Color(hex: 0x24123F), Color(hex: 0x5B3FA3), Color(hex: 0xC7A6FF))
        case .ocean:
            return (Color(hex: 0x08263A), Color(hex: 0x0F5C8C), Color(hex: 0x4FD1C5))
        case .blossom:
            return (Color(hex: 0x321225), Color(hex: 0x7A2F4E), Color(hex: 0xFF9FC0))
        case .midnight:
            return (Color(hex: 0x0B1430), Color(hex: 0x243A7A), Color(hex: 0x7FB0FF))
        case .batman:
            return (Color(hex: 0x05070B), Color(hex: 0x102235), Color(hex: 0x00CEC8))
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height * 0.5
            ZStack(alignment: .top) {
                shaderLayer(height: height)
                    .frame(height: height)
                    .frame(maxWidth: .infinity, alignment: .top)
                    // Soft fade into the static lower background (no hard edge).
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .black, location: 0.72),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func shaderLayer(height: CGFloat) -> some View {
        let (a, b, accent) = shaderPalette
        // Reduce Motion or inactive app: show a calm static tint instead of animating.
        if reduceMotion || scenePhase != .active {
            LinearGradient(colors: [a.opacity(0.28), b.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom)
        } else if #available(iOS 17.0, *) {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: scenePhase != .active)) { context in
                    let time = Float(context.date.timeIntervalSince(startDate))
                    Rectangle()
                        .fill(theme.colors.screenBackground)
                        .colorEffect(
                            ShaderLibrary.mokoWaterFlow(
                                .float2(Float(geo.size.width), Float(geo.size.height)),
                                .float(time),
                                .color(a),
                                .color(b),
                                .color(accent)
                            )
                        )
                }
            }
        } else {
            LinearGradient(colors: [a.opacity(0.22), b.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

/// App background with subtle theme gradient and dark-mode water-flow shader (top half only).
struct MokoAnimatedBackdrop: View {
    @Environment(\.mokoTheme) private var theme

    var body: some View {
        ZStack {
            // Base theme gradient for all appearances.
            theme.colors.backgroundGradient
                .ignoresSafeArea()

            // Atmospheric shader only in dark mode, limited to top half.
            if theme.isDark {
                MokoWaterFlowBackground()
                    .ignoresSafeArea(edges: .top)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
