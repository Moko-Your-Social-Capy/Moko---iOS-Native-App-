//
//  MokoComponents.swift
//  Moko
//
//  The shared building blocks every screen uses:
//  - `.mokoCard()`      a white rounded card with a soft shadow
//  - `MokoBackdrop`     the screen background with the bush and leaf drawings
//  - `MokoSlideControl` the "slide to finish" button
//  - `MokoRadarChart`   the diamond chart on Insights
//  - `MokoBarChart`     the small bar chart on Insights
//  Sizes and colours come from `MokoScreenTheme`, so change them there.
//

import SwiftUI
import UIKit

// A short nickname so we can write `Theme.Colors` instead of `MokoScreenTheme.Colors`.
private typealias Theme = MokoScreenTheme

// MARK: - Card shell (§6.2)

// A ViewModifier is a reusable "recipe" of modifiers. We wrap it in `.mokoCard()` below.
private struct MokoCardModifier: ViewModifier {
    let fill: Color?
    let radius: CGFloat
    /// Locked and disabled surfaces drop the lift so they read as set aside.
    var lift: Bool = true

    @Environment(\.mokoTheme) private var theme

    func body(content: Content) -> some View {
        let surface = fill ?? theme.colors.cardSurface
        let shadow = theme.colors.cardShadow
        let border = theme.colors.cardBorder
        let glow = theme.colors.cardGlow

        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(surface)
                    .shadow(color: lift ? shadow.opacity(theme.isDark ? 0.45 : 0.12) : .clear,
                            radius: lift ? (theme.isDark ? 10 : 13) : 0,
                            x: 0, y: lift ? (theme.isDark ? 6 : 10) : 0)
                    .shadow(color: lift && theme.isDark ? glow.opacity(0.06) : .clear,
                            radius: lift && theme.isDark ? 14 : 0,
                            x: 0, y: 0)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(border.opacity(theme.isDark ? 0.9 : 0.0), lineWidth: theme.isDark ? 1 : Theme.Card.outline)
            }
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    /// Theme-aware card surface with elevation. Defaults to the active theme card surface.
    func mokoCard(fill: Color? = nil,
                  radius: CGFloat = Theme.Radius.card,
                  lift: Bool = true) -> some View {
        modifier(MokoCardModifier(fill: fill, radius: radius, lift: lift))
    }
}

// MARK: - Background (§5)

/// Theme-aware app background with dark-mode water-flow shader (top half only).
struct MokoBackdrop: View {
    var body: some View {
        MokoAnimatedBackdrop()
    }
}

/// Five overlapping rounded lobes on a 10pt trunk. Explicitly not a mushroom:
/// no cap, no gills, no dome — line art only.
struct VectorBushShape: Shape {
    private let design = CGSize(width: 310, height: 200)

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / design.width
        var path = Path()

        // Trunk: two open rails, 10pt apart, bleeding off the bottom edge.
        path.move(to: CGPoint(x: 150, y: 200))
        path.addLine(to: CGPoint(x: 150, y: 128))
        path.move(to: CGPoint(x: 160, y: 200))
        path.addLine(to: CGPoint(x: 160, y: 128))

        // Lobes: equal-radius circles, staggered heights, widest 62pt.
        let lobes: [(x: CGFloat, radius: CGFloat, lift: CGFloat)] = [
            (28, 22, 4),
            (82, 27, -4),
            (140, 31, -8),
            (196, 26, -2),
            (246, 19, 6)
        ]

        for lobe in lobes {
            let centerY = 130 - lobe.radius + lobe.lift
            let frame = CGRect(x: lobe.x - lobe.radius,
                               y: centerY - lobe.radius,
                               width: lobe.radius * 2,
                               height: lobe.radius * 2)
            path.addEllipse(in: frame)
        }

        return path.applying(
            CGAffineTransform(scaleX: scale, y: scale)
                .concatenating(
                    CGAffineTransform(translationX: rect.minX, y: rect.maxY - design.height * scale)
                )
        )
    }
}

