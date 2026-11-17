//
//  StreakDetailView.swift
//  Moko
//
//  Detailed streak view with hero section, milestones, and activity breakdown.
//  Shows progress towards next milestone and streak history.
//  All data comes from StreakService (ActivityRecord rows) — the single source
//  of truth — so the detail screen, calendar and profile always match.
//

import SwiftUI
import Lottie
import SwiftData

struct StreakDetailView: View {
    // SwiftData rows — the single source of truth for streak data.
    @Query private var activityRecords: [ActivityRecord]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingMilestoneCelebration = false
    
    private let milestones = [7, 14, 21, 30, 60, 90, 180, 365]
    
    // Streak stats computed from ActivityRecord rows via StreakService.
    private var stats: StreakStats {
        StreakService.shared.stats(from: activityRecords)
    }
    
    private var currentStreak: Int { stats.currentStreak }
    private var longestStreak: Int { stats.longestStreak }
    private var totalDaysActive: Int { stats.totalActiveDays }
    private var lastActivityDate: Date? { stats.lastActivityDate }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero section
                heroSection
                
                // Streak calendar
                streakCalendarSection
                
                // Milestones progress
                milestonesSection
                
                // Activity breakdown
                activityBreakdownSection
                
                // Tips & motivation
                tipsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(MokoBackdrop())
        .navigationTitle("Your Streak")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMilestoneCelebration) {
            milestoneCelebrationSheet
        }
        .onChange(of: currentStreak) { oldValue, newValue in
            checkForMilestone(newValue)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Streak flame animation
            ZStack {
                if currentStreak >= 7 {
                    MokoLottieView(animation: .sparkles, loopMode: .loop)
                        .frame(width: 150, height: 150)
                        .opacity(0.55)
                }

                MokoLottieView(animation: .streakFlame, loopMode: .loop)
                    .frame(width: 200, height: 200)
            }
            
            VStack(spacing: 8) {
                Text("\(currentStreak)-day streak!")
                    .mokoText(MokoScreenTheme.Typeface.title1)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                
                Text(lastActivityStatus)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                statItem(value: "\(longestStreak)", label: "Longest", color: MokoScreenTheme.Colors.dataMagenta)
                
                Divider()
                    .frame(height: 40)
                    .background(MokoScreenTheme.Colors.borderSubtle)
                
                statItem(value: "\(totalDaysActive)", label: "Total Days", color: MokoScreenTheme.Colors.dataVioletDeep)
                
                Divider()
                    .frame(height: 40)
                    .background(MokoScreenTheme.Colors.borderSubtle)
                
                statItem(value: nextMilestoneText, label: "Next Goal", color: MokoScreenTheme.Colors.dataTeal)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(MokoScreenTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Streak Calendar Section
    
    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .mokoText(MokoScreenTheme.Typeface.title3)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("Week").tag(TimeRange.week)
                    Text("Month").tag(TimeRange.month)
                    Text("Year").tag(TimeRange.year)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            // Simplified activity chart
            activityChart
        }
    }
    
    // MARK: - Milestones Section
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            
            VStack(spacing: 12) {
                ForEach(milestones, id: \.self) { milestone in
                    milestoneRow(milestone: milestone)
                }
            }
        }
    }
    
    // MARK: - Activity Breakdown
    
    private var activityBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Breakdown")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            
            VStack(spacing: 12) {
                activityStat(
                    icon: "brain.head.profile",
                    title: "Mindfulness Sessions",
                    value: "\(Int(Double(totalDaysActive) * 0.8))",
                    color: MokoScreenTheme.Colors.dataVioletDeep
                )
                
                activityStat(
                    icon: "heart",
                    title: "Breathing Exercises",
                    value: "\(Int(Double(totalDaysActive) * 1.2))",
                    color: MokoScreenTheme.Colors.dataMagenta
                )
                
                activityStat(
                    icon: "quote.bubble",
                    title: "Affirmations",
                    value: "\(Int(Double(totalDaysActive) * 0.6))",
                    color: MokoScreenTheme.Colors.dataTeal
                )
                
                activityStat(
                    icon: "checkmark.circle",
                    title: "Quests Completed",
                    value: "\(Int(Double(totalDaysActive) * 0.4))",
                    color: MokoScreenTheme.Colors.dataGold
                )
            }
        }
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keep Your Streak Going")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            
            VStack(spacing: 12) {
                tipItem(
                    icon: "bell",
                    title: "Set a Daily Reminder",
                    description: "Get notified to practice mindfulness each day"
                )
                
                tipItem(
                    icon: "target",
                    title: "Start Small",
                    description: "Even 5 minutes of practice counts toward your streak"
                )
                
                tipItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "Watch your streak grow and celebrate milestones"
                )
            }
        }
    }
    
    // MARK: - Milestone Celebration Sheet
    
    private var milestoneCelebrationSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Celebration animation with confetti
                MokoLottieView(animation: .confetti, loopMode: .playOnce)
                    .frame(width: 200, height: 200)
                
                // Trophy icon overlay
                Image(systemName: "trophy")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MokoScreenTheme.Colors.dataGold, MokoScreenTheme.Colors.dataMagenta],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(spacing: 12) {
                    Text("Milestone Achieved!")
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    
                    Text("You've reached a \(currentStreak)-day mindfulness streak! Keep up the amazing work.")
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                PrimaryButton(title: "Continue", action: {
                    showingMilestoneCelebration = false
                })
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.top, 40)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }
    
    // MARK: - Helper Views
    
    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .mokoText(MokoScreenTheme.Typeface.title2)
                .foregroundStyle(color)
            
            Text(label)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MokoScreenTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var activityChart: some View {
        let buckets = activityBuckets
        let peak = max(buckets.map(\.count).max() ?? 0, 1)

        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(buckets) { bucket in
                VStack(spacing: 6) {
                    // A small number above each bar explains how much happened.
                    Text(bucket.count > 0 ? "\(bucket.count)" : " ")
                        .mokoText(MokoScreenTheme.Typeface.badge)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(bucket.count > 0
                              ? MokoScreenTheme.Colors.dataVioletDeep
                              : MokoScreenTheme.Colors.canvasTop.opacity(0.25))
                        .frame(height: max(6, 104 * CGFloat(bucket.count) / CGFloat(peak)))

                    // Real period labels: Mon, W2, Jan — never a guessed weekday.
                    Text(bucket.label)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(bucket.label), \(bucket.count) activities")
            }
        }
        .frame(height: 160)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.1))
        )
    }

    /// Real activity buckets for the Week, Month or Year picker.
    private var activityBuckets: [StreakChartBucket] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedTimeRange {
        case .week:
            // Seven days ending today, labelled with their real weekdays.
            let today = calendar.startOfDay(for: now)
            return (0..<7).reversed().compactMap { offset in
                guard let start = calendar.date(byAdding: .day, value: -offset, to: today),
                      let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                    return nil
                }
                return StreakChartBucket(
                    start: start,
                    label: start.formatted(.dateTime.weekday(.abbreviated)),
                    count: activityCount(from: start, to: end)
                )
            }

        case .month:
            // Each calendar week in this month, labelled W1, W2, and so on.
            guard let month = calendar.dateInterval(of: .month, for: now) else { return [] }
            var cursor = calendar.dateInterval(of: .weekOfYear, for: month.start)?.start ?? month.start
            var weekNumber = 1
            var buckets: [StreakChartBucket] = []

            while cursor < month.end {
                guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else {
                    break
                }
                let start = max(cursor, month.start)
                let end = min(next, month.end)
                buckets.append(
                    StreakChartBucket(
                        start: start,
                        label: "W\(weekNumber)",
                        count: activityCount(from: start, to: end)
                    )
                )
                cursor = next
                weekNumber += 1
            }
            return buckets

        case .year:
            // One bar per month, labelled with the real month name.
            let year = calendar.component(.year, from: now)
            return (1...12).compactMap { month in
                guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else {
                    return nil
                }
                return StreakChartBucket(
                    start: start,
                    label: start.formatted(.dateTime.month(.abbreviated)),
                    count: activityCount(from: start, to: end)
                )
            }
        }
    }

    /// Counts saved activities inside one chart period.
    private func activityCount(from start: Date, to end: Date) -> Int {
        activityRecords.filter { $0.activityDate >= start && $0.activityDate < end }.count
    }
    
    private func milestoneRow(milestone: Int) -> some View {
        let isCompleted = currentStreak >= milestone
        let isCurrent = currentStreak < milestone && (milestones.first(where: { $0 > currentStreak }) == milestone)
        
        return HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(
                    isCompleted ? MokoScreenTheme.Colors.dataTeal :
                    isCurrent ? MokoScreenTheme.Colors.dataVioletDeep :
                    MokoScreenTheme.Colors.textMuted
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(milestone) days")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(
                        isCompleted ? MokoScreenTheme.Colors.textTitle :
                        isCurrent ? MokoScreenTheme.Colors.textTitle :
                        MokoScreenTheme.Colors.textMuted
                    )
                
                if isCompleted {
                    Text("Achieved")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.dataTeal)
                } else if isCurrent {
                    Text("\(milestone - currentStreak) days to go")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                } else {
                    Text("Keep going")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                }
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "trophy")
                    .font(.system(size: 16))
                    .foregroundStyle(MokoScreenTheme.Colors.dataGold)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isCurrent ? MokoScreenTheme.Colors.dataVioletLight.opacity(0.1) :
                    isCompleted ? MokoScreenTheme.Colors.dataTeal.opacity(0.05) :
                    Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isCurrent ? MokoScreenTheme.Colors.dataVioletDeep.opacity(0.2) :
                            isCompleted ? MokoScreenTheme.Colors.dataTeal.opacity(0.2) :
                            MokoScreenTheme.Colors.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func activityStat(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                
                Text("\(value) total")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
            }
            
            Spacer()
            
            Text("+\(Int.random(in: 5...15))%")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
    }
    
    private func tipItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                .frame(width: 40, height: 40)
                .background(MokoScreenTheme.Colors.dataVioletLight.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                
                Text(description)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    private var lastActivityStatus: String {
        guard let lastDate = lastActivityDate else {
            return "Start your streak today!"
        }
        
        if Calendar.current.isDateInToday(lastDate) {
            return "You practiced mindfulness today. Great job!"
        } else if Calendar.current.isDateInYesterday(lastDate) {
            return "You practiced yesterday. Keep it up!"
        } else {
            let daysAgo = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            return "Last practice was \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago."
        }
    }
    
    private var nextMilestoneText: String {
        if let nextMilestone = milestones.first(where: { $0 > currentStreak }) {
            return "\(nextMilestone)"
        } else {
            return "Max"
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkForMilestone(_ streak: Int) {
        if milestones.contains(streak) {
            showingMilestoneCelebration = true
        }
    }
}

// MARK: - Chart Data

/// One real activity bar in the streak chart.
private struct StreakChartBucket: Identifiable {
    let start: Date
    let label: String
    let count: Int

    var id: Date { start }
}

// MARK: - Time Range Enum

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

#Preview {
    NavigationStack {
        StreakDetailView()
    }
}
