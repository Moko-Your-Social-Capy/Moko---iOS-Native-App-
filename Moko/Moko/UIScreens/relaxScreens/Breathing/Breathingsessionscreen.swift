//
//  BreathingSessionScreen.swift
//  Moko
//
//  Guided breathing timer. One screen with four states:
//  idle (Start) -> running (pause / reset) -> paused (play / reset) -> completed.
//  The progress ring fills during the session; the capybara follows a 4s inhale / 6s exhale rhythm.
//  When the timer completes, a green completion badge and falling lemons replace the capybara.
//

import SwiftUI
import SwiftData
import Combine
import RiveRuntime

struct BreathingSessionScreen: View {
    let minutes: Int
    /// Fires when the user taps Complete on the final screen.
    var onFinish: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    fileprivate enum RunState {
        case idle, running, paused, completed
    }

    @State private var runState: RunState
    @State private var elapsed: TimeInterval = 0
    @State private var lastTick: Date?
    /// Bumped on reset so the Rive state machine starts again from frame 0.
    @State private var riveResetID = UUID()

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    // Breathing rhythm
    private let inhaleDuration: TimeInterval = 4
    private let exhaleDuration: TimeInterval = 6

    // A soft lime palette with a deep green accent.
    private let cardGreen = MocoScreenTheme.Colors.dataVioletDeep
    private let subtextGray = MocoScreenTheme.Colors.textBody
    private let mist = MocoScreenTheme.Colors.surfaceLavender

    init(minutes: Int, onFinish: (() -> Void)? = nil, previewCompleted: Bool = false) {
        self.minutes = max(1, minutes)
        self.onFinish = onFinish
        _runState = State(initialValue: previewCompleted ? .completed : .idle)
    }

    // MARK: - Derived values
    private var total: TimeInterval { TimeInterval(minutes * 60) }
    private var cycle: TimeInterval { inhaleDuration + exhaleDuration }
    private var progress: Double { min(1, elapsed / total) }

    private var remainingSeconds: Int { max(0, Int(ceil(total - elapsed))) }
    private var timeText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private var isInhaling: Bool {
        elapsed.truncatingRemainder(dividingBy: cycle) < inhaleDuration
    }

    private var phaseTitle: String {
        switch runState {
        case .idle:      return "Ready"
        case .running:   return isInhaling ? "Inhale" : "Exhale"
        case .paused:    return "Paused"
        case .completed: return "Well done"
        }
    }

