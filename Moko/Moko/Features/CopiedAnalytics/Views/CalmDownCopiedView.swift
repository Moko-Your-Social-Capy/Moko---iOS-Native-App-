import SwiftUI
import Charts

struct CalmDownCopiedView: View {
    @State private var period: MokoPeriod = .day

    @Environment(\.dismiss) private var dismiss

    private var bars: [BarDatum] { DemoMokoData.calmBars(for: period) }
    private var activities: [CalmActivity] { DemoMokoData.activities(for: period) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitle(title: "Summary", showsBack: true, backAction: { dismiss() })
                    .padding(.top, 8)

                MokoPeriodPicker(selection: $period)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TOTAL TIME")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(AppColors.secondaryInk)
                        Text(totalTimeText)
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x5B4634))

                        Chart {
                            ForEach(Array(bars.enumerated()), id: \.element.id) { index, item in
                                BarMark(
                                    x: .value("Period", item.label),
                                    y: .value("Minutes", item.minutes),
                                    width: .ratio(0.72)
                                )
                                .foregroundStyle(index == selectedBarIndex ? AppColors.amber : AppColors.amber.opacity(0.32))
                                .cornerRadius(3)
                            }
                        }
                        .chartLegend(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .trailing, values: .automatic) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(AppColors.divider)
                                AxisValueLabel()
                                    .font(.system(size: 7))
                                    .foregroundStyle(AppColors.secondaryInk)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.system(size: 7))
                                    .foregroundStyle(AppColors.secondaryInk)
                            }
                        }
                        .chartYScale(domain: 0...(maxValue * 1.2))
                        .frame(height: 120)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("All Activities")
                            .font(.system(size: 12, weight: .bold))
                        HStack {
                            Text(completedTitle)
                                .font(.system(size: 9, weight: .medium))
                            Spacer()
                            Text("\(DemoMokoData.activityCount(for: period)) Sessions")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.secondaryInk)
                        }

                        ForEach(activities) { activity in
                            HStack(spacing: 9) {
                                Image(systemName: activity.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppColors.amber)
                                    .frame(width: 28, height: 28)
                                    .background(AppColors.amberSoft, in: RoundedRectangle(cornerRadius: 8))
                                Text(activity.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(AppColors.ink)
                                Spacer()
                                Text(duration(activity.minutes))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(AppColors.secondaryInk)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(AppColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: period)
    }

    private var selectedBarIndex: Int { max(0, bars.count / 2) }
    private var maxValue: Double { max(bars.map(\.minutes).max() ?? 1, 1) }
    private var completedTitle: String {
        switch period {
        case .day: "Completed Today"
        case .week: "Completed This Week"
        case .month: "Completed This Month"
        }
    }
    private var totalTimeText: String {
        let minutes = DemoMokoData.totalMinutes(for: period)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining == 0 ? "\(hours) hr" : "\(hours) hr \(remaining) min"
    }
    private func duration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining == 0 ? "\(hours) hours" : "\(hours) hr \(remaining) min"
    }
}

#Preview { NavigationStack { CalmDownCopiedView() } }
