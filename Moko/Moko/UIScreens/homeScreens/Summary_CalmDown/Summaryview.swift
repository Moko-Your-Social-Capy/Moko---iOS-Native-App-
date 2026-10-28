//
//  SummaryView.swift
//  Moko
//
//  Summary screen: segmented Day / Week / Month picker, Apple Charts bar chart
//  and activity list. Opened from the Calm Down card on the Overview screen.
//

import SwiftUI
import Charts

// MARK: - Model

enum SummaryRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

struct SummaryBar: Identifiable {
    let id = UUID()
    let label: String
    let value: Double          // same unit as maxValue
}

struct SummaryActivity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String           // SF Symbol
    let duration: String
}

struct SummaryData {
    let totalTime: String
    let bars: [SummaryBar]
    let selectedIndex: Int
    let maxValue: Double
    let axisLabels: [String]   // top, middle, bottom
    let listTitle: String
    let activities: [SummaryActivity]

    var selectedLabel: String { bars[selectedIndex].label }

    /// Text for the y-axis marks at 0, half and max.
    func axisLabel(for value: Double) -> String {
        if value == 0 { return axisLabels[2] }
        if value == maxValue { return axisLabels[0] }
        return axisLabels[1]
    }

    static func make(for range: SummaryRange) -> SummaryData {
        switch range {
        case .day:
            return SummaryData(
                totalTime: "18 min",
                bars: [
                    SummaryBar(label: "Mon", value: 8),
                    SummaryBar(label: "Tue", value: 12),
                    SummaryBar(label: "Wed", value: 18),
                    SummaryBar(label: "Thu", value: 0),
                    SummaryBar(label: "Fri", value: 0),
                    SummaryBar(label: "Sat", value: 0),
                    SummaryBar(label: "Sun", value: 0)
                ],
                selectedIndex: 2,
                maxValue: 30,
                axisLabels: ["30 min", "15 min", "0 min"],
                listTitle: "Completed Today",
                activities: [
                    SummaryActivity(name: "Box Breathing", icon: "cube.fill", duration: "4 min"),
                    SummaryActivity(name: "Mirror Reflection", icon: "person.crop.square", duration: "6 min"),
                    SummaryActivity(name: "Box Breathing", icon: "cube.fill", duration: "4 min"),
                    SummaryActivity(name: "Gentle Breathing", icon: "wind", duration: "4 min")
                ]
            )
        case .week:
            return SummaryData(
                totalTime: "1 hr 25 min",
                bars: [
                    SummaryBar(label: "Week 1", value: 40),
                    SummaryBar(label: "Week 2", value: 55),
                    SummaryBar(label: "Week 3", value: 85),
                    SummaryBar(label: "Week 4", value: 0),
                    SummaryBar(label: "Week 5", value: 0)
                ],
                selectedIndex: 2,
                maxValue: 120,
                axisLabels: ["2 hours", "1 hour", "0 hour"],
                listTitle: "Completed This Week",
                activities: [
                    SummaryActivity(name: "Box Breathing", icon: "cube.fill", duration: "25 min"),
                    SummaryActivity(name: "Mirror Reflection", icon: "person.crop.square", duration: "10 min"),
                    SummaryActivity(name: "5-4-3-2-1 Grounding", icon: "5.square.fill", duration: "15 min"),
                    SummaryActivity(name: "Gentle Breathing", icon: "wind", duration: "20 min"),
                    SummaryActivity(name: "Imagery Guide", icon: "photo.on.rectangle", duration: "15 min")
                ]
            )
        case .month:
            return SummaryData(
                totalTime: "26 hr 5 min",
                bars: [
                    SummaryBar(label: "Jan", value: 14),
                    SummaryBar(label: "Feb", value: 19),
                    SummaryBar(label: "Mar", value: 26),
                    SummaryBar(label: "Apr", value: 0),
                    SummaryBar(label: "May", value: 0),
                    SummaryBar(label: "Jun", value: 0),
                    SummaryBar(label: "Jul", value: 0)
                ],
                selectedIndex: 2,
                maxValue: 40,
                axisLabels: ["40 hours", "20 hours", "0 hour"],
                listTitle: "Completed This Month",
                activities: [
                    SummaryActivity(name: "Box Breathing", icon: "cube.fill", duration: "4 hours"),
                    SummaryActivity(name: "Mirror Reflection", icon: "person.crop.square", duration: "5 hours"),
                    SummaryActivity(name: "5-4-3-2-1 Grounding", icon: "5.square.fill", duration: "7 hours"),
                    SummaryActivity(name: "Gentle Breathing", icon: "wind", duration: "5 hours"),
                    SummaryActivity(name: "Imagery Guide", icon: "photo.on.rectangle", duration: "5 hours")
                ]
            )
        }
    }
}

// MARK: - Screen

struct SummaryView: View {
    @State private var range: SummaryRange = .day

    private let screenBg    = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let darkGreen   = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    private let lightGreen  = Color(red: 201/255, green: 232/255, blue: 207/255)
    private let titleDark   = Color(red: 47/255, green: 42/255, blue: 40/255)    // #2F2A28
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)  // #6F6762

    private var data: SummaryData { SummaryData.make(for: range) }

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Range", selection: $range) {
                        ForEach(SummaryRange.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    chartCard
                    activitiesCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Total time + chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL TIME")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(subtextGray)

            Text(data.totalTime)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(titleDark)

            Chart(data.bars) { bar in
                BarMark(
                    x: .value("Period", bar.label),
                    y: .value("Time", bar.value)
                )
                .foregroundStyle(bar.label == data.selectedLabel ? darkGreen : lightGreen)
                .cornerRadius(3)
            }
            .chartYScale(domain: 0...data.maxValue)
            .chartYAxis {
                AxisMarks(position: .trailing, values: [0, data.maxValue / 2, data.maxValue]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(data.axisLabel(for: number))
                                .font(.system(size: 8))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: 130)
            .padding(.top, 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut, value: range)
    }

    // MARK: Activities

    private var activitiesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("All Activities")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(subtextGray)
                    Text(data.listTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(titleDark)
                }

                Spacer()

                Text("\(data.activities.count) Sessions")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(subtextGray)
            }
            .padding(.bottom, 12)

            ForEach(data.activities) { activity in
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: activity.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(darkGreen)
                        .frame(width: 36, height: 36)
                        .background(lightGreen, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text(activity.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(titleDark)

                    Spacer()

                    Text(activity.duration)
                        .font(.system(size: 13))
                        .foregroundColor(titleDark)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    SummaryView()
}
