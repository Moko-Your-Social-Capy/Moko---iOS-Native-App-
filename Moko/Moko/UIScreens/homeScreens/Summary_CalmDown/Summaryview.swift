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

// MARK: - Chart Scale

/// The unit used on the chart's vertical axis.
enum SummaryChartUnit: String, Equatable {
    case seconds
    case minutes
    case hours

    /// How many seconds one unit is worth.
    var secondsPerUnit: Double {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        case .hours: return 3_600
        }
    }

    /// The short word drawn after an axis number ("20 sec", "5 min", "2 hr").
    var suffix: String {
        switch self {
        case .seconds: return "sec"
        case .minutes: return "min"
        case .hours: return "hr"
        }
    }

    /// Picks the unit from the tallest bar. Short sessions get a seconds scale
    /// and long ones get an hours scale, so the bars never look almost empty.
    static func best(forPeakSeconds peak: Double) -> SummaryChartUnit {
        if peak < 120 {
            return .seconds
        }

        if peak < 3_600 {
            return .minutes
        }

        return .hours
    }

    /// Turns saved seconds into the number the chart draws.
    func value(fromSeconds seconds: Double) -> Double {
        seconds / secondsPerUnit
    }
}

/// The vertical scale of the chart: unit, top value and gridline ticks.
/// Everything comes from the tallest bar, so the graph changes shape when the
/// user logs 20 seconds instead of 3 hours.
struct SummaryChartScale: Equatable {
    let unit: SummaryChartUnit
    let maxValue: Double
    let ticks: [Double]

    init(peakSeconds: Double) {
        let unit = SummaryChartUnit.best(forPeakSeconds: peakSeconds)
        self.unit = unit

        let peak = unit.value(fromSeconds: max(0, peakSeconds))

        guard peak > 0 else {
            maxValue = 1
            ticks = [0, 1]
            return
        }

        // A little room above the tallest bar keeps it off the top gridline.
        let target = peak * 1.1
        let step = Self.step(for: target / 3, unit: unit)
        let maxValue = max(step, (target / step).rounded(.up) * step)

        self.maxValue = maxValue
        ticks = Self.makeTicks(max: maxValue, step: step)
    }

    /// Round step sizes (1, 2, 5, 10 ...) so the labels stay easy to read.
    private static func step(for raw: Double, unit: SummaryChartUnit) -> Double {
        let candidates: [Double]

        switch unit {
        case .seconds, .minutes:
            candidates = [1, 2, 5, 10, 15, 30, 60]
        case .hours:
            candidates = [1, 2, 3, 4, 6, 12, 24]
        }

        if let candidate = candidates.first(where: { $0 >= raw }) {
            return candidate
        }

        // Very large totals (for example a whole year of sessions) need a
        // bigger step, so grow the next round number by powers of ten.
        let magnitude = pow(10, floor(log10(max(raw, 1))))
        let fraction = raw / magnitude

        let niceFraction: Double

        switch fraction {
        case ...1: niceFraction = 1
        case ...2: niceFraction = 2
        case ...5: niceFraction = 5
        default: niceFraction = 10
        }

        return niceFraction * magnitude
    }

    /// Builds ticks at 0, step, 2 × step ... up to the top value.
    private static func makeTicks(max: Double, step: Double) -> [Double] {
        guard step > 0 else {
            return [0, max]
        }

        var ticks: [Double] = []
        var value = 0.0

        // The tiny tolerance stops floating-point drift from adding a fifth tick.
        while value <= max + step * 0.0001 {
            ticks.append(value)
            value += step
        }

        return ticks
    }
}

/// One bar in the chart (one hour, day, week or month).
struct SummaryBar: Identifiable {
    /// Where the bar sits on the time axis.
    let date: Date
    let label: String
    /// Time saved for this bar, in seconds. The chart converts it to the picked unit.
    let seconds: Double
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

/// A snapshot of the chart's shape. When it changes, the bars and gridlines animate.
struct SummaryChartAnimationKey: Equatable {
    let unit: SummaryChartUnit
    let maxValue: Double
    let values: [Double]
}

// MARK: - Summary Data

/// Everything the screen shows for one range, worked out from the saved sessions.
/// Plain maths only, so it is easy to test without the UI.
struct SummaryData {

    let totalText: String
    let bars: [SummaryBar]
    let chartStart: Date
    let chartEnd: Date
    /// Unit, top value and gridlines, all based on the tallest bar.
    let scale: SummaryChartScale
    /// The x-axis labels. The day chart drops some hours so the text never overlaps.
    let axisDates: [Date]
    let listTitle: String
    let sessionCount: Int
    let activities: [SummaryActivity]

