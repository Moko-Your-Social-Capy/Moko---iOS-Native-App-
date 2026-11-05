import ActivityKit
import SwiftUI
import WidgetKit

private enum LivePalette {
    static let teal = Color(red: 31 / 255, green: 116 / 255, blue: 136 / 255)
    static let beige = Color(red: 247 / 255, green: 245 / 255, blue: 242 / 255)
    static let ink = Color(red: 74 / 255, green: 56 / 255, blue: 38 / 255)
    static let lightGreen = Color(red: 207 / 255, green: 230 / 255, blue: 196 / 255)
    static let midGreen = Color(red: 143 / 255, green: 191 / 255, blue: 138 / 255)
}

@main
struct MokoLiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        MokoCalmLiveActivity()
        MokoQuestLiveActivity()
        MokoStreakLiveActivity()
    }
}

struct MokoCalmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MokoCalmActivityAttributes.self) { context in
            CalmLockScreenView(state: context.state)
                .widgetURL(URL(string: "moko://calm"))
                .activityBackgroundTint(LivePalette.beige)
                .activitySystemActionForegroundColor(LivePalette.teal)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MokoMark(size: 40)
                        .padding(.leading, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(context.state.isPaused ? "Paused" : "Time left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ActivityCountdown(end: context.state.sessionEndsAt, paused: context.state.isPaused, remaining: context.state.remaining)
                    }
                    .padding(.trailing, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        BreathingPulse(phase: context.state.phase, isPaused: context.state.isPaused)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(context.state.isPaused ? "Paused" : context.state.phase.title)
                                .font(.headline)
                                .foregroundStyle(LivePalette.ink)
                                .contentTransition(.opacity)
                            Text("Box breathing · 4 seconds each")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        Spacer(minLength: 4)
                        Link(destination: URL(string: "moko://calm/end")!) {
                            Text("End")
                                .font(.subheadline.weight(.semibold))
                                .frame(minWidth: 44, minHeight: 44)
                                .foregroundStyle(LivePalette.teal)
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                MokoMark(size: 20)
            } compactTrailing: {
                CalmRing(state: context.state, size: 20)
            } minimal: {
                CalmRing(state: context.state, size: 19)
            }
            .keylineTint(LivePalette.teal)
            .widgetURL(URL(string: "moko://calm"))
        }
    }
}

struct MokoQuestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MokoQuestActivityAttributes.self) { context in
            QuestLiveActivityView(attributes: context.attributes, state: context.state)
                .widgetURL(URL(string: "moko://overview"))
                .activityBackgroundTint(LivePalette.beige)
                .activitySystemActionForegroundColor(LivePalette.teal)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MokoMark(size: 36)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: .now...context.attributes.expiresAt, countsDown: true)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 42, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(context.attributes.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LivePalette.ink)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            ThreeStepProgress(step: context.state.progressStep)
                        }
                        Spacer(minLength: 4)
                        Link(destination: URL(string: "moko://quest/done?id=\(context.attributes.questID.uuidString)")!) {
                            Text("Done")
                                .font(.subheadline.weight(.semibold))
                                .frame(minWidth: 44, minHeight: 44)
                                .foregroundStyle(LivePalette.teal)
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: "checklist")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LivePalette.lightGreen)
            } compactTrailing: {
                Text(timerInterval: .now...context.attributes.expiresAt, countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(minWidth: 28)
            } minimal: {
                Image(systemName: "checklist")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LivePalette.midGreen)
            }
            .keylineTint(LivePalette.teal)
            .widgetURL(URL(string: "moko://overview"))
        }
    }
}

struct MokoStreakLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MokoStreakActivityAttributes.self) { context in
            HStack(spacing: 12) {
                MokoMark(size: 42)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Moko’s waiting, no rush")
                        .font(.headline)
                        .foregroundStyle(LivePalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("A little moment for today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Link(destination: URL(string: "moko://overview")!) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LivePalette.teal)
                        .frame(width: 44, height: 44)
                        .background(LivePalette.lightGreen.opacity(0.6), in: Circle())
                        .contentShape(Circle())
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 2)
            .widgetURL(URL(string: "moko://overview"))
            .activityBackgroundTint(LivePalette.beige)
            .activitySystemActionForegroundColor(LivePalette.teal)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { MokoMark(size: 36) }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: .now...context.attributes.expiresAt, countsDown: true)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Text("Moko’s waiting, no rush")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LivePalette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Link(destination: URL(string: "moko://overview")!) {
                            Image(systemName: "arrow.up.right")
                                .frame(width: 44, height: 44)
                                .foregroundStyle(LivePalette.teal)
                        }
                    }
                }
            } compactLeading: {
                MokoMark(size: 19)
            } compactTrailing: {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LivePalette.midGreen)
            } minimal: {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LivePalette.midGreen)
            }
            .keylineTint(LivePalette.midGreen)
            .widgetURL(URL(string: "moko://overview"))
        }
    }
}

