import SwiftUI

/// Shared completion illustration used by every relaxation flow.
/// The layout keeps the success badge prominent while lemons fall behind it.
struct MokoCompletionAnimation: View {
    var ringDiameter: CGFloat = 210

    @State private var startedAt = Date()

    private let duration: TimeInterval = 3.6
    private let lemonDelays: [Double] = [0, 0.45, 0.9, 1.35, 1.8, 2.25, 2.7, 3.15]
    private let lemonPositions: [CGFloat] = [0.08, 0.88, 0.96, 0.14, 0.79, 0.25, 0.91, 0.13]
    private let lemonSizes: [CGFloat] = [0.58, 0.52, 0.48, 0.54, 0.57, 0.48, 0.55, 0.52]

    private var canvasSide: CGFloat { ringDiameter * 1.55 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(startedAt))
            let time = elapsed.truncatingRemainder(dividingBy: duration)
            let checkCycle = elapsed.truncatingRemainder(dividingBy: 1.8)
            let checkProgress = CGFloat(min(1, checkCycle / 0.27))
            let entrance = min(1, elapsed / 0.44)
            let easedEntrance = entrance * entrance * (3 - 2 * entrance)
            let overshoot = 1 + 0.055 * exp(-7 * elapsed) * sin(15 * elapsed)
            let breathing = 1 + 0.018 * sin(elapsed * .pi * 2 / 2.4)
            let badgeScale = CGFloat((0.78 + 0.22 * easedEntrance) * overshoot * breathing)

            ZStack {
                Canvas { context, canvasSize in
                    let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    let radius = ringDiameter / 2

                    drawFallingLemons(in: &context, size: canvasSize, time: time)
                    drawRipples(in: &context, center: center, radius: radius, time: time)
                    context.translateBy(x: center.x, y: center.y)
                    context.scaleBy(x: badgeScale, y: badgeScale)
                    context.translateBy(x: -center.x, y: -center.y)
                    drawBadge(in: &context, center: center, radius: radius)
                }

                CompletionCheckmark()
                    .trim(from: 0, to: checkProgress)
                    .stroke(
                        .white,
                        style: StrokeStyle(lineWidth: max(5, ringDiameter * 0.044), lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: ringDiameter * 0.37, height: ringDiameter * 0.37)
                    .scaleEffect(badgeScale)
                    .frame(width: canvasSide, height: canvasSide)
            }
            .frame(width: canvasSide, height: canvasSide)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session complete. A check mark appears as green rings pulse and lemons fall.")
        .onAppear {
            startedAt = Date()
        }
    }

    private func drawBadge(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let outer = CGRect(x: center.x - radius, y: center.y - radius,
                           width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: outer), with: .color(Color(hex: 0xEAF6C8)))
        context.stroke(Path(ellipseIn: outer), with: .color(Color(hex: 0x315F35)), lineWidth: max(4, ringDiameter * 0.03))

        let layers: [(CGFloat, Color)] = [
            (0.77, Color(hex: 0xB7E888)),
            (0.62, Color(hex: 0x65BD4B)),
            (0.48, Color(hex: 0x006B36))
        ]
        for (fraction, fill) in layers {
            let r = radius * fraction
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)),
                with: .color(fill)
            )
        }
    }

    private func drawRipples(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, time: Double) {
        for index in 0..<3 {
            let period = 1.35
            let phase = (time + Double(index) * 0.37).truncatingRemainder(dividingBy: period) / period
            let rippleRadius = radius * CGFloat(1.02 + phase * 0.48)
            let rect = CGRect(x: center.x - rippleRadius, y: center.y - rippleRadius,
                              width: rippleRadius * 2, height: rippleRadius * 2)
            let tint = index == 0 ? Color(hex: 0x7FCB62) : Color(hex: 0xB5DF70)
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(tint.opacity((1 - phase) * 0.22)),
                lineWidth: max(2, ringDiameter * (0.047 - CGFloat(index) * 0.006))
            )
        }
    }

    private func drawFallingLemons(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let scale = ringDiameter / 286
        for index in lemonDelays.indices {
            let p = (time - lemonDelays[index] + duration)
                .truncatingRemainder(dividingBy: duration) / duration
            let eased = p * p * (3 - 2 * p)
            let y = -ringDiameter * 0.25 + CGFloat(eased) * (size.height + ringDiameter * 0.5)
            let x = size.width * lemonPositions[index] + CGFloat(sin(p * .pi * 2) * ringDiameter * 0.035)
            let fade = min(1, min(p / 0.1, (1 - p) / 0.1))
            drawLemon(
                in: &context,
                at: CGPoint(x: x, y: y),
                scale: scale * lemonSizes[index],
                rotation: CGFloat(p * .pi * 0.9) * (index.isMultiple(of: 2) ? 1 : -1),
                opacity: fade
            )
        }
    }

    private func drawLemon(in context: inout GraphicsContext, at point: CGPoint, scale: CGFloat, rotation: CGFloat, opacity: Double) {
        var lemon = Path()
        lemon.move(to: CGPoint(x: -26, y: 0))
        lemon.addCurve(to: CGPoint(x: 26, y: 0), control1: CGPoint(x: -16, y: 22), control2: CGPoint(x: 16, y: 22))
        lemon.addCurve(to: CGPoint(x: -26, y: 0), control1: CGPoint(x: 16, y: -22), control2: CGPoint(x: -16, y: -22))
        lemon.closeSubpath()

        var leaf = Path()
        leaf.move(to: CGPoint(x: -2, y: 18))
        leaf.addQuadCurve(to: CGPoint(x: 12, y: 27), control: CGPoint(x: 5, y: 31))
        leaf.addQuadCurve(to: CGPoint(x: -2, y: 18), control: CGPoint(x: 0, y: 27))
        leaf.closeSubpath()

        var transform = CGAffineTransform(translationX: point.x, y: point.y)
        transform = transform.rotated(by: rotation)
        transform = transform.scaledBy(x: scale, y: scale)
        let fruit = lemon.applying(transform)
        let stem = leaf.applying(transform)
        context.fill(fruit, with: .color(Color(hex: 0xF6CF42).opacity(opacity)))
        context.stroke(fruit, with: .color(Color(hex: 0xD9A927).opacity(opacity)), lineWidth: max(1, ringDiameter * 0.007))
        context.fill(stem, with: .color(Color(hex: 0x5D9B47).opacity(opacity)))
    }
}

private struct CompletionCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.39, y: rect.minY + rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.23))
        return path
    }
}