    /// Short way to write `data.scale.unit` in the view.
    var unit: SummaryChartUnit { scale.unit }

    /// Top of the chart's y-axis in the picked unit.
    var maxValue: Double { scale.maxValue }

    /// Gridline values in the picked unit.
    var axisTicks: [Double] { scale.ticks }

    /// A small snapshot used to animate the chart when the numbers change.
    var animationKey: SummaryChartAnimationKey {
        SummaryChartAnimationKey(
            unit: scale.unit,
            maxValue: scale.maxValue,
            values: bars.map(\.seconds)
        )
    }

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
        chartStart = chart.start
        chartEnd = chart.end

        let peakSeconds = chart.bars.map(\.seconds).max() ?? 0
        scale = SummaryChartScale(peakSeconds: peakSeconds)
        axisDates = Self.axisDates(
            for: range,
            bars: chart.bars,
            start: chart.start,
            end: chart.end
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

    /// Draws an axis number in the chart's current unit ("30 sec", "5 min", "2 hr").
    func axisText(_ value: Double) -> String {

        if value == 0 {
            return "0"
        }

        let rounded = value.rounded()

        if abs(value - rounded) < 0.0001 {
            return "\(Int(rounded)) \(scale.unit.suffix)"
        }

        // One decimal is enough for the rare in-between value.
        return String(format: "%.1f", value) + " \(scale.unit.suffix)"
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

    /// Builds the bars for one range, and tells the chart which slice of time to draw.
    private static func makeBars(
        for range: SummaryRange,
        records: [CalmDownModel],
        calendar: Calendar,
        now: Date
    ) -> (
        bars: [SummaryBar],
        start: Date,
        end: Date
    ) {

        // Total seconds logged between two dates (all sessions, not just this range).
        func seconds(
            from start: Date,
            to end: Date
        ) -> Double {

            records
                .filter {
                    $0.date >= start && $0.date < end
                }
                .reduce(0) {
                    $0 + $1.exerciseTime
                }
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
                    seconds: seconds(
                        from: hourStart,
                        to: hourEnd
                    ),
                    isSelected: isSelected
                )
            }

            // Only draw the hours around the sessions, so the bars are not lost
            // among empty hours.
            let window = dayWindow(
                bars: bars,
                day: interval
            )

            // Keep just the bars inside the window. Every session is inside it,
            // so no saved time is hidden.
            let visibleBars = bars.filter {
                $0.date >= window.start && $0.date < window.end
            }

            return (
                visibleBars,
                window.start,
                window.end
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
                    seconds: seconds(
                        from: dayStart,
                        to: dayEnd
                    ),
                    isSelected: isSelected
                )
            }

            return (
                bars,
                interval.start,
                interval.end
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

                // Short "W1" fits under a bar; the full "Week 1" was clipping.
                let label = "W\(weekNumber)"

                let axisDate = calendar.date(
                    byAdding: .day,
                    value: 3,
                    to: cursor
                ) ?? cursor

                bars.append(
                    SummaryBar(
                        date: axisDate,
                        label: label,
                        seconds: seconds(
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
                firstWeek.start,
                cursor
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
                seconds: seconds(
                    from: monthStart,
                    to: nextMonth
                ),
                isSelected: isSelected
            )
        }

        return (
            bars,
            yearInterval.start,
            yearInterval.end
        )
    }

    // MARK: Focus The Day Chart

    /// Picks the part of the day the chart should draw. It covers every hour
    /// with a session, one hour of breathing room on each side, and never less
    /// than four hours. Empty days show the whole day.
    private static func dayWindow(
        bars: [SummaryBar],
        day: DateInterval
    ) -> (start: Date, end: Date) {

        // The Day chart groups sessions into one-hour bars, so a bar is one hour wide.
        let hour: TimeInterval = 60 * 60

        // Four hours stops one short session from looking like a thin needle.
        // A clock-change day can be shorter, so never ask for more than one day.
        let minimumWindow = min(4 * hour, day.duration)

        // Hours that hold saved time.
        let activeBars = bars.filter { $0.seconds > 0 }
        let activeDates = activeBars.map(\.date)

        guard let firstActive = activeDates.min(),
              let lastActive = activeDates.max() else {
            // Nothing saved: there is no chart to draw, so show the whole day.
            return (day.start, day.end)
        }

        // The last active bar covers its own full hour.
        let dataEnd = min(lastActive + hour, day.end)

        // One empty hour on each side keeps the bars away from the card edges.
        var start = firstActive - hour
        var end = dataEnd + hour

        // Some days do not have four hours of data, so grow the window evenly.
        let span = end.timeIntervalSince(start)
        if span < minimumWindow {
            let extra = (minimumWindow - span) / 2
            start -= extra
            end += extra
        }

        // Keep the window inside the day. When one side hits midnight, move the
        // extra room to the other side so the window keeps its length.
        if start < day.start {
            end += day.start.timeIntervalSince(start)
            start = day.start
        }

        if end > day.end {
            start -= end.timeIntervalSince(day.end)
            end = day.end
        }

        start = max(start, day.start)
        end = min(end, day.end)

        // Half an hour of blank space beside the first and last bar stops the
        // chart edge from cutting a bar in half.
        let edgeRoom = hour / 2

        return (
            max(day.start, start - edgeRoom),
            min(day.end, end + edgeRoom)
        )
    }

    // MARK: X-Axis Labels

    /// The dates that get a label under the chart. The day view thins them out
    /// when many hours are visible, and the year view skips every other month,
    /// so the labels never overlap.
    private static func axisDates(
        for range: SummaryRange,
        bars: [SummaryBar],
        start: Date,
        end: Date
    ) -> [Date] {

        guard range == .day else {

            guard range == .year else {
                return bars.map(\.date)
            }

            // Twelve month names are too wide for a phone, so show six.
            return bars.enumerated().compactMap { index, bar in
                index.isMultiple(of: 2) ? bar.date : nil
            }
        }

        let visibleHours = max(end.timeIntervalSince(start) / 3_600, 1)
        let labelStride = max(1, Int((visibleHours / 6).rounded(.up)))

        // Labels need room on both sides, or the chart clips the first and last
        // one. Twenty minutes is about the width of a short hour label.
        let edgeGap: TimeInterval = 20 * 60

        return bars.enumerated().compactMap { index, bar in

            guard index.isMultiple(of: labelStride) else {
                return nil
            }

            let before = bar.date.timeIntervalSince(start)
            let after = end.timeIntervalSince(bar.date)

            return before >= edgeGap && after >= edgeGap ? bar.date : nil
        }
    }

    // MARK: Duration Formatting

    static func durationText(
        _ seconds: TimeInterval
    ) -> String {

        let totalSeconds = Int(max(0, seconds).rounded())

        if totalSeconds < 60 {
            return "\(totalSeconds) sec"
        }

        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return minutes == 0
                ? "\(hours) hr"
                : "\(hours) hr \(minutes) min"
        }

        if remainingSeconds == 0 {
            return "\(minutes) min"
        }

        // A short minute count keeps its seconds ("1 min 30 sec"), so it never lies.
        if minutes == 0 {
            return "\(remainingSeconds) sec"
        }

        return "\(minutes) min \(remainingSeconds) sec"
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

    // The phone's "Reduce Motion" setting. When on, the chart changes without sliding.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                // When the total changes, the number rolls to its new value.
                .contentTransition(.numericText())
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.35),
                    value: data.totalText
                )