private struct CalmLockScreenView: View {
    let state: MokoCalmActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            BreathingPulse(phase: state.phase, isPaused: state.isPaused)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.isPaused ? "Paused" : state.phase.title)
                    .font(.headline)
                    .foregroundStyle(LivePalette.ink)
                    .contentTransition(.opacity)
                HStack(spacing: 8) {
                    Text("Box breathing")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    ActivityCountdown(end: state.sessionEndsAt, paused: state.isPaused, remaining: state.remaining)
                }
            }
            Spacer(minLength: 4)
            Link(destination: URL(string: "moko://calm/end")!) {
                Text("End")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LivePalette.teal)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 4)
    }
}

private struct QuestLiveActivityView: View {
    let attributes: MokoQuestActivityAttributes
    let state: MokoQuestActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            MokoMark(size: 44)
            VStack(alignment: .leading, spacing: 7) {
                Text("Today’s quest")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(attributes.title)
                    .font(.headline)
                    .foregroundStyle(LivePalette.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                ThreeStepProgress(step: state.progressStep)
            }
            Spacer(minLength: 4)
            VStack(spacing: 4) {
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(timerInterval: .now...attributes.expiresAt, countsDown: true)
                    .font(.caption.monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                Link(destination: URL(string: "moko://quest/done?id=\(attributes.questID.uuidString)")!) {
                    Text("Done")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LivePalette.teal)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ActivityCountdown: View {
    let end: Date
    let paused: Bool
    let remaining: TimeInterval

    var body: some View {
        Group {
            if paused {
                Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond(padMinuteToLength: 1)))
            } else {
                Text(timerInterval: .now...end, countsDown: true)
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit())
        .foregroundStyle(LivePalette.teal)
        .contentTransition(.numericText(countsDown: true))
    }
}

private struct CalmRing: View {
    let state: MokoCalmActivityAttributes.ContentState
    let size: CGFloat

    private var fraction: CGFloat {
        state.isComplete ? 1 : CGFloat(min(max(state.progressFraction, 0), 1))
    }

    var body: some View {
        ZStack {
            Circle().stroke(LivePalette.lightGreen.opacity(0.45), lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(LivePalette.midGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: fraction)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Breathing session progress")
    }
}

private struct BreathingPulse: View {
    let phase: MokoBreathingPhase
    let isPaused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var startScale: CGFloat {
        switch phase {
        case .inhale, .holdOut: 0.88
        case .holdIn, .exhale: 1.12
        }
    }

    private var targetScale: CGFloat {
        switch phase {
        case .inhale, .holdIn: 1.12
        case .exhale, .holdOut: 0.88
        }
    }

    var body: some View {
        let fromScale = startScale
        let toScale = targetScale
        let animatedPhase = phase
        let shouldAnimate = !reduceMotion && !isPaused
        return ZStack {
            Circle().fill(LivePalette.lightGreen.opacity(0.65))
            Circle()
                .fill(LivePalette.midGreen.opacity(0.65))
                .padding(6)
            MokoMark(size: 27)
        }
        .keyframeAnimator(initialValue: CGFloat(0), trigger: animatedPhase) { content, progress in
            let scale = fromScale + (toScale - fromScale) * progress
            content.scaleEffect(shouldAnimate ? scale : 1)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                switch animatedPhase {
                case .inhale, .exhale:
                    CubicKeyframe(shouldAnimate ? 1 : 0, duration: 3.8)
                case .holdIn, .holdOut:
                    LinearKeyframe(0, duration: 0.05)
                }
            }
        }
        .accessibilityLabel(isPaused ? "Moko, breathing paused" : "Moko, \(phase.title.lowercased())")
    }
}

private struct ThreeStepProgress: View {
    let step: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index < step ? LivePalette.teal : LivePalette.lightGreen)
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("\(min(max(step, 0), 3)) of 3 steps")
    }
}

private struct MokoMark: View {
    var size: CGFloat

    var body: some View {
        Image("MokoMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
