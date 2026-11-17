//
//  OverviewDebriefDone.swift
//  Moko
//
//  The Overview tab ("debrief done" version): shown after a debrief is finished.
//  The mission card celebrates and counts down to midnight, when the next daily
//  mission is created. The header and Growth cards come from `OverviewScaffold`.
//

import SwiftUI
import SwiftData

private typealias Theme = MokoScreenTheme

struct OverviewDebriefDone: View {
    @State private var showConfetti = false

    var body: some View {
        OverviewScaffold {
            VStack(spacing: 0) {
                Text("No Active Quest")
                    .mokoText(Theme.Typeface.cardTitle)
                    .foregroundStyle(Theme.Colors.textTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Completion icon (decoration only, so VoiceOver skips it).
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(Theme.Colors.dataVioletDeep)
                    .padding(12)
                    .background(Theme.Colors.dataVioletDeep.opacity(0.10), in: Circle())
                    .padding(.top, 24)
                    .accessibilityHidden(true)

                Text("All quests completed!")
                    .mokoText(Theme.Typeface.section)
                    .foregroundStyle(Theme.Colors.textTitle)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                Text("You've finished today's quests. Discover more interesting challenges in the quest library.")
                    .mokoText(Theme.Typeface.body)
                    .foregroundStyle(Theme.Colors.textBody)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                countdown
                    .padding(.top, 26)
            }
        }
        .celebration($showConfetti, style: .confetti, duration: 3.5)
        .onAppear {
            // One confetti burst celebrates the single completion card below.
            showConfetti = true
        }
    }

    // MARK: - Countdown

    /// Dynamic countdown to midnight when the next daily quest drops.
    /// `TimelineView(.everyMinute)` recalculates the remaining time every minute.
    private var countdown: some View {
        TimelineView(.everyMinute) { context in
            HStack(spacing: 7) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .accessibilityHidden(true)

                Text("New quest in")
                    .mokoText(Theme.Typeface.body)

                Text(Self.timeUntilTomorrow(from: context.date))
                    .mokoText(Theme.Typeface.slider)
                    .foregroundStyle(Theme.Colors.countdownValue)
            }
            .foregroundStyle(Theme.Colors.textBody)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                Theme.Colors.surfaceLavender,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .accessibilityElement(children: .combine)
        }
    }

    /// Actual time left until midnight (next daily mission boundary), e.g. "12 hrs 48 mins" or "45 mins".
    static func timeUntilTomorrow(from now: Date) -> String {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let seconds = max(0, Int(tomorrow.timeIntervalSince(now)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours) hr\(hours == 1 ? "" : "s") \(minutes) min\(minutes == 1 ? "" : "s")"
        } else {
            return "\(max(1, minutes)) min\(minutes == 1 ? "" : "s")"
        }
    }
}

#Preview {
    OverviewDebriefDone()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
