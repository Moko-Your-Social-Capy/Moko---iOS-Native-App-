//
//  EnhancedInsightsRadar.swift
//  Moko
//
//  High-visibility 4-point radar chart with color-coded vertices, reference rings,
//  and axis labels. Animates from center outward.
//

import SwiftUI

/// 4-point radar polygon that scales from 0 to 1.
/// Values should be 0...1 normalized.
struct StatPolygon: Shape {
    var values: [Double]       // [courage, clarity, presence, warmth] – each 0...1
    var progress: Double = 1.0 // animates 0→1 to grow the shape from center

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let count = values.count

        var path = Path()

        for (i, v) in values.enumerated() {
            // Angle: -π/2 (top) + 2π/count per step, counterclockwise
            let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(count)
            let r = radius * v * progress

            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

/// Axis lines radiating from center to each vertex.
struct RadarAxes: Shape {
    let count: Int = 4  // courage, clarity, presence, warmth

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()

        for i in 0..<count {
            let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(count)
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            path.move(to: center)
            path.addLine(to: point)
        }

        return path
    }
}

/// High-visibility insights radar chart with reference rings, axes, and colored nodes.
struct EnhancedInsightsRadar: View {
    let values: [Double]  // [courage, clarity, presence, warmth] – normalized 0...1
    let labels: [String] = ["Courage", "Clarity", "Presence", "Warmth"]
    let colors: [Color] = [
        Color(hex: 0x7C3AED),  // violet
        Color(hex: 0x10B981),  // green
        Color(hex: 0x4F46E5),  // indigo
        Color(hex: 0x14B8A6),  // teal
    ]

    @State private var progress = 0.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Reference rings (25%, 50%, 75%, 100%)
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { ringValue in
                StatPolygon(values: [ringValue, ringValue, ringValue, ringValue])
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }

            // Axis spokes
            RadarAxes()
                .stroke(Color.black.opacity(0.06), lineWidth: 1)

            // Outer boundary frame
            StatPolygon(values: [1, 1, 1, 1])
                .stroke(MokoScreenTheme.Colors.dataViolet.opacity(0.2), lineWidth: 2)

            // User's data shape - solid fill (no gradient)
            StatPolygon(values: values, progress: progress)
                .fill(MokoScreenTheme.Colors.dataViolet.opacity(0.2))

            StatPolygon(values: values, progress: progress)
                .stroke(MokoScreenTheme.Colors.dataVioletDeep, lineWidth: 2)

            // Color-coded vertex nodes and directional axis labels
            Canvas { ctx, size in
                let rect = CGRect(origin: .zero, size: size)
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let radius = min(size.width, size.height) / 2

                for (i, color) in colors.enumerated() {
                    let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / 4
                    let nodeRadius = radius * values[i] * progress

                    // Draw colored node
                    let nodePoint = CGPoint(
                        x: center.x + cos(angle) * nodeRadius,
                        y: center.y + sin(angle) * nodeRadius
                    )

                    var circlePath = Path()
                    circlePath.addEllipse(in: CGRect(
                        x: nodePoint.x - 6,
                        y: nodePoint.y - 6,
                        width: 12,
                        height: 12
                    ))

                    ctx.fill(circlePath, with: .color(color))

                    // Draw axis labels - larger, bolder, more prominent (like directional labels)
                    let labelDist = radius + 40
                    let labelPoint = CGPoint(
                        x: center.x + cos(angle) * labelDist,
                        y: center.y + sin(angle) * labelDist
                    )

                    let text = Text(labels[i])
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(color)

                    ctx.draw(text, at: labelPoint, anchor: .center)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)  // Always square and centered
        .padding(24)
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2)) {
                    progress = 1
                }
            } else {
                progress = 1
            }
        }
    }
}

#Preview {
    EnhancedInsightsRadar(values: [0.78, 0.85, 0.72, 0.88])
        .padding()
        .frame(maxWidth: 400, maxHeight: 400)
        .background(MokoScreenTheme.Colors.surfaceWhite, in: RoundedRectangle(cornerRadius: 22))
        .padding()
        .background(MokoScreenTheme.Colors.canvasTop)
}
