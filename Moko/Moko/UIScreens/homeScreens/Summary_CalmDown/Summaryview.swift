//
//  Summaryview.swift
//  Moko
//
//  The Calm Down summary: total relax time and a bar chart for the chosen
//  Day / Week / Month / Year, plus a list of the exercises done in that period.
//
//  Flow: `@Query` reads every saved `CalmDownModel` → `SummaryData` does all the
//  maths (no UI) → `SummaryView` only draws it.
//  Debug tip: create sample sessions with the "With Sessions" preview at the bottom.
//

import SwiftUI
import SwiftData
import Charts
import Lottie

// MARK: - Model

/// The segmented control options at the top of the screen.
enum SummaryRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

/// One bar in the chart (one hour, day, week or month).
struct SummaryBar: Identifiable {
    /// Where the bar sits on the time axis.
    let date: Date
    let label: String
    let minutes: Double
    /// True for the current hour/day/week/month. Drawn in the darker colour.
    let isSelected: Bool

    var id: Date { date }
}

/// One row in the "All Activities" list.
struct SummaryActivity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let duration: String
}

// MARK: - Summary Data

/// Everything the screen shows for one range, worked out from the saved sessions.
/// Plain maths only, so it is easy to test without the UI.
struct SummaryData {

    let totalText: String
    let bars: [SummaryBar]
    let selectedDate: Date
    let chartStart: Date
    let chartEnd: Date
    /// How much time fits on screen before the chart scrolls sideways.
    let visibleDuration: TimeInterval
    /// Top of the chart's y-axis.
    let maxMinutes: Double
    let listTitle: String
    let sessionCount: Int
    let activities: [SummaryActivity]

    var isEmpty: Bool {
        sessionCount == 0
    }

    init(
        range: SummaryRange,
        records: [CalmDownModel],
        now: Date = Date()
    ) {
        var calendar = Calendar.current

        // Monday is the first day of the week.
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4

        let interval = Self.period(Self.component(for: range), containing: now, in: calendar)

        // Only the sessions inside today / this week / this month / this year.
        let inRange = records.filter {
            interval.contains($0.date)
        }

        sessionCount = inRange.count

        totalText = Self.durationText(
            inRange.reduce(0) {
                $0 + $1.exerciseTime
            }
        )

        let chart = Self.makeBars(
            for: range,
            records: records,
            calendar: calendar,
            now: now
        )

        bars = chart.bars
        selectedDate = chart.selectedDate
        chartStart = chart.start
        chartEnd = chart.end
        visibleDuration = chart.visibleDuration

        maxMinutes = Self.niceMax(
            chart.bars.map(\.minutes).max() ?? 0
        )

        listTitle = Self.listTitle(for: range)

        switch range {

        case .day:
            // Today: one row per session, newest first.
            activities = inRange
                .sorted { $0.date > $1.date }
                .map {
                    SummaryActivity(
                        name: $0.exerciseTitle,
                        icon: Self.icon(for: $0.exerciseTitle),
                        duration: Self.durationText($0.exerciseTime)
                    )
                }

        case .week, .month, .year:
            // Longer ranges: one row per exercise, with its time added up.
            let totals = Dictionary(
                grouping: inRange,
                by: \.exerciseTitle
            )
            .mapValues {
                $0.reduce(0) {
                    $0 + $1.exerciseTime
                }
            }

            activities = totals
                .sorted {
                    $0.value > $1.value
                }
                .map {
                    SummaryActivity(
                        name: $0.key,
                        icon: Self.icon(for: $0.key),
                        duration: Self.durationText($0.value)
                    )
                }
        }
    }

    // MARK: Chart Axis Text

    func axisText(_ minutes: Double) -> String {

        if minutes == 0 {
            return "0"
        }

        // Minutes stay readable up to two hours of logged time, then the axis switches to hours.
        guard maxMinutes >= 120 else {
            return "\(Int(minutes.rounded())) min"
        }

        let hours = minutes / 60

        if hours == hours.rounded() {
            return "\(Int(hours)) hr"
        }

        // One decimal, rounded away from the half-way ties (1.25 hr reads better as 1.3).
        let tenths = (hours * 10).rounded() / 10

        return String(format: "%.1f hr", tenths)
    }

    // MARK: Helpers

    private static func listTitle(for range: SummaryRange) -> String {
        switch range {
        case .day:   return "Completed Today"
        case .week:  return "Completed This Week"
        case .month: return "Completed This Month"
        case .year:  return "Completed This Year"
        }
    }