            Chart(data.bars) { bar in

                // Saved seconds are turned into the chart's current unit
                // (seconds, minutes or hours), so a 20-second session and a
                // 3-hour session both get readable bars.
                BarMark(
                    x: .value("Period", bar.date),
                    y: .value("Time", data.unit.value(fromSeconds: bar.seconds))
                )
                .foregroundStyle(
                    bar.isSelected ? accent : MokoScreenTheme.Colors.dataViolet
                )
                .cornerRadius(4)
            }
            // The day chart shows only the hours that hold sessions, so its bars
            // fill the card. The other ranges show their whole period.
            .chartXScale(
                domain: data.chartStart...data.chartEnd
            )
            // The top of the chart comes from the tallest bar, so the bars always
            // use the full height instead of sitting on a fixed minute ceiling.
            .chartYScale(
                domain: 0...data.maxValue
            )
            .chartYAxis {

                // Gridlines and labels use the same seconds / minutes / hours scale.
                AxisMarks(
                    position: .trailing,
                    values: data.axisTicks
                ) { value in

                    AxisGridLine()
                        .foregroundStyle(MokoScreenTheme.Colors.dataGrid)

                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(data.axisText(number))
                                .mokoText(MokoScreenTheme.Typeface.caption)
                        }
                    }
                }
            }
            // One label per bar, using the bar's own text ("9 AM", "Mon", "W2", "Jan").
            // The day chart thins the hours and the year chart skips every other month.
            .chartXAxis {

                AxisMarks(
                    preset: .aligned,
                    values: data.axisDates
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

                            // Short labels stay centred under their bar instead of clipping.
                            Text(bar.label)
                                .mokoText(MokoScreenTheme.Typeface.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(subtextGray)
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(.top, 12)
            // Bars slide to their new height when a session arrives or the range changes.
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.45),
                value: data.animationKey
            )
            .accessibilityLabel("Calm down chart")
            .accessibilityValue("\(data.totalText) in this period")
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
