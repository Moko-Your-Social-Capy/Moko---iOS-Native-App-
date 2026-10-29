//
//  SummaryView.swift
//  Moko
//
//  Summary screen: segmented Day / Week / Month picker, Apple Charts bar chart
//  and activity list. Everything comes from the CalmDownModel records saved in
//  SwiftData when a calm down exercise finishes. No records = empty message.
//

import SwiftUI
import SwiftData
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
    let minutes: Double
}

struct SummaryActivity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String           // SF Symbol
    let duration: String
}

/// Everything the screen shows for one range, built from the saved records.
struct SummaryData {
    let totalText: String
    let bars: [SummaryBar]
    let selectedLabel: String
    let maxMinutes: Double
    let listTitle: String
    let sessionCount: Int
    let activities: [SummaryActivity]

    var isEmpty: Bool { sessionCount == 0 }

    init(range: SummaryRange, records: [CalmDownModel], now: Date = Date()) {
        let calendar = Calendar.current

        // Records that belong to today / this week / this month
        let interval = calendar.dateInterval(of: Self.component(for: range), for: now)
        let inRange = records.filter { interval?.contains($0.date) ?? false }

        sessionCount = inRange.count
        totalText = Self.durationText(inRange.reduce(0) { $0 + $1.exerciseTime })

        let chart = Self.makeBars(for: range, records: records, calendar: calendar, now: now)
        bars = chart.bars
        selectedLabel = chart.selected
        maxMinutes = Self.niceMax(chart.bars.map(\.minutes).max() ?? 0)

        switch range {
        case .day:
            listTitle = "Completed Today"
            // Every session, newest first
            activities = inRange
                .sorted { $0.date > $1.date }
                .map { SummaryActivity(name: $0.exerciseTitle,
                                       icon: Self.icon(for: $0.exerciseTitle),
                                       duration: Self.durationText($0.exerciseTime)) }
        case .week, .month:
            listTitle = range == .week ? "Completed This Week" : "Completed This Month"
            // One row per exercise with its total time, longest first
            let totals = Dictionary(grouping: inRange, by: \.exerciseTitle)
                .mapValues { $0.reduce(0) { $0 + $1.exerciseTime } }
            activities = totals
                .sorted { $0.value > $1.value }
                .map { SummaryActivity(name: $0.key,
                                       icon: Self.icon(for: $0.key),
                                       duration: Self.durationText($0.value)) }
        }
    }

    /// Text for the y-axis marks (minutes up to 1 hour, hours above that)
    func axisText(_ minutes: Double) -> String {
        if maxMinutes > 60 {
            return minutes == 0 ? "0 hr" : "\((minutes / 60).formatted()) hr"
        }
        return "\(Int(minutes)) min"
    }

    // MARK: Helpers

    private static func component(for range: SummaryRange) -> Calendar.Component {
        switch range {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        }
    }