    /// The whole day / week / month / year that contains `date`.
    /// `dateInterval` can return nil in theory, so this falls back to that single day
    /// instead of force unwrapping (`!`) and crashing.
    private static func period(
        _ component: Calendar.Component,
        containing date: Date,
        in calendar: Calendar
    ) -> DateInterval {
        calendar.dateInterval(of: component, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 24 * 60 * 60)
    }

    private static func component(
        for range: SummaryRange
    ) -> Calendar.Component {

        switch range {
        case .day:
            return .day

        case .week:
            return .weekOfYear

        case .month:
            return .month

        case .year:
            return .year
        }
    }

    // MARK: Generate Chart Bars

    /// Builds the bars for one range, and tells the chart where to start, end and scroll to.
    private static func makeBars(
        for range: SummaryRange,
        records: [CalmDownModel],
        calendar: Calendar,
        now: Date
    ) -> (
        bars: [SummaryBar],
        selectedDate: Date,
        start: Date,
        end: Date,
        visibleDuration: TimeInterval
    ) {

        // Total minutes logged between two dates (all sessions, not just this range).
        func minutes(
            from start: Date,
            to end: Date
        ) -> Double {

            records
                .filter {
                    $0.date >= start && $0.date < end
                }
                .reduce(0) {
                    $0 + $1.exerciseTime
                } / 60
        }

        // MARK: DAY - 24 Hourly Bars

        if range == .day {

            let interval = period(.day, containing: now, in: calendar)

            let bars = (0..<24).compactMap { hour -> SummaryBar? in

                guard let hourStart = calendar.date(
                    byAdding: .hour,
                    value: hour,
                    to: interval.start
                ),
                let hourEnd = calendar.date(
                    byAdding: .hour,
                    value: 1,
                    to: hourStart
                ) else {
                    return nil
                }

                let isSelected = calendar.component(
                    .hour,
                    from: now
                ) == hour

                let label = hourStart.formatted(
                    .dateTime.hour(.defaultDigits(amPM: .abbreviated))
                )

                return SummaryBar(
                    date: hourStart,
                    label: label,
                    minutes: minutes(
                        from: hourStart,
                        to: hourEnd
                    ),
                    isSelected: isSelected
                )
            }

            let selectedHour = calendar.date(
                bySetting: .minute,
                value: 0,
                of: now
            ) ?? now

            return (
                bars,
                selectedHour,
                interval.start,
                interval.end,
                6 * 60 * 60
            )
        }

        // MARK: WEEK - Monday to Sunday

        if range == .week {

            let interval = period(.weekOfYear, containing: now, in: calendar)

            let bars = (0..<7).compactMap { offset -> SummaryBar? in

                guard let dayStart = calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: interval.start
                ),
                let dayEnd = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: dayStart
                ) else {
                    return nil
                }

                let isSelected = calendar.isDate(
                    dayStart,
                    inSameDayAs: now
                )

                // Short weekday name (e.g. Mon, Tue, Wed).
                let label = dayStart.formatted(
                    .dateTime.weekday(.abbreviated)
                )

                return SummaryBar(
                    date: dayStart,
                    label: label,
                    minutes: minutes(
                        from: dayStart,
                        to: dayEnd
                    ),
                    isSelected: isSelected
                )
            }

            let selectedDay = calendar.startOfDay(for: now)

