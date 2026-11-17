//
//  StreakDetailView.swift
//  Moko
//
//  Simplified streak view: streak count, milestones, and calendar only.
//  All data comes from StreakService (ActivityRecord rows).
//

import SwiftUI
import SwiftData

struct StreakDetailView: View {
    // SwiftData rows — the single source of truth for streak data.
    @Query private var activityRecords: [ActivityRecord]

    private let milestones = [7, 14, 21, 30, 60, 90, 180, 365]

    // Streak stats computed from ActivityRecord rows via StreakService.
    private var stats: StreakStats {
        StreakService.shared.stats(from: activityRecords)
    }

    private var currentStreak: Int { stats.currentStreak }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                streakCountSection
                milestonesSection
                calendarSection
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.vertical, 20)
        }
        .background(MokoBackdrop())
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 1) Streak count

    private var streakCountSection: some View {
        VStack(spacing: 10) {
            // Flame uses centralized Lottie asset (loops appropriately, respects Reduce Motion).
            MokoLottieView(animation: .streakFlame)
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)

            Text("\(currentStreak)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                .monospacedDigit()

            Text(currentStreak == 1 ? "day streak" : "days streak")
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .mokoCard(fill: MokoScreenTheme.Colors.surfaceWhite)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentStreak) day streak")
    }

    // MARK: - 2) Streak milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            VStack(spacing: 10) {
                ForEach(milestones, id: \.self) { milestone in
                    milestoneRow(milestone: milestone)
                }
            }
        }
        .padding(16)
        .mokoCard(fill: MokoScreenTheme.Colors.surfaceWhite)
    }

    private func milestoneRow(milestone: Int) -> some View {
        let isCompleted = currentStreak >= milestone
        let nextMilestone = milestones.first(where: { $0 > currentStreak })
        let isCurrent = nextMilestone == milestone

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? MokoScreenTheme.Colors.ctaAccent : MokoScreenTheme.Colors.surfaceLavender)
                    .frame(width: 28, height: 28)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MokoScreenTheme.Colors.textOnBrand)
                } else {
                    Circle()
                        .stroke(isCurrent ? MokoScreenTheme.Colors.ctaAccent : MokoScreenTheme.Colors.borderSubtle, lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(milestone) days")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(isCompleted || isCurrent ? MokoScreenTheme.Colors.textTitle : MokoScreenTheme.Colors.textMuted)
                Text(statusText(for: milestone, isCompleted: isCompleted, isCurrent: isCurrent))
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(isCurrent ? MokoScreenTheme.Colors.ctaAccent : MokoScreenTheme.Colors.textBody)
            }

            Spacer()

            // Simple height marker so milestones read as "heights".
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isCompleted ? MokoScreenTheme.Colors.ctaAccent : (isCurrent ? MokoScreenTheme.Colors.chartTertiary : MokoScreenTheme.Colors.borderSubtle))
                .frame(width: 6, height: milestoneHeight(for: milestone))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func statusText(for milestone: Int, isCompleted: Bool, isCurrent: Bool) -> String {
        if isCompleted { return "Completed" }
        if isCurrent { return "\(max(0, milestone - currentStreak)) days to go" }
        return "Upcoming"
    }

    private func milestoneHeight(for milestone: Int) -> CGFloat {
        switch milestone {
        case 7: return 14
        case 14: return 18
        case 21: return 22
        case 30: return 26
        case 60: return 30
        case 90: return 34
        case 180: return 38
        default: return 42
        }
    }

    // MARK: - 3) Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            // Monthly calendar with completed days, today, missed/active distinction, and month navigation.
            StreakCalendarView()
        }
    }
}

#Preview {
    NavigationStack {
        StreakDetailView()
            .modelContainer(for: [ActivityRecord.self], inMemory: true)
    }
}
