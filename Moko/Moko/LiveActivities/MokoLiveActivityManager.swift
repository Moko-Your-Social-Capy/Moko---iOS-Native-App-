import ActivityKit
import Foundation

@MainActor
enum MokoLiveActivityManager {
    static func startCalmSession(totalDuration: TimeInterval) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let now = Date()
        let state = MokoCalmActivityAttributes.ContentState(
            phase: .inhale,
            progressFraction: 0,
            remaining: totalDuration,
            phaseEndsAt: now.addingTimeInterval(4),
            sessionEndsAt: now.addingTimeInterval(totalDuration),
            isPaused: false,
            isComplete: false
        )
        let content = ActivityContent(state: state, staleDate: now.addingTimeInterval(9))
        for existing in Activity<MokoCalmActivityAttributes>.activities {
            await existing.end(nil, dismissalPolicy: .immediate)
        }
        _ = try? Activity.request(
            attributes: MokoCalmActivityAttributes(sessionID: UUID()),
            content: content,
            pushType: nil
        )
    }

    static func updateCalmSession(
        phase: MokoBreathingPhase,
        progress: Double,
        remaining: TimeInterval,
        phaseRemaining: TimeInterval,
        isPaused: Bool = false
    ) async {
        guard let activity = Activity<MokoCalmActivityAttributes>.activities.first else { return }
        let now = Date()
        let state = MokoCalmActivityAttributes.ContentState(
            phase: phase,
            progressFraction: min(max(progress, 0), 1),
            remaining: max(remaining, 0),
            phaseEndsAt: now.addingTimeInterval(max(phaseRemaining, 0)),
            sessionEndsAt: now.addingTimeInterval(max(remaining, 0)),
            isPaused: isPaused,
            isComplete: false
        )
        await activity.update(ActivityContent(
            state: state,
            staleDate: isPaused ? nil : now.addingTimeInterval(phaseRemaining + 5)
        ))
    }

    static func endCalmSession(completed: Bool) async {
        guard let activity = Activity<MokoCalmActivityAttributes>.activities.first else { return }
        let now = Date()
        let oldState = activity.content.state
        let state = MokoCalmActivityAttributes.ContentState(
            phase: oldState.phase,
            progressFraction: completed ? 1 : oldState.progressFraction,
            remaining: 0,
            phaseEndsAt: now,
            sessionEndsAt: now,
            isPaused: false,
            isComplete: completed
        )
        let content = ActivityContent(state: state, staleDate: now.addingTimeInterval(1))
        await activity.end(content, dismissalPolicy: completed ? .after(now.addingTimeInterval(2)) : .immediate)
    }

    static func startTodayQuest(id: UUID, title: String, progressStep: Int = 1) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let now = Date()
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        if let existing = Activity<MokoQuestActivityAttributes>.activities.first(where: { $0.attributes.questID == id }) {
            let state = MokoQuestActivityAttributes.ContentState(progressStep: min(max(progressStep, 0), 3), isComplete: false)
            await existing.update(ActivityContent(state: state, staleDate: endOfDay))
            return
        }
        for existing in Activity<MokoQuestActivityAttributes>.activities {
            await existing.end(nil, dismissalPolicy: .immediate)
        }
        let attributes = MokoQuestActivityAttributes(questID: id, title: title, expiresAt: endOfDay)
        let state = MokoQuestActivityAttributes.ContentState(progressStep: min(max(progressStep, 0), 3), isComplete: false)
        _ = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: endOfDay), pushType: nil)
    }

    static func completeTodayQuest(id: UUID) async {
        guard let activity = Activity<MokoQuestActivityAttributes>.activities.first(where: { $0.attributes.questID == id }) else { return }
        let state = MokoQuestActivityAttributes.ContentState(progressStep: 3, isComplete: true)
        await activity.end(ActivityContent(state: state, staleDate: .now), dismissalPolicy: .after(.now.addingTimeInterval(2)))
    }

    static func startStreakReminderIfNeeded(streak: Int, lastActivityDate: Date?) async {
        guard streak > 0,
              ActivityAuthorizationInfo().areActivitiesEnabled,
              Calendar.current.component(.hour, from: .now) >= 19,
              let lastActivityDate,
              !Calendar.current.isDateInToday(lastActivityDate),
              Activity<MokoStreakActivityAttributes>.activities.isEmpty else { return }

        let now = Date()
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        let attributes = MokoStreakActivityAttributes(dayStart: Calendar.current.startOfDay(for: now), expiresAt: endOfDay)
        let state = MokoStreakActivityAttributes.ContentState(reminderEndsAt: endOfDay)
        _ = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: endOfDay), pushType: nil)
    }

    static func endExpiredActivities() async {
        let now = Date()
        for activity in Activity<MokoCalmActivityAttributes>.activities where activity.activityState == .stale {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        for activity in Activity<MokoQuestActivityAttributes>.activities where activity.attributes.expiresAt <= now {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        for activity in Activity<MokoStreakActivityAttributes>.activities where activity.attributes.expiresAt <= now {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