            return (
                bars,
                selectedDay,
                interval.start,
                interval.end,
                5 * 24 * 60 * 60
            )
        }

        // MARK: MONTH - Week 1, Week 2, Week 3...

        if range == .month {

            let monthInterval = period(.month, containing: now, in: calendar)
            // The week the month starts in (it may begin in the previous month).
            let firstWeek = period(.weekOfYear, containing: monthInterval.start, in: calendar)

            var cursor = firstWeek.start
            var weekNumber = 1

            var bars: [SummaryBar] = []
            var selectedDate = cursor

            while cursor < monthInterval.end {

                guard let nextWeek = calendar.date(
                    byAdding: .weekOfYear,
                    value: 1,
                    to: cursor
                ) else {
                    break
                }

                // Only count sessions inside the selected month.
                let effectiveStart = max(
                    cursor,
                    monthInterval.start
                )

                let effectiveEnd = min(
                    nextWeek,
                    monthInterval.end
                )

                let isSelected = now >= effectiveStart
                    && now < effectiveEnd

                let label = "Week \(weekNumber)"

                let axisDate = calendar.date(
                    byAdding: .day,
                    value: 3,
                    to: cursor
                ) ?? cursor

                if isSelected {
                    selectedDate = axisDate
                }

                bars.append(
                    SummaryBar(
                        date: axisDate,
                        label: label,
                        minutes: minutes(
                            from: effectiveStart,
                            to: effectiveEnd
                        ),
                        isSelected: isSelected
                    )
                )

                cursor = nextWeek
                weekNumber += 1
            }

            return (
                bars,
                selectedDate,
                firstWeek.start,
                cursor,
                5 * 7 * 24 * 60 * 60
            )
        }

        // MARK: YEAR - January to December

        let yearInterval = period(.year, containing: now, in: calendar)

        let bars = (1...12).compactMap { month -> SummaryBar? in

            guard let monthStart = calendar.date(
                from: DateComponents(
                    year: calendar.component(.year, from: now),
                    month: month,
                    day: 1
                )
            ),
            let nextMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: monthStart
            ) else {
                return nil
            }

            let isSelected = calendar.component(
                .month,
                from: now
            ) == month

            let label = monthStart.formatted(
                .dateTime.month(.abbreviated)
            )

            // Position the month label near the middle of the month.
            let axisDate = calendar.date(
                byAdding: .day,
                value: 14,
                to: monthStart
            ) ?? monthStart

            return SummaryBar(
                date: axisDate,
                label: label,
                minutes: minutes(
                    from: monthStart,
                    to: nextMonth
                ),
                isSelected: isSelected
            )
        }

        // Scroll the chart to this month's bar.
        let selectedMonth = bars.first(where: \.isSelected)?.date ?? yearInterval.start

        return (
            bars,
            selectedMonth,
            yearInterval.start,
            yearInterval.end,
            6 * 30.5 * 24 * 60 * 60
        )
    }

    // MARK: Maximum Chart Value

    /// The chart's top value, derived from the tallest bar so the graph grows and shrinks with the
    /// time actually logged instead of sitting on a fixed 30/60 minute ceiling.
    private static func niceMax(_ peak: Double) -> Double {

        guard peak > 0 else {
            return 10
        }

        // A little headroom keeps the tallest bar off the top gridline.
        let raw = peak * 1.2

        let magnitude = pow(10, floor(log10(raw)))
        let fraction = raw / magnitude

        let step: Double

        switch fraction {

        case ..<1.5:
            step = 1.5

        case ..<2:
            step = 2

        case ..<2.5:
            step = 2.5

        case ..<3:
            step = 3

        case ..<4:
            step = 4

        case ..<5:
            step = 5

        case ..<6:
            step = 6

        case ..<8:
            step = 8

        default:
            step = 10
        }

        // Never below two minutes, so the three gridline labels stay distinct.
        return max(2, step * magnitude)
    }

    // MARK: Duration Formatting

    static func durationText(
        _ seconds: TimeInterval
    ) -> String {

        if seconds > 0 && seconds < 60 {
            return "\(Int(seconds)) sec"
        }

        let totalMinutes = Int((seconds / 60).rounded())

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes) min"
        }

        if minutes == 0 {
            return "\(hours) hr"
        }

        return "\(hours) hr \(minutes) min"
    }

    // MARK: Exercise Icons

    private static func icon(for title: String) -> String {

        switch title {

        case "Box Breathing":
            return "cube.fill"

        case "Mirror Reflection":
            return "person.crop.square"

        case "Gentle Breathing":
            return "wind"

        case "Imagery Guide":
            return "photo.on.rectangle"

        case "Grounding Exercise":
            return "hand.raised.fill"

        default:
            return "leaf.fill"
        }
    }
}

// MARK: - Screen

struct SummaryView: View {

    // `@Query` reads every saved calm-down session from SwiftData and redraws
    // this screen automatically when a new one is saved.
    @Query(sort: \CalmDownModel.date, order: .reverse)
    private var records: [CalmDownModel]

    // Which segment is picked: Day, Week, Month or Year.
    @State private var range: SummaryRange = .day

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let soft = MokoScreenTheme.Colors.surfaceLavender
    private let titleDark = MokoScreenTheme.Colors.textTitle
    private let subtextGray = MokoScreenTheme.Colors.textBody

    // MARK: Body

