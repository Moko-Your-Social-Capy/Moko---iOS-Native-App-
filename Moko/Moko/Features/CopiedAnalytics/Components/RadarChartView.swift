import SwiftUI

/// Custom SwiftUI Shape because Swift Charts has no built-in radar/spider chart.
struct RadarChartView: View {
    let metrics: [RadarMetric]

    private let ringCount = 4

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width * 0.31, geometry.size.height * 0.34)

            ZStack {
                ForEach(1...ringCount, id: \.self) { ring in
                    RadarPolygon(values: Array(repeating: Double(ring) / Double(ringCount), count: metrics.count))
                        .stroke(AppColors.divider, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                        .frame(width: radius * 2, height: radius * 2)
                }

                ForEach(metrics.indices, id: \.self) { index in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(index, value: 1, center: center, radius: radius, count: metrics.count))
                    }
                    .stroke(AppColors.divider, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }

                RadarPolygon(values: metrics.map { Double($0.value) / 100 })
                    .fill(AppColors.amber.opacity(0.42))
                    .frame(width: radius * 2, height: radius * 2)

                RadarPolygon(values: metrics.map { Double($0.value) / 100 })
                    .stroke(AppColors.amber, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(metrics.indices, id: \.self) { index in
                    let p = point(index, value: 1.23, center: center, radius: radius, count: metrics.count)
                    VStack(spacing: 1) {
                        Text(metrics[index].title)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(AppColors.secondaryInk)
                        Text("\(metrics[index].value)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.ink)
                    }
                    .position(clamped(p, in: geometry.size))
                }

                Circle()
                    .fill(AppColors.amber)
                    .frame(width: 5, height: 5)
                    .position(point(0, value: Double(metrics.first?.value ?? 0) / 100, center: center, radius: radius, count: metrics.count))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Radar chart for Clarity, Courage, Presence, and Warmth")
    }

    private func point(_ index: Int, value: Double, center: CGPoint, radius: CGFloat, count: Int) -> CGPoint {
        let angle = -Double.pi / 2 + (2 * Double.pi * Double(index) / Double(max(count, 1)))
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius * CGFloat(value),
            y: center.y + CGFloat(sin(angle)) * radius * CGFloat(value)
        )
    }

    private func clamped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: min(max(point.x, 35), size.width - 35),
                y: min(max(point.y, 16), size.height - 16))
    }
}

private struct RadarPolygon: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count >= 3 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for (index, value) in values.enumerated() {
            let angle = -Double.pi / 2 + (2 * Double.pi * Double(index) / Double(values.count))
            let point = CGPoint(
                x: center.x + cos(angle) * radius * CGFloat(min(max(value, 0), 1)),
                y: center.y + sin(angle) * radius * CGFloat(min(max(value, 0), 1))
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