    private var phaseHint: String {
        switch runState {
        case .idle:      return "Find a comfortable position, then press start"
        case .running:   return isInhaling ? "Breathe in slowly through your nose" : "Let it out gently through your mouth"
        case .paused:    return "Take a moment. Resume when you're ready"
        case .completed: return "You breathed mindfully for \(minutes) min"
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 12)
            breathingFocus
            Spacer(minLength: 12)
        }
        .padding(.horizontal, MocoScreenTheme.Space.page)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MocoBackdrop())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomPanel
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onReceive(ticker) { now in
            tick(now)
        }
        .sensoryFeedback(trigger: runState) { oldState, newState in
            switch (oldState, newState) {
            case (_, .completed): return .success
            case (.idle, .running): return .impact(weight: .medium)
            default: return .impact(weight: .light)
            }
        }
    }

    /// Keeps Moko as the calm focal point, with generous space around the animation.
    private var breathingFocus: some View {
        VStack(spacing: 10) {
            ZStack {
                if runState == .completed {
                    MokoCompletionAnimation(ringDiameter: 190)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                } else {
                    Circle()
                        .fill(mist.opacity(0.58))
                        .frame(width: 250, height: 250)
                    Circle()
                        .stroke(cardGreen.opacity(0.12), lineWidth: 5)
                        .frame(width: 270, height: 270)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(cardGreen, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 270, height: 270)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0 / 30.0), value: progress)
                        .accessibilityLabel("Session progress, \(Int(progress * 100)) percent")

                    AsyncRiveUIViewRepresentable {
                        let worker = try await Worker()
                        let file = try await File(
                            source: .local("MokoMeditationRive", Bundle.main),
                            worker: worker
                        )
                        return try await Rive(file: file)
                    }
                    .paused(runState != .running)
                    .id(riveResetID)
                    .frame(width: 250, height: 250)
                    // The mascot is the direct start / pause / resume control.
                    .overlay {
                        Button(action: toggleMascotPlayback) {
                            Color.clear
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(mascotAccessibilityLabel)
                        .accessibilityHint("Starts the breathing timer, or pauses and resumes it")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(runState == .completed ? "Breathing session complete" : "Moko breathing animation")

            Text(phaseTitle)
                .mocoText(MocoScreenTheme.Typeface.title1)
                .foregroundStyle(cardGreen)
                .contentTransition(.opacity)

            Text(phaseHint)
                .mocoText(MocoScreenTheme.Typeface.body)
                .foregroundStyle(subtextGray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.25), value: phaseTitle)
    }

    // MARK: - Bottom panel (timer + controls)
    private var bottomPanel: some View {
        VStack(spacing: 14) {
            if runState != .completed {
                Text(timeText)
                    .mocoText(MocoScreenTheme.Typeface.numeral)
                    .monospacedDigit()
                    .foregroundColor(cardGreen)
            }
            controls
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .mocoCard()
        .padding(.horizontal, MocoScreenTheme.Space.page)
        .padding(.bottom, 8)
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Gentle Breathing")
                .mocoText(MocoScreenTheme.Typeface.title1)
                .foregroundColor(MocoScreenTheme.Colors.textTitle)

            Text("Set your own meditation timer for a calmer mind")
                .mocoText(MocoScreenTheme.Typeface.body)
                .foregroundColor(subtextGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls
    @ViewBuilder
    private var controls: some View {
        Group {
            switch runState {
            case .idle:
                primaryButton("Start") { start() }

            case .running, .paused:
                HStack {
                    circleButton(systemName: "arrow.counterclockwise") { reset() }
                    Spacer()
                    circleButton(systemName: runState == .running ? "pause.fill" : "play.fill") {
                        togglePause()
                    }
                }
                .padding(.horizontal, 12)

            case .completed:
                primaryButton("Complete") {
                    if let onFinish {
                        onFinish()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.2), value: runState)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .mocoText(MocoScreenTheme.Typeface.cardTitle)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(cardGreen))
        }
        .buttonStyle(.plain)
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(cardGreen))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer logic
    private func tick(_ now: Date) {
        guard runState == .running else {
            lastTick = nil
            return
        }

        if let last = lastTick {
            elapsed += now.timeIntervalSince(last)
        }
        lastTick = now

        if elapsed >= total {
            elapsed = total
            lastTick = nil
            runState = .completed
            modelContext.logCalmDown("Gentle Breathing", seconds: total)
        }
    }

    private func start() {
        elapsed = 0
        lastTick = nil
        runState = .running
    }

    private func togglePause() {
        lastTick = nil
        runState = (runState == .running) ? .paused : .running
    }

    private func toggleMascotPlayback() {
        switch runState {
        case .idle:
            start()
        case .running, .paused:
            togglePause()
        case .completed:
            break
        }
    }

    private var mascotAccessibilityLabel: String {
        switch runState {
        case .idle: return "Start breathing session"
        case .running: return "Pause breathing session"
        case .paused: return "Resume breathing session"
        case .completed: return "Breathing session complete"
        }
    }

    private func reset() {
        elapsed = 0
        lastTick = nil
        runState = .idle
        riveResetID = UUID()
    }
}

#Preview("Idle") {
    NavigationStack { BreathingSessionScreen(minutes: 1) }
}

#Preview("Completed") {
    NavigationStack { BreathingSessionScreen(minutes: 1, previewCompleted: true) }
}
