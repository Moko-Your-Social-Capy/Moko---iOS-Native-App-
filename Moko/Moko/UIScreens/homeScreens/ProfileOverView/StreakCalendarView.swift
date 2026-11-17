//
//  StreakCalendarView.swift
//  Moko
//
//  Calendar view showing daily activity streak with visual indicators.
//  All data comes from StreakService (ActivityRecord rows) — the single source
//  of truth — so the calendar, profile streak and detail screen always match.
//

import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    // The day the user tapped. The view owns its own selection.
    @State private var selectedDate: Date = Date()
    // SwiftData rows — the single source of truth for streak data.
    @Query private var activityRecords: [ActivityRecord]

    // Streak stats computed from ActivityRecord rows via StreakService.
    private var stats: StreakStats {
        StreakService.shared.stats(from: activityRecords)
    }

    private var activeDates: Set<Date> { stats.activeDates }
    private var currentStreak: Int { stats.currentStreak }
    private var longestStreak: Int { stats.longestStreak }

    @State private var currentMonth: Date = Date()
    @State private var showingMonthPicker = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 20) {
            // Month header with navigation
            monthHeader

            // Weekday headers
            weekdayHeaders

            // Calendar grid
            calendarGrid

            // Streak stats
            streakStats
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(MokoScreenTheme.Colors.borderSubtle, lineWidth: 1)
                )
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
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
            }
            .mokoButtonStyle(.icon)

            Spacer()

            Button(action: { showingMonthPicker = true }) {
                Text(monthYearString(from: currentMonth))
                    .mokoText(MokoScreenTheme.Typeface.title3)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            }
            .mokoButtonStyle(.secondary)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
            }
            .mokoButtonStyle(.icon)
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
            ForEach(daysInMonth(), id: \.self) { date in
                if let date = date {
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isActive: activeDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }),
                        isToday: calendar.isDateInToday(date),
                        isInCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                } else {
                    // Empty cell for days outside the month
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    // MARK: - Streak Stats

    private var streakStats: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .mokoText(MokoScreenTheme.Typeface.title1)
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)

                Text("Current Streak")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)
                .background(MokoScreenTheme.Colors.borderSubtle)

            VStack(spacing: 4) {
                Text("\(longestStreak)")
                    .mokoText(MokoScreenTheme.Typeface.title1)
                    .foregroundStyle(MokoScreenTheme.Colors.dataMagenta)

                Text("Longest Streak")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.1))
        )
    }

    // MARK: - Month Picker Sheet

    private var monthPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(0..<12) { monthOffset in
                    let date = calendar.date(byAdding: .month, value: monthOffset - 6, to: Date())!
                    Button(action: {
                        currentMonth = startOfMonth(for: date)
                        showingMonthPicker = false
                    }) {
                        HStack {
                            Text(monthYearString(from: date))
                                .mokoText(MokoScreenTheme.Typeface.body)
                                .foregroundStyle(MokoScreenTheme.Colors.textBody)

                            Spacer()

                            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        showingMonthPicker = false
                    }
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
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
                .frame(width: 36, height: 36)
                .background(dayBackground)
                .clipShape(Circle())
        }
        .frame(height: 50)
        .opacity(isInCurrentMonth ? 1 : 0.3)
    }

    private var dayTextColor: Color {
        if isSelected {
            return MokoScreenTheme.Colors.textOnBrand
        } else if isToday {
            return MokoScreenTheme.Colors.dataVioletDeep
        } else if isActive {
            return MokoScreenTheme.Colors.textBody
        } else {
            return MokoScreenTheme.Colors.textMuted
        }
    }

    private var dayBackground: some View {
        Group {
            if isSelected {
                Circle()
                    .fill(MokoScreenTheme.Colors.dataVioletDeep)
            } else if isToday {
                Circle()
                    .stroke(MokoScreenTheme.Colors.dataVioletDeep, lineWidth: 2)
                    .background(Circle().fill(MokoScreenTheme.Colors.canvasTop))
            } else if isActive {
                Circle()
                    .fill(MokoScreenTheme.Colors.dataVioletLight.opacity(0.2))
            } else {
                Circle()
                    .fill(Color.clear)
            }
        }
    }
}

#Preview {
    StreakCalendarView()
        .modelContainer(for: [ActivityRecord.self], inMemory: true)
}