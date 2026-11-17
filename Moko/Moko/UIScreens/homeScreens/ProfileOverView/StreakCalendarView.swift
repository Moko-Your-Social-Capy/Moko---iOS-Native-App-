//
//  StreakCalendarView.swift
//  Moko
//
//  Monthly streak calendar used in the Streak Detail screen.
//  Data comes from StreakService (ActivityRecord rows) — the single source of truth.
//

import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    // The day the user tapped.
    @State private var selectedDate: Date = Date()
    // SwiftData rows — the single source of truth for streak data.
    @Query private var activityRecords: [ActivityRecord]

    // Active days computed from ActivityRecord rows via StreakService.
    private var activeDates: Set<Date> { StreakService.shared.stats(from: activityRecords).activeDates }

    @State private var currentMonth: Date = Date()
    @State private var showingMonthPicker = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            monthHeader
            weekdayHeaders
            calendarGrid
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card, style: .continuous)
                .fill(MokoScreenTheme.Colors.surfaceWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card, style: .continuous)
                .stroke(MokoScreenTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .sheet(isPresented: $showingMonthPicker) {
            monthPickerSheet
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(MokoScreenTheme.Colors.ctaAccent)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { showingMonthPicker = true }) {
                Text(monthYearString(from: currentMonth))
                    .mokoText(MokoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(MokoScreenTheme.Colors.ctaAccent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                if let date = date {
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isActive: activeDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }),
                        isToday: calendar.isDateInToday(date),
                        isInCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    )
                    .onTapGesture { selectedDate = date }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    // MARK: - Month Picker Sheet

    private var monthPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(0..<12) { monthOffset in
                    let date = calendar.date(byAdding: .month, value: monthOffset - 6, to: Date()) ?? Date()
                    Button(action: {
                        currentMonth = startOfMonth(for: date)
                        showingMonthPicker = false
                    }) {
                        HStack {
                            Text(monthYearString(from: date))
                                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                            Spacer()
                            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(MokoScreenTheme.Colors.ctaAccent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { showingMonthPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        let totalDays = 42 // 6 weeks × 7 days
        for offset in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: offset, to: monthFirstWeek.start) {
                days.append(date)
            }
        }
        return days
    }

    private func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isActive: Bool
    let isToday: Bool
    let isInCurrentMonth: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .mokoText(isToday ? MokoScreenTheme.Typeface.button : MokoScreenTheme.Typeface.body)
                .foregroundStyle(dayTextColor)
                .frame(width: 34, height: 34)
                .background(dayBackground)
                .clipShape(Circle())
        }
        .frame(height: 42)
        .opacity(isInCurrentMonth ? 1 : 0.25)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dayTextColor: Color {
        if isSelected { return MokoScreenTheme.Colors.textOnBrand }
        if isToday { return MokoScreenTheme.Colors.ctaAccent }
        if isActive { return MokoScreenTheme.Colors.textTitle }
        return MokoScreenTheme.Colors.textMuted
    }

    private var dayBackground: some View {
        Group {
            if isSelected {
                Circle().fill(MokoScreenTheme.Colors.ctaAccent)
            } else if isToday {
                Circle()
                    .stroke(MokoScreenTheme.Colors.ctaAccent, lineWidth: 2)
                    .background(Circle().fill(MokoScreenTheme.Colors.surfaceWhite))
            } else if isActive {
                Circle().fill(MokoScreenTheme.Colors.ctaAccent.opacity(0.18))
            } else {
                Circle().fill(Color.clear)
            }
        }
    }

    private var accessibilityLabel: String {
        let day = calendar.component(.day, from: date)
        if isActive { return "Day \(day), active" }
        if isToday { return "Day \(day), today" }
        return "Day \(day)"
    }
}

#Preview {
    StreakCalendarView()
        .modelContainer(for: [ActivityRecord.self], inMemory: true)
}
