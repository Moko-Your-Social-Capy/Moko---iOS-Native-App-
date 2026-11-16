//
//  BreathingSessionScreen.swift
//  Moko
//
//  Relax → Breathing. A timer the user sets in minutes.
//  States: idle (Start) → running (pause / reset) → paused (play / reset) → completed.
//
//  How the timer works (good place to start debugging):
//  - `elapsed` is the only number that moves. The ring, the countdown, the
//    "Inhale / Exhale" text and the mascot's size are all worked out from it.
//  - `.task(id: runState)` runs `runClock()`. While running it adds the real
//    time that passed about 30 times a second. Changing `runState` stops the
//    old loop, so pausing simply stops adding time.
//

import SwiftUI
import SwiftData

struct BreathingSessionScreen: View {
    let minutes: Int
    // Runs when the user taps Complete. If nil, the screen just closes itself.
    var onFinish: (() -> Void)? = nil

    // Closes this screen (used when there is no `onFinish`).
    @Environment(\.dismiss) private var dismiss
    // The SwiftData database. Used to save the finished session.
    @Environment(\.modelContext) private var modelContext
    // The phone setting "Reduce Motion". If it is on, the mascot stays still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    fileprivate enum RunState {
        case idle, running, paused, completed
    }

    @State private var runState: RunState
    // Seconds of breathing done so far (pauses not counted).
    @State private var elapsed: TimeInterval = 0

    // One breath = 4 s in + 6 s out.
    private let inhaleDuration: TimeInterval = 4
    private let exhaleDuration: TimeInterval = 6

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let bodyText = MokoScreenTheme.Colors.textBody
    private let mist = MokoScreenTheme.Colors.surfaceLavender

    /// `previewCompleted` is only for the Xcode preview of the done screen.
    init(minutes: Int, onFinish: (() -> Void)? = nil, previewCompleted: Bool = false) {
        self.minutes = max(1, minutes)
        self.onFinish = onFinish
        // `_runState` is the @State wrapper itself. This is how you give @State a starting value in init.
        _runState = State(initialValue: previewCompleted ? .completed : .idle)
    }

    // MARK: - Values worked out from `elapsed`

    private var total: TimeInterval { TimeInterval(minutes * 60) }
    private var cycle: TimeInterval { inhaleDuration + exhaleDuration }
    /// 0 at the start, 1 at the end. Drives the ring.
    private var progress: Double { min(1, elapsed / total) }

    private var remainingSeconds: Int { max(0, Int(ceil(total - elapsed))) }
    /// Time left, e.g. "4:59".
    private var timeText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    /// True during the first 4 seconds of every 10-second breath.
    private var isInhaling: Bool {
        elapsed.truncatingRemainder(dividingBy: cycle) < inhaleDuration
    }

    /// How big the mascot is right now: it grows while you breathe in
    /// and shrinks while you breathe out.
    /// It is worked out from the session clock, so pause, resume and reset
    /// always line up with the timer.
    private var breathScale: CGFloat {
        guard !reduceMotion else { return 1 }
        // Where we are inside one inhale + exhale loop, in seconds.
        let phase = elapsed.truncatingRemainder(dividingBy: cycle)
        // 0 → 1 while breathing in, 1 → 0 while breathing out.
        let fraction = isInhaling ? phase / inhaleDuration : 1 - (phase - inhaleDuration) / exhaleDuration
        // The cosine curve makes the size change start and end gently, like real breath.
        let eased = (1 - cos(.pi * fraction)) / 2
        return 0.94 + 0.06 * CGFloat(eased)
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
        ZStack {
            // Show the shared completion screen when done, overlaid on the session UI.
            if runState == .completed {
                // Gentle Breathing specific content passed to the shared completion screen.
                // RelaxCompletionScreen plays the GPay sound automatically on appear.
                RelaxCompletionScreen(
                    title: "Well done",
                    subtitle: "You breathed mindfully for \(minutes) min. Every breath was a step toward calm.",
                    accent: accent,
                    onContinue: {
                        if let onFinish {
                            onFinish()
                        } else {
                            dismiss()
                        }
                    }
                )
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 12)
                    breathingFocus
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MokoBackdrop())
                // Pins the timer card to the bottom, above the home indicator.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomPanel
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                // Immersive session: keep the tab bar out of the way.
                .toolbar(.hidden, for: .tabBar)
                .transition(.opacity)
            }
        }
        // Reveal the finished session once, without interrupting breathing cues.
        .mokoCompletionReveal(isPresented: runState == .completed)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        // Immersive session: keep the tab bar out of the way.
        .toolbar(.hidden, for: .tabBar)
        // Restarts every time `runState` changes. See `runClock()`.
        .task(id: runState) { await runClock() }
        // A buzz on start, pause/resume, and a "success" buzz when done.
        .sensoryFeedback(trigger: runState) { oldState, newState in
            switch (oldState, newState) {
            case (_, .completed): return .success
            case (.idle, .running): return .impact(weight: .medium)
            default: return .impact(weight: .light)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: runState == .completed)
    }

    /// The mascot inside the progress ring, with the phase text under it.
    private var breathingFocus: some View {
        VStack(spacing: 10) {
            ZStack {
                if runState == .completed {
                    MokoCompletionAnimation(ringDiameter: 190)
                        .transition(.opacity)
                } else {
                    // Soft disc behind the mascot.
                    Circle()
                        .fill(mist.opacity(0.58))
                        .frame(width: 250, height: 250)
                    // Empty ring track.
                    Circle()
                        .stroke(accent.opacity(0.12), lineWidth: 5)
                        .frame(width: 270, height: 270)

                    // Filled part of the ring. `.trim` draws only 0…progress of the circle,
                    // and the -90° turn makes it start at 12 o'clock instead of 3 o'clock.
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 270, height: 270)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0 / 30.0), value: progress)
                        .accessibilityLabel("Session progress, \(Int(progress * 100)) percent")

                    Image("MokoMascot")
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                        .frame(width: 250, height: 250)
                        // Grows from the feet up, so the mascot looks like it is filling with air.
                        .scaleEffect(breathScale, anchor: .bottom)
                        .accessibilityHidden(true)
                        // Tapping the mascot starts, pauses or resumes the timer.
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
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(accent)
                // Fade between "Inhale" and "Exhale" instead of snapping.
                .contentTransition(.opacity)

            Text(phaseHint)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(bodyText)
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
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .monospacedDigit()   // digits all the same width, so the text does not jump
                    .foregroundStyle(accent)
            }
            controls
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .mokoCard()
        .padding(.horizontal, MokoScreenTheme.Space.page)
        .padding(.bottom, 8)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Gentle Breathing")
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            Text("Set your own meditation timer for a calmer mind")
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(bodyText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    /// The buttons change with the state: Start, Reset + Pause/Play, or Complete.
    private var controls: some View {
        Group {
            switch runState {
            case .idle:
                primaryButton("Start", action: start)

            case .running, .paused:
                HStack {
                    circleButton(systemName: "arrow.counterclockwise", label: "Reset", action: reset)
                    Spacer()
                    circleButton(
                        systemName: runState == .running ? "pause.fill" : "play.fill",
                        label: runState == .running ? "Pause" : "Resume",
                        action: togglePause
                    )
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
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(accent))
        }
        .buttonStyle(.plain)
    }

    private func circleButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(accent))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        // VoiceOver reads this instead of the icon name.
        .accessibilityLabel(label)
    }

    // MARK: - Clock

    /// Runs inside `.task(id: runState)`. SwiftUI cancels it when `runState` changes.
    private func runClock() async {
        guard runState == .running else { return }
        var lastTick = Date()
        // About 30 updates a second keeps the ring and the mascot smooth.
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(33))
            // Paused or reset while we slept: do not add that time.
            guard !Task.isCancelled else { return }
            let now = Date()
            // Add the real time that passed, so slow frames never make the timer drift.
            advance(by: now.timeIntervalSince(lastTick))
            lastTick = now
        }
    }

    private func advance(by seconds: TimeInterval) {
        elapsed += seconds
        if elapsed >= total {
            elapsed = total
            runState = .completed
            // Save the session so it shows up in Insights and achievements.
            modelContext.logCalmDown("Gentle Breathing", seconds: total)
        }
    }

    // MARK: - Buttons

    private func start() {
        elapsed = 0
        runState = .running
    }

    private func togglePause() {
        runState = (runState == .running) ? .paused : .running
    }

    private func reset() {
        elapsed = 0
        runState = .idle
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
}

#Preview("Idle") {
    NavigationStack { BreathingSessionScreen(minutes: 1) }
}

#Preview("Completed") {
    NavigationStack { BreathingSessionScreen(minutes: 1, previewCompleted: true) }
}