/// Almond lens 96×44 with a central vein and three paired side veins at 35°.
struct VectorLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midY = h / 2
        let gap: CGFloat = 2

        var path = Path()

        // Lens: two mirrored quadratics.
        path.move(to: CGPoint(x: 0, y: midY))
        path.addQuadCurve(to: CGPoint(x: w, y: midY),
                          control: CGPoint(x: w * 0.5, y: -h * 0.32))
        path.addQuadCurve(to: CGPoint(x: 0, y: midY),
                          control: CGPoint(x: w * 0.5, y: h * 1.32))

        // Central vein, stopping 2pt short of each terminal.
        path.move(to: CGPoint(x: gap * 2, y: midY))
        path.addLine(to: CGPoint(x: w - gap * 2, y: midY))

        // Three paired side veins at 35°.
        let radians: CGFloat = 35 * .pi / 180
        let slope = tan(radians)
        for step in 1...3 {
            let x = w * CGFloat(step) / 4
            let reach = h * 0.30
            let dx = reach / slope

            path.move(to: CGPoint(x: x, y: midY))
            path.addLine(to: CGPoint(x: x + dx, y: midY - reach))

            path.move(to: CGPoint(x: x, y: midY))
            path.addLine(to: CGPoint(x: x + dx, y: midY + reach))
        }

        return path.applying(
            CGAffineTransform(translationX: rect.minX, y: rect.minY)
        )
    }
}

// MARK: - Control/Slide (§6.4)

/// Small helpers that make the phone buzz. "Impact" is a tap, "notify" is a success/error pattern.
private enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

/// What the slider is doing right now.
/// idle = untouched, dragging = finger on it, ready = far enough to finish,
/// completing = finished and playing the end animation.
private enum SlideState {
    case idle, dragging, ready, completing
}

/// Track 54, knob 46 inset 4, five states, rubber-band ends, 10% a11y steps.
struct MokoSlideControl: View {
    let label: String
    let onComplete: () -> Void

    // The phone setting "Reduce Motion". If it is on, we skip the bouncy animations.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // How far (in points) the round knob has moved to the right.
    @State private var travel: CGFloat = 0
    // Where the knob was when the finger first touched it.
    @State private var dragStart: CGFloat = 0
    // Which step of the slide we are in (see SlideState above).
    @State private var state: SlideState = .idle
    // True for a moment when the slide finishes, so the track flashes lighter.
    @State private var flashToTint = false
    // Flips on and off forever to make the idle track gently "breathe".
    @State private var breath = false
    // Remembers the last buzz position so we only buzz once per step.
    @State private var lastHapticStep = 0

    private var trackHeight: CGFloat { Theme.Control.trackHeight }
    private var knobSize: CGFloat { Theme.Control.knob }
    private var knobInset: CGFloat { Theme.Control.knobInset }

    var body: some View {
        GeometryReader { geo in
            let maxTravel = max(1, geo.size.width - knobSize - knobInset * 2)

            track(maxTravel: maxTravel)
                .overlay(alignment: .leading) {
                    knob
                        .offset(x: knobInset + travel)
                }
                .contentShape(Capsule())
                .gesture(dragGesture(maxTravel: maxTravel))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityValue("\(Int((min(travel, maxTravel) / maxTravel) * 100)) percent")
                .accessibilityAddTraits(.isButton)
                .accessibilityAdjustableAction { direction in
                    adjust(direction, maxTravel: maxTravel)
                }
                .accessibilityAction(named: Text("Complete")) {
                    complete(maxTravel: maxTravel)
                }
                // Runs once when the slider shows up and starts the idle "breathing" glow.
                .onAppear(perform: startBreathing)
        }
        .frame(height: trackHeight)
    }

    // MARK: Layers

