import SwiftUI
import Charts

struct CalmDownCopiedView: View {
    @State private var period: InsightsPeriod = .week

    private var data: [(label: String, count: Int)] {
        switch period {
        case .day: return [("AM", 1), ("Noon", 0), ("PM", 2), ("Night", 1)]
        case .week: return [("M", 1), ("T", 2), ("W", 0), ("T", 3), ("F", 1), ("S", 2), ("S", 1)]
        case .month: return [("Wk 1", 4), ("Wk 2", 6), ("Wk 3", 3), ("Wk 4", 7)]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calm Down").font(.largeTitle.bold())
                    Text("Your calm moments, over time")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                PeriodPicker(selection: $period)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sessions").font(.headline)
                            Text(summary).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(data.reduce(0) { $0 + $1.count })")
                            .font(.title2.bold().monospacedDigit())
                    }

                    Chart {
                        ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                            BarMark(x: .value("Period", item.label),
                                    y: .value("Sessions", item.count))
                                .foregroundStyle(AppColors.chartStroke)
                                .cornerRadius(5)
                        }
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 210)
                }
                .padding(18)
                .background(AppColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises").font(.title3.bold())
                    ExerciseRow(title: "Breathing", detail: "A guided breathing reset", icon: "wind", duration: "1–10 min")
                    ExerciseRow(title: "Grounding", detail: "Return your attention to the present", icon: "leaf", duration: "2–5 min")
                    ExerciseRow(title: "Reflection", detail: "Pause and check in with yourself", icon: "book.closed", duration: "3 min")
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var summary: String {
        switch period {
        case .day: return "Sessions today"
        case .week: return "Sessions this week"
        case .month: return "Sessions this month"
        }
    }
}

private struct ExerciseRow: View {
    let title: String
    let detail: String
    let icon: String
    let duration: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3)
                .frame(width: 44, height: 44)
                .background(AppColors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text(duration).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 18))
    }
}

#Preview { NavigationStack { CalmDownCopiedView() } }
