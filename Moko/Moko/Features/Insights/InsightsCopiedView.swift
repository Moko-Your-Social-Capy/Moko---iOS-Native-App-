import SwiftUI

struct InsightMetric: Identifiable {
    let id: String
    let title: String
    let value: Double
    let detail: String
}

struct InsightsCopiedView: View {
    @State private var period: InsightsPeriod = .week

    // Demo values only; replace with the user's real progress model.
    private var metrics: [InsightMetric] {
        let values: [(String, Double, String)]
        switch period {
        case .day:
            values = [("Focus", 62, "Attention and time on task"),
                      ("Calm", 78, "Calm-down sessions"),
                      ("Consistency", 54, "Habits completed today"),
                      ("Reflection", 70, "Reflection activity")]
        case .week:
            values = [("Focus", 76, "Attention and time on task"),
                      ("Calm", 68, "Calm-down sessions"),
                      ("Consistency", 84, "Habits completed this week"),
                      ("Reflection", 59, "Reflection activity")]
        case .month:
            values = [("Focus", 71, "Attention and time on task"),
                      ("Calm", 82, "Calm-down sessions"),
                      ("Consistency", 73, "Habits completed this month"),
                      ("Reflection", 66, "Reflection activity")]
        }
        return values.map { InsightMetric(id: $0.0, title: $0.0, value: $0.1, detail: $0.2) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Insights").font(.largeTitle.bold())
                    Text("A snapshot of your progress")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                PeriodPicker(selection: $period)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Your balance").font(.headline)
                        Spacer()
                        Text(period.rawValue).foregroundStyle(.secondary)
                    }
                    RadarChartView(values: metrics.map(\.value), labels: metrics.map(\.title))
                        .frame(height: 290)

                    HStack(spacing: 0) {
                        ForEach(metrics) { metric in
                            VStack(spacing: 4) {
                                Text(metric.title).font(.caption).foregroundStyle(.secondary)
                                Text("\(Int(metric.value))").font(.headline.monospacedDigit())
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(18)
                .background(AppColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your four parameters").font(.title3.bold())
                    ForEach(metrics) { metric in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(metric.title).font(.headline)
                                Text(metric.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(metric.value))/100")
                                .font(.title3.bold().monospacedDigit())
                        }
                        .padding(15)
                        .background(AppColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: period)
    }
}

struct RadarChartView: View {
    let values: [Double]
    let labels: [String]

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) * 0.30
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            ZStack {
                ForEach(1...4, id: \.self) { ring in
                    RadarPolygon(values: Array(repeating: Double(ring) / 4, count: values.count))
                        .stroke(AppColors.separator.opacity(0.6), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                }
                ForEach(values.indices, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(i, 1, center, radius, values.count))
                    }
                    .stroke(AppColors.separator.opacity(0.6), lineWidth: 1)
                }
                RadarPolygon(values: values.map { min(max($0 / 100, 0), 1) })
                    .fill(AppColors.chartFill)
                    .frame(width: radius * 2, height: radius * 2)
                RadarPolygon(values: values.map { min(max($0 / 100, 0), 1) })
                    .stroke(AppColors.chartStroke, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(labels.indices, id: \.self) { i in
                    Text(labels[i])
                        .font(.caption.weight(.medium))
                        .position(point(i, 1.27, center, radius, labels.count))
                }
            }
        }
        .accessibilityLabel("Radar chart showing four insight parameters")
    }

    private func point(_ index: Int, _ fraction: Double, _ center: CGPoint, _ radius: CGFloat, _ count: Int) -> CGPoint {
        let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(max(count, 1))
        return CGPoint(x: center.x + cos(angle) * radius * fraction,
                       y: center.y + sin(angle) * radius * fraction)
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
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(values.count)
            let point = CGPoint(x: center.x + cos(angle) * radius * min(max(value, 0), 1),
                                y: center.y + sin(angle) * radius * min(max(value, 0), 1))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

#Preview { NavigationStack { InsightsCopiedView() } }