    private func track(maxTravel: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(flashToTint ? Theme.Colors.accentBlueTint : Theme.Colors.accentBlue)

            // Fill behind the knob while it moves.
            Rectangle()
                .fill(Color.black.opacity(state == .idle ? 0 : 0.10))
                .frame(width: knobInset + travel + knobSize)

            Text(label)
                .mokoText(Theme.Typeface.slider)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .opacity(labelOpacity(maxTravel: maxTravel))
                .allowsHitTesting(false)

            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "chevron.right")
                        .font(.system(size: Theme.Control.chevronSize, weight: .bold))
                }
            }
            .foregroundStyle(Color.white.opacity(0.35))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, Theme.Space.s3)
            .opacity(state == .dragging || state == .ready ? 1 : 0)
            .allowsHitTesting(false)

            // Inset top highlight.
            Capsule()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: Theme.Line.hair)
        }
        .frame(height: trackHeight)
        .clipShape(Capsule())
        .overlay {
            // Idle breath: 0 → 6% white over 2.4s.
            Capsule()
                .fill(Color.white.opacity(breath ? 0.06 : 0))
                .allowsHitTesting(false)
        }
    }

    private var knob: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.surfaceWhite)
                .frame(width: knobSize, height: knobSize)
                .overlay {
                    Circle()
                        .strokeBorder(Theme.Colors.strokeInk.opacity(0.10),
                                      lineWidth: Theme.Line.hair)
                }
                .shadow(color: Theme.Elevation.knobColor,
                        radius: Theme.Elevation.knobRadius,
                        x: 0, y: Theme.Elevation.knobOffset)

            Image(systemName: isGlyphChecked ? "checkmark" : "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentBlue)
                .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
        }
        .frame(width: knobSize, height: knobSize)
        .animation(Theme.Motion.glyphSwap, value: isGlyphChecked)
        .accessibilityHidden(true)
    }

    private var isGlyphChecked: Bool {
        state == .ready || state == .completing
    }

    // MARK: Behaviour

    private func dragGesture(maxTravel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard state != .completing else { return }

                if state == .idle {
                    state = .dragging
                    dragStart = min(travel, maxTravel)
                    Haptics.impact(.light)
                }

                let raw = dragStart + value.translation.width
                travel = rubberBanded(raw, maxTravel: maxTravel)

                let reached = travel >= maxTravel * Theme.Control.completionThreshold
                if reached {
                    if state != .ready {
                        state = .ready
                        Haptics.impact(.medium)
                    }
                } else if state == .ready {
                    state = .dragging
                }

                tickHaptics(every: 44)
            }
            .onEnded { _ in
                guard state != .completing else { return }

                if travel >= maxTravel * Theme.Control.completionThreshold {
                    complete(maxTravel: maxTravel)
                } else {
                    state = .idle
                    lastHapticStep = 0
                    withAnimation(reduceMotion ? nil : Theme.Motion.snapBack) {
                        travel = 0
                    }
                }
            }
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection, maxTravel: CGFloat) {
        guard state != .completing else { return }

        let step = maxTravel * 0.10
        switch direction {
        case .increment:
            travel = min(maxTravel, travel + step)
        case .decrement:
            travel = max(0, travel - step)
        @unknown default:
            return
        }

        state = travel >= maxTravel * Theme.Control.completionThreshold ? .ready : .dragging

        if state == .ready {
            complete(maxTravel: maxTravel)
        }
    }

    private func complete(maxTravel: CGFloat) {
        guard state != .completing else { return }
        state = .completing
        Haptics.notify(.success)

        withAnimation(reduceMotion ? nil : Theme.Motion.snapToEnd) {
            travel = maxTravel
        }

        guard !reduceMotion else {
            onComplete()
            return
        }

        // Track flashes accent → tint → accent over 240ms, then the card swaps.
        // `Task` lets us wait without freezing the screen; `Task.sleep` is the wait.
        Task {
            withAnimation(Theme.Motion.flash) { flashToTint = true }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(Theme.Motion.flash) { flashToTint = false }
            try? await Task.sleep(for: .milliseconds(120))
            onComplete()
        }
    }

    /// Past either end the knob only moves 15% as far as the finger,
    /// so it feels like stretching a rubber band.
    private func rubberBanded(_ raw: CGFloat, maxTravel: CGFloat) -> CGFloat {
        if raw < 0 { return raw * 0.15 }
        if raw > maxTravel { return maxTravel + (raw - maxTravel) * 0.15 }
        return raw
    }

    private func labelOpacity(maxTravel: CGFloat) -> Double {
        let progress = min(travel, maxTravel) / maxTravel
        // Fades across 45–60% of the drag.
        let fade = (progress - 0.45) / 0.15
        return Double(1 - min(max(fade, 0), 1))
    }

    /// Gives a light buzz every `step` points so the drag feels like a ratchet.
    private func tickHaptics(every step: CGFloat) {
        let index = Int(travel / step)
        guard index != lastHapticStep else { return }
        lastHapticStep = index
        Haptics.impact(.light)
    }

    /// Starts a slow glow that repeats forever while the slider is waiting.
    private func startBreathing() {
        guard !reduceMotion else { return }
        withAnimation(Theme.Motion.breath.repeatForever(autoreverses: true)) {
            breath = true
        }
    }
}

// MARK: - Control/Radar (§6.5)

