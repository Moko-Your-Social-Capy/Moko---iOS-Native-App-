
import SwiftUI
import SwiftData
import Charts

// MARK: - Model

enum SummaryRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

struct SummaryBar: Identifiable {
    let date: Date
    let label: String
    let minutes: Double
    let isSelected: Bool

    var id: Date { date }
}

struct SummaryActivity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let duration: String
}

// MARK: - Summary Data

struct SummaryData {

    let totalText: String
    let bars: [SummaryBar]
    let selectedDate: Date
    let chartStart: Date
    let chartEnd: Date
    let visibleDuration: TimeInterval
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

        let interval = calendar.dateInterval(
            of: Self.component(for: range),
            for: now
        ) ?? DateInterval(
            start: now,
            duration: 86400
        )

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

        switch range {

        case .day:
            listTitle = "Completed Today"

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

            switch range {
            case .week:
                listTitle = "Completed This Week"

            case .month:
                listTitle = "Completed This Month"

            case .year:
                listTitle = "Completed This Year"

            case .day:
                listTitle = "Completed Today"
            }

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
        if maxMinutes > 60 {
            return minutes == 0
                ? "0 hr"
                : "\(Int((minutes / 60).rounded())) hr"
        }

        return "\(Int(minutes)) min"
    }

    // MARK: Helpers

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

            let interval = calendar.dateInterval(
                of: .day,
                for: now
            )!

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

            let interval = calendar.dateInterval(
                of: .weekOfYear,
                for: now
            )!

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

                let label = dayStart.formatted(
                    .dateTime.weekday(.wide)
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

            let monthInterval = calendar.dateInterval(
                of: .month,
                for: now
            )!

            let firstWeek = calendar.dateInterval(
                of: .weekOfYear,
                for: monthInterval.start
            )!

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

        let yearInterval = calendar.dateInterval(
            of: .year,
            for: now
        )!

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

        let selectedMonth = calendar.date(
            byAdding: .day,
            value: 14,
            to: calendar.date(
                from: DateComponents(
                    year: calendar.component(.year, from: now),
                    month: calendar.component(.month, from: now),
                    day: 1
                )
            )!
        )!

        return (
            bars,
            selectedMonth,
            yearInterval.start,
            yearInterval.end,
            6 * 30.5 * 24 * 60 * 60
        )
    }

    // MARK: Maximum Chart Value

    private static func niceMax(_ peak: Double) -> Double {

        if peak <= 30 {
            return 30
        }

        if peak <= 60 {
            return 60
        }

        let hours = ceil(peak / 60)

        let evenHours =
            hours.truncatingRemainder(dividingBy: 2) == 0
            ? hours
            : hours + 1

        return evenHours * 60
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

    @Query(sort: \CalmDownModel.date, order: .reverse)
    private var records: [CalmDownModel]

    @State private var range: SummaryRange = .day

    private let darkGreen = MocoScreenTheme.Colors.dataVioletDeep

    private let lightGreen = MocoScreenTheme.Colors.surfaceLavender

    private let titleDark = MocoScreenTheme.Colors.textTitle

    private let subtextGray = MocoScreenTheme.Colors.textBody

    // MARK: Body

    var body: some View {

        let data = SummaryData(
            range: range,
            records: records
        )

        ZStack {

            MocoBackdrop()

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
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Calm Down")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(MocoScreenTheme.Colors.dataVioletDeep)
        .animation(.easeInOut, value: range)
    }

    // MARK: Empty State

    private var emptyCard: some View {

        VStack(spacing: 12) {

            Image(systemName: "leaf.fill")
                .font(.system(size: 36))
                .foregroundStyle(darkGreen)
                .frame(width: 80, height: 80)
                .background(lightGreen, in: Circle())

            Text("No exercise logged yet")
                .mocoText(MocoScreenTheme.Typeface.section)
                .foregroundStyle(titleDark)

            Text(
                "Try some calm down exercises. The time you spend on each one shows up here."
            )
            .mocoText(MocoScreenTheme.Typeface.body)
            .foregroundStyle(subtextGray)
            .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .mocoCard()
    }

    // MARK: Total Time + Chart

    private func chartCard(
        _ data: SummaryData
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {

            Text("Total time")
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundStyle(subtextGray)

            Text(data.totalText)
                .mocoText(MocoScreenTheme.Typeface.title1)
                .foregroundStyle(MocoScreenTheme.Colors.dataNumeral)

            Chart(data.bars) { bar in

                BarMark(
                    x: .value("Period", bar.date),
                    y: .value("Minutes", bar.minutes)
                )
                .foregroundStyle(
                    bar.isSelected ? darkGreen : MocoScreenTheme.Colors.dataViolet
                )
                .cornerRadius(4)
            }
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
                        .foregroundStyle(MocoScreenTheme.Colors.dataGrid)

                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text(data.axisText(minutes))
                                .mocoText(MocoScreenTheme.Typeface.caption)
                        }
                    }
                }
            }
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
                                .mocoText(MocoScreenTheme.Typeface.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(subtextGray)
                        }
                    }
                }
            }
            .frame(height: 150)
            .padding(.top, 12)

            Text(chartHint)
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundStyle(subtextGray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(MocoScreenTheme.Space.cardHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mocoCard()
    }

    // MARK: Chart Hint

    private var chartHint: String {

        switch range {

        case .day:
            return "Swipe horizontally to explore the hours"

        case .week:
            return "Swipe horizontally to explore the week"

        case .month:
            return "Swipe horizontally to explore the weeks"

        case .year:
            return "Swipe horizontally to explore the months"
        }
    }

    // MARK: Activities

    private func activitiesCard(
        _ data: SummaryData
    ) -> some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .top) {

                VStack(alignment: .leading, spacing: 2) {

                    Text("All Activities")
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundStyle(subtextGray)

                    Text(data.listTitle)
                        .mocoText(MocoScreenTheme.Typeface.slider)
                        .foregroundStyle(titleDark)
                }

                Spacer()

                Text(
                    "\(data.sessionCount) \(data.sessionCount == 1 ? "Session" : "Sessions")"
                )
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundStyle(subtextGray)
            }
            .padding(.bottom, 12)

            ForEach(data.activities) { activity in

                Divider()

                HStack(spacing: 12) {

                    Image(systemName: activity.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(darkGreen)
                        .frame(width: 36, height: 36)
                        .background(
                            lightGreen,
                            in: RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )

                    Text(activity.name)
                        .mocoText(MocoScreenTheme.Typeface.slider)
                        .foregroundStyle(titleDark)

                    Spacer()

                    Text(activity.duration)
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundStyle(titleDark)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(MocoScreenTheme.Space.cardHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mocoCard()
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

    let container = try! ModelContainer(
        for: CalmDownModel.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

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