    /// Bars: Day = days of this week, Week = weeks of this month, Month = months of this year.
    private static func makeBars(for range: SummaryRange,
                                 records: [CalmDownModel],
                                 calendar: Calendar,
                                 now: Date) -> (bars: [SummaryBar], selected: String) {
        func minutes(_ matching: (CalmDownModel) -> Bool) -> Double {
            records.filter(matching).reduce(0) { $0 + $1.exerciseTime } / 60
        }

        switch range {
        case .day:
            guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return ([], "") }
            let bars = (0..<7).compactMap { offset -> SummaryBar? in
                guard let day = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
                return SummaryBar(label: day.formatted(.dateTime.weekday(.abbreviated)),
                                  minutes: minutes { calendar.isDate($0.date, inSameDayAs: day) })
            }
            return (bars, now.formatted(.dateTime.weekday(.abbreviated)))

        case .week:
            guard let month = calendar.dateInterval(of: .month, for: now),
                  let weeks = calendar.range(of: .weekOfMonth, in: .month, for: now) else { return ([], "") }
            let bars = weeks.map { week in
                SummaryBar(label: "Week \(week)",
                           minutes: minutes { month.contains($0.date)
                               && calendar.component(.weekOfMonth, from: $0.date) == week })
            }
            return (bars, "Week \(calendar.component(.weekOfMonth, from: now))")

        case .month:
            let year = calendar.component(.year, from: now)
            let names = calendar.shortMonthSymbols
            let bars = (1...12).map { month in
                SummaryBar(label: names[month - 1],
                           minutes: minutes { calendar.component(.year, from: $0.date) == year
                               && calendar.component(.month, from: $0.date) == month })
            }
            return (bars, names[calendar.component(.month, from: now) - 1])
        }
    }

    /// A tidy top value for the y-axis so the middle mark is a round number.
    private static func niceMax(_ peak: Double) -> Double {
        if peak <= 30 { return 30 }
        if peak <= 60 { return 60 }
        let hours = ceil(peak / 60)
        let evenHours = hours.truncatingRemainder(dividingBy: 2) == 0 ? hours : hours + 1
        return evenHours * 60
    }

    /// "45 sec", "18 min", "2 hr", "1 hr 25 min"
    static func durationText(_ seconds: TimeInterval) -> String {
        if seconds > 0 && seconds < 60 { return "\(Int(seconds)) sec" }

        let totalMinutes = Int((seconds / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 { return "\(minutes) min" }
        if minutes == 0 { return "\(hours) hr" }
        return "\(hours) hr \(minutes) min"
    }

    private static func icon(for title: String) -> String {
        switch title {
        case "Box Breathing":     return "cube.fill"
        case "Mirror Reflection": return "person.crop.square"
        case "Gentle Breathing":  return "wind"
        case "Imagery Guide":     return "photo.on.rectangle"
        case "Grounding Exercise": return "hand.raised.fill"   // must match the title logged by GroundingExerciseScreen
        default:                  return "leaf.fill"
        }
    }
}

// MARK: - Screen

struct SummaryView: View {
    /// Every finished exercise, newest first. The selected range is filtered in SummaryData.
    @Query(sort: \CalmDownModel.date, order: .reverse) private var records: [CalmDownModel]

    @State private var range: SummaryRange = .day

    private let screenBg    = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let darkGreen   = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    private let lightGreen  = Color(red: 201/255, green: 232/255, blue: 207/255)
    private let titleDark   = Color(red: 47/255, green: 42/255, blue: 40/255)    // #2F2A28
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)  // #6F6762

    var body: some View {
        let data = SummaryData(range: range, records: records)

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

                    if data.isEmpty {
                        emptyCard
                    } else {
                        chartCard(data)
                        activitiesCard(data)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.large)
        .animation(.easeInOut, value: range)
    }

    // MARK: Empty state

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 36))
                .foregroundColor(darkGreen)
                .frame(width: 80, height: 80)
                .background(lightGreen, in: Circle())

            Text("No exercise logged yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(titleDark)

            Text("Try some calm down exercises. The time you spend on each one shows up here.")
                .font(.system(size: 15))
                .foregroundColor(subtextGray)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Total time + chart

    private func chartCard(_ data: SummaryData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL TIME")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(subtextGray)

            Text(data.totalText)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(titleDark)

            Chart(data.bars) { bar in
                BarMark(
                    x: .value("Period", bar.label),
                    y: .value("Minutes", bar.minutes)
                )
                .foregroundStyle(bar.label == data.selectedLabel ? darkGreen : lightGreen)
                .cornerRadius(3)
            }
            .chartYScale(domain: 0...data.maxMinutes)
            .chartYAxis {
                AxisMarks(position: .trailing, values: [0, data.maxMinutes / 2, data.maxMinutes]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text(data.axisText(minutes))
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
    }

    // MARK: Activities

    private func activitiesCard(_ data: SummaryData) -> some View {
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

                Text("\(data.sessionCount) \(data.sessionCount == 1 ? "Session" : "Sessions")")
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

// MARK: - Previews

#Preview("Empty (default)") {
    NavigationStack { SummaryView() }
        .modelContainer(for: CalmDownModel.self, inMemory: true)
}

#Preview("With sessions") {
    let container = try! ModelContainer(
        for: CalmDownModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let samples: [(String, TimeInterval)] = [
        ("Box Breathing", 240),
        ("Mirror Reflection", 120),
        ("Gentle Breathing", 300),
        ("Imagery Guide", 120),
        ("Grounding Exercise", 180)
    ]
    for (title, seconds) in samples {
        container.mainContext.insert(CalmDownModel(exerciseTitle: title, exerciseTime: seconds, date: Date()))
    }

    return NavigationStack { SummaryView() }
        .modelContainer(container)
}