/// Four axes on a 45° diamond, three rings at 33/66/100%, violet at 35%.
struct MokoRadarChart: View {
    var scores: InsightsScores = .zero

    private let ringFactors: [CGFloat] = [0.33, 0.66, 1.0]

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2 - Theme.Line.data
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Outer/inner rings use different theme chart colors for a 2-3 color look.
                ForEach(Array(ringFactors.enumerated()), id: \.offset) { idx, factor in
                    diamond(center: center, radius: radius * factor)
                        .stroke(idx == ringFactors.count - 1 ? Theme.Colors.dataViolet : Theme.Colors.dataGrid, lineWidth: Theme.Line.data)
                }

                axes(center: center, radius: radius)
                    .stroke(Theme.Colors.dataGrid, lineWidth: Theme.Line.data)

                dataPolygon(center: center, radius: radius)
                    .fill(Theme.Colors.dataViolet.opacity(0.28))

                dataPolygon(center: center, radius: radius)
                    .stroke(Theme.Colors.dataVioletDeep,
                            style: StrokeStyle(lineWidth: Theme.Line.data, lineJoin: .round))

                ForEach(Array(vertexPoints(center: center, radius: radius).enumerated()), id: \.offset) { idx, point in
                    // Vertex dots cycle theme chart colors so the graph shows 2-3 colors.
                    let dotColors = [Theme.Colors.dataVioletDeep, Theme.Colors.dataViolet, Theme.Colors.chartTertiary, Theme.Colors.dataVioletDeep]
                    Circle()
                        .fill(dotColors[idx % dotColors.count])
                        .frame(width: 4, height: 4)
                        .position(point)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Insights radar chart")
    }

    // Top = courage, right = presence, bottom = warmth, left = clarity.
    private func values() -> [Double] {
        [scores.courage, scores.presence, scores.warmth, scores.clarity]
    }

    private func vertexPoints(center: CGPoint, radius: CGFloat) -> [CGPoint] {
        let ratios = values().map { max(0, min(100, $0)) / 100 }
        return [
            CGPoint(x: center.x, y: center.y - radius * ratios[0]),
            CGPoint(x: center.x + radius * ratios[1], y: center.y),
            CGPoint(x: center.x, y: center.y + radius * ratios[2]),
            CGPoint(x: center.x - radius * ratios[3], y: center.y)
        ]
    }

    /// One diamond-shaped ring of the background grid.
    private func diamond(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
        return path
    }

    private func axes(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.move(to: CGPoint(x: center.x - radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        return path
    }

    /// The filled violet shape that shows the four scores.
    private func dataPolygon(center: CGPoint, radius: CGFloat) -> Path {
        let points = vertexPoints(center: center, radius: radius)
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Control/Bars (§6.6)

/// 8pt-gap bars, 6pt wide, 3pt radius, ascending opacity, last bar deep +2pt.
struct MokoBarChart: View {
    var values: [Double]

    private let barWidth: CGFloat = 6
    private let gap: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let peak = max(values.max() ?? 0, 1)
            let count = max(values.count, 1)

            HStack(alignment: .bottom, spacing: gap) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let isLast = index == count - 1
                    let emphasis: CGFloat = isLast ? 2 : 0
                    // Mix 2-3 theme chart colors so each theme's graph feels distinct.
                    let fillColor: Color = isLast ? Theme.Colors.dataVioletDeep : (index % 2 == 0 ? Theme.Colors.dataViolet : Theme.Colors.chartTertiary)

                    RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                        .fill(fillColor)
                        .opacity(isLast ? 1 : max(0.55, opacity(at: index, of: count)))
                        .frame(width: barWidth,
                               height: barHeight(value, peak: peak, available: geo.size.height) + emphasis)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .accessibilityElement()
        .accessibilityLabel("Calm down minutes for recent days")
    }

    /// Older bars are fainter, newer bars are stronger (45% → 90%).
    private func opacity(at index: Int, of count: Int) -> Double {
        guard count > 1 else { return 0.7 }
        return 0.45 + (0.45 * Double(index) / Double(count - 1))
    }

    /// Bar height compared with the tallest bar. Empty days still get a 4pt stub.
    private func barHeight(_ value: Double, peak: Double, available: CGFloat) -> CGFloat {
        guard value > 0 else { return 4 }
        return max(4, available * CGFloat(value / peak))
    }
}
