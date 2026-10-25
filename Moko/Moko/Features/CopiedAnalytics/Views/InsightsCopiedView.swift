import SwiftUI

struct InsightsCopiedView: View {
    @State private var period: MokoPeriod = .day
    @State private var expandedMetric: String? = "Courage"

    @Environment(\.dismiss) private var dismiss

    private var metrics: [RadarMetric] { DemoMokoData.metrics(for: period) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitle(title: "Insights", showsBack: true, backAction: { dismiss() })
                    .padding(.top, 8)

                MokoPeriodPicker(selection: $period)

                SurfaceCard {
                    RadarChartView(metrics: metrics)
                        .frame(height: 218)
                }

                HStack(spacing: 10) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(AppColors.amber)
                        .frame(width: 42, height: 42)
                        .background(AppColors.amberSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your growth profile").font(.system(size: 14, weight: .bold))
                        Text("A snapshot of your progress across four dimensions.")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.secondaryInk)
                    }
                }
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your four parameters")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Scroll to see what shapes each score.")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.secondaryInk)

                    VStack(spacing: 0) {
                        ForEach(metrics) { metric in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    expandedMetric = expandedMetric == metric.id ? nil : metric.id
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(metric.title)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppColors.ink)
                                        Spacer()
                                        Text("\(metric.value)")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(metric.title == "Courage" ? AppColors.amber : AppColors.forest)
                                        Image(systemName: expandedMetric == metric.id ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(AppColors.amber)
                                    }
                                    if expandedMetric == metric.id {
                                        Text(metric.note)
                                            .font(.system(size: 10))
                                            .foregroundStyle(AppColors.secondaryInk)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.bottom, 3)
                                    }
                                }
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if metric.id != metrics.last?.id {
                                Rectangle().fill(AppColors.divider).frame(height: 1)
                            }
                        }
                    }
                }
                .padding(14)
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(AppColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: period)
    }
}

#Preview { NavigationStack { InsightsCopiedView() } }