    var body: some View {

        // Recalculated on every redraw. Cheap, because it is only simple maths.
        let data = SummaryData(
            range: range,
            records: records
        )

        ZStack {

            MokoBackdrop()

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    // Day / Week / Month / Year
                    Picker("Range", selection: $range) {

                        ForEach(SummaryRange.allCases) { item in
                            Text(item.rawValue)
                                .tag(item)
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
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Calm Down")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(MokoScreenTheme.Colors.dataVioletDeep)
        // Smoothly changes the chart when another range is picked.
        .animation(.easeInOut, value: range)
    }

    // MARK: Empty State

    private var emptyCard: some View {

        VStack(spacing: 16) {

            // Use Lottie empty animation instead of SF Symbol
            MokoLottieView(animation: .empty, loopMode: .loop)
                .frame(width: 100, height: 100)
                .accessibilityHidden(true)

            Text("No exercise logged yet")
                .mokoText(MokoScreenTheme.Typeface.section)
                .foregroundStyle(titleDark)

            Text(
                "Try some calm down exercises. The time you spend on each one shows up here."
            )
            .mokoText(MokoScreenTheme.Typeface.body)
            .foregroundStyle(subtextGray)
            .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .mokoCard()
    }

    // MARK: Total Time + Chart

    private func chartCard(
        _ data: SummaryData
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {

            Text("Total time")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(subtextGray)

            Text(data.totalText)
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(MokoScreenTheme.Colors.dataNumeral)

            Chart(data.bars) { bar in

                BarMark(
                    x: .value("Period", bar.date),
                    y: .value("Minutes", bar.minutes)
                )
                .foregroundStyle(
                    bar.isSelected ? accent : MokoScreenTheme.Colors.dataViolet
                )
                .cornerRadius(4)
            }
            // The chart scrolls sideways and opens on the current hour/day/week/month.
            .chartXScale(
                domain: data.chartStart...data.chartEnd
            )
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(
                length: data.visibleDuration
            )
            .chartScrollPosition(
                initialX: data.selectedDate
            )
            .chartYScale(
                domain: 0...data.maxMinutes
            )
            .chartYAxis {

                AxisMarks(
                    position: .trailing,
                    values: [
                        0,
                        data.maxMinutes / 2,
                        data.maxMinutes
                    ]
                ) { value in

                    AxisGridLine()
                        .foregroundStyle(MokoScreenTheme.Colors.dataGrid)

                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text(data.axisText(minutes))
                                .mokoText(MokoScreenTheme.Typeface.caption)
                        }
                    }
                }
            }
            // One label per bar, using the bar's own text ("9 AM", "Mon", "Week 2", "Jan").
            .chartXAxis {

                AxisMarks(
                    values: data.bars.map(\.date)
                ) { value in

                    AxisValueLabel {

                        if let date = value.as(Date.self),
                           let bar = data.bars.first(
                               where: {
                                   abs(
                                       $0.date.timeIntervalSince(date)
                                   ) < 1
                               }
                           ) {

                            Text(bar.label)
                                .mokoText(MokoScreenTheme.Typeface.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(subtextGray)
                        }
                    }
                }
            }
            .frame(height: 150)
            .padding(.top, 12)
        }
        .padding(MokoScreenTheme.Space.cardHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mokoCard()
    }

    // MARK: Activities

    private func activitiesCard(
        _ data: SummaryData
    ) -> some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .top) {

                VStack(alignment: .leading, spacing: 2) {

                    Text("All Activities")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(subtextGray)

                    Text(data.listTitle)
                        .mokoText(MokoScreenTheme.Typeface.slider)
                        .foregroundStyle(titleDark)
                }

                Spacer()

                Text(
                    "\(data.sessionCount) \(data.sessionCount == 1 ? "Session" : "Sessions")"
                )
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(subtextGray)
            }
            .padding(.bottom, 12)

            ForEach(data.activities) { activity in

                Divider()

                HStack(spacing: 12) {

                    Image(systemName: activity.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 36, height: 36)
                        .background(
                            soft,
                            in: RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )

                    Text(activity.name)
                        .mokoText(MokoScreenTheme.Typeface.slider)
                        .foregroundStyle(titleDark)

                    Spacer()

                    Text(activity.duration)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(titleDark)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(MokoScreenTheme.Space.cardHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mokoCard()
    }
}

// MARK: - Previews

#Preview("Empty") {
    NavigationStack {
        SummaryView()
    }
    .modelContainer(
        for: CalmDownModel.self,
        inMemory: true
    )
}

#Preview("With Sessions") {
    // An in-memory database, so preview data never touches the real app data.
    guard let container = try? ModelContainer(
        for: CalmDownModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return Text("Preview database could not be created")
    }

    let calendar = Calendar.current

    let samples: [(String, TimeInterval, Int)] = [
        ("Box Breathing", 240, 0),
        ("Mirror Reflection", 120, 0),
        ("Gentle Breathing", 300, 1),
        ("Imagery Guide", 120, 3),
        ("Grounding Exercise", 180, 10)
    ]

    for (title, seconds, daysAgo) in samples {

        let date = calendar.date(
            byAdding: .day,
            value: -daysAgo,
            to: Date()
        ) ?? Date()

        container.mainContext.insert(
            CalmDownModel(
                exerciseTitle: title,
                exerciseTime: seconds,
                date: date
            )
        )
    }

    return NavigationStack {
        SummaryView()
    }
    .modelContainer(container)
}
