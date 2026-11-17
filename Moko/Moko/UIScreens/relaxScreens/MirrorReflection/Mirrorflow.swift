//
//  MirrorFlow.swift
//  Moko
//
//  The Mirror Reflection screens after the user picks "mirror" or "camera":
//  prep checklist → 2:00 affirmation timer → "You did it!".
//  RelaxScreen pushes them one by one (see `RelaxRoute`).
//
//  This file also holds the parts both the mirror and camera versions share:
//  colours, header, buttons, and `MirrorSessionClock` (the 2:00 timer).
//  The affirmation lines come from MirrorAffirmations.swift (8 lines, 15 s each).
//

import SwiftUI
import SwiftData

// MARK: - Shared palette

enum MirrorPalette {
    static let accent = MokoScreenTheme.Colors.dataVioletDeep     // buttons, ring, icons
    static let accentSoft = MokoScreenTheme.Colors.dataViolet     // start of the ring gradient
    static let track = MokoScreenTheme.Colors.surfaceLavender     // empty ring, chips, soft fills
    static let title = MokoScreenTheme.Colors.textTitle
    static let subtext = MokoScreenTheme.Colors.textBody
}

// MARK: - Shared 2:00 clock

/// The 2-minute timer used by both `MirrorTimerScreen` and `CameraTimerScreen`.
///
/// How it works (good place to start debugging):
/// - The screen keeps one clock in `@State` and calls `run()` from `.task(id: clock.runState)`.
/// - `run()` adds the real time that passed about 30 times a second, but only while running.
/// - Pausing changes `runState`, which cancels the task, so time stops being added.
@Observable
final class MirrorSessionClock {
    enum RunState {
        case idle, running, paused, completed
    }

    /// The session is always 2 minutes: 8 affirmations × 15 seconds.
    static let total: TimeInterval = 120

    private(set) var runState: RunState = .idle
    private(set) var elapsed: TimeInterval = 0

    /// 0 at the start, 1 at the end. Drives the ring / card outline.
    var progress: Double { min(1, elapsed / Self.total) }

    /// Time left, e.g. "1:45".
    var timeText: String {
        let remaining = max(0, Int(ceil(Self.total - elapsed)))
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    /// Short status for the title / chip.
    var statusText: String {
        switch runState {
        case .idle:              return "Let’s Start"
        case .running, .paused:  return "Keep Going!"
        case .completed:         return "Well done"
        }
    }

    /// Which affirmation to show: a new one every 15 seconds.
    func lineIndex(count: Int) -> Int {
        max(0, min(count - 1, Int(elapsed / MirrorAffirmationStore.slotDuration)))
    }

    func start() {
        elapsed = 0
        runState = .running
    }

    func togglePause() {
        runState = (runState == .running) ? .paused : .running
    }

    func reset() {
        elapsed = 0
        runState = .idle
    }

    /// Call from `.task(id: clock.runState)`.
    /// Returns `true` only when the 2 minutes have just finished, so the screen can save the session.
    func run() async -> Bool {
        guard runState == .running else { return false }
        var lastTick = Date()
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(33))
            // Paused or reset while we slept: do not add that time.
            guard !Task.isCancelled else { return false }
            let now = Date()
            elapsed += now.timeIntervalSince(lastTick)
            lastTick = now
            if elapsed >= Self.total {
                elapsed = Self.total
                runState = .completed
                return true
            }
        }
        return false
    }
}

// MARK: - Shared views

/// "Mirror Reflection" title with its subtitle.
struct MirrorHeader: View {
    var centered = false

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 4) {
            Text("Mirror Reflection")
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(MirrorPalette.title)

            Text("A self-reflective confidence practice")
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MirrorPalette.subtext)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

/// The big rounded button ("Start", "Continue", "Done").
struct MirrorPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(MirrorPalette.accent))
        }
        .buttonStyle(.plain)
    }
}

/// A round icon button (pause, play, reset).
struct MirrorCircleButton: View {
    let systemName: String
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(MirrorPalette.accent))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        // VoiceOver reads this instead of the icon name.
        .accessibilityLabel(label)
    }
}

/// The timer buttons, shared by both timer screens:
/// Start → Pause/Play + Reset → Continue + Reset.
struct MirrorTimerControls: View {
    let clock: MirrorSessionClock
    var onContinue: () -> Void
    // The camera screen also restarts the camera on reset, so the caller decides.
    var onReset: () -> Void

    var body: some View {
        Group {
            switch clock.runState {
            case .idle:
                MirrorPrimaryButton(title: "Start", action: clock.start)

            case .running, .paused:
                HStack {
                    MirrorCircleButton(
                        systemName: clock.runState == .running ? "pause.fill" : "play.fill",
                        label: clock.runState == .running ? "Pause" : "Resume",
                        action: clock.togglePause
                    )
                    Spacer()
                    MirrorCircleButton(systemName: "arrow.counterclockwise", label: "Reset", action: onReset)
                }
                .padding(.horizontal, 8)

            case .completed:
                HStack(spacing: 16) {
                    MirrorPrimaryButton(title: "Continue", action: onContinue)
                    MirrorCircleButton(systemName: "arrow.counterclockwise", label: "Reset", action: onReset)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: clock.runState)
        // A buzz on start, pause/resume, and a "success" buzz when done.
        .sensoryFeedback(trigger: clock.runState) { oldState, newState in
            switch (oldState, newState) {
            case (_, .completed):    return .success
            case (.idle, .running):  return .impact(weight: .medium)
            default:                 return .impact(weight: .light)
            }
        }
    }
}

// MARK: - Prep screen (four points, then Continue)

/// "Get ready" checklist. The points fade in one by one, and the picture
/// (`hero`) glows a little brighter with each one.
struct MirrorPrepScreen<Hero: View>: View {
    let title: String
    let listTitle: String
    let items: [String]
    var onContinue: () -> Void
    /// The picture at the top. It gets 0...1: how many points have appeared so far.
    private let hero: (Double) -> Hero

    // How many points are visible right now.
    @State private var revealed = 0

    init(title: String,
         listTitle: String = "Before you begin",
         items: [String],
         onContinue: @escaping () -> Void,
         @ViewBuilder hero: @escaping (Double) -> Hero) {
        self.title = title
        self.listTitle = listTitle
        self.items = items
        self.onContinue = onContinue
        self.hero = hero
    }

    var body: some View {
        ZStack {
            MokoBackdrop()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    MirrorHeader()
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 18)

                    hero(Double(revealed) / Double(max(items.count, 1)))
                        .padding(.top, 8)

                    Text(title)
                        .mokoText(MokoScreenTheme.Typeface.title2)
                        .foregroundStyle(MirrorPalette.title)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, MokoScreenTheme.Space.page)

                    Text(listTitle)
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(MirrorPalette.subtext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 24)

                    bulletCard
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 10)

                    // Set expectations: the microphone is part of the practice,
                    // and it only listens for voice level, not words.
                    Text("Moko will listen while you say each line. If you pause, Moko will gently nudge you to continue.")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MirrorPalette.subtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 14)
                        .opacity(revealed == items.count ? 1 : 0)

                    Text("Take your time. Continue when you’re ready.")
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(MirrorPalette.subtext)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .opacity(revealed == items.count ? 1 : 0)
                }
            }
        }
        // Pins the Continue button to the bottom, above the home indicator.
        .safeAreaInset(edge: .bottom) {
            MirrorPrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 12)
        }
        // `.task` runs when the screen appears and stops by itself if the user leaves early.
        .task {
            await revealPoints()
        }
    }

    // MARK: Bullet points

    private var bulletCard: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                bulletRow(items[index], index: index)

                // Thin divider between rows (not after the last one).
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.leading, 62)
                        .opacity(index < revealed ? 1 : 0)
                }
            }
        }
        .padding(.vertical, 4)
        .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card, style: .continuous))
        .mokoCard()
    }

    private func bulletRow(_ text: String, index: Int) -> some View {
        let isVisible = index < revealed

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MirrorPalette.track.opacity(0.8))
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(MirrorPalette.accent)
                    .frame(width: 10, height: 10)
            }

            Text(text)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MirrorPalette.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        // Hidden rows sit 10 pt lower, so they slide up a little as they fade in.
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        // VoiceOver reads the row as one item.
        .accessibilityElement(children: .combine)
    }

    /// Shows the points one after another so each gets a moment of attention.
    private func revealPoints() async {
        guard revealed == 0 else { return }

        // Short pause before the first point, then 0.22 s between points.
        try? await Task.sleep(for: .milliseconds(250))
        for index in items.indices {
            if index > 0 {
                try? await Task.sleep(for: .milliseconds(220))
            }
            // Stop if the user already left this screen.
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                revealed = index + 1
            }
        }
    }
}

// MARK: - Mirror timer screen (fixed 2:00)

/// The timer for the "real mirror" version: affirmations on top, a ring in the middle.
struct MirrorTimerScreen: View {
    var onContinue: () -> Void

    // The 2:00 clock. See `MirrorSessionClock`.
    @State private var clock = MirrorSessionClock()
    // Listens for the user's voice and nudges them when they go quiet.
    @State private var voice = MirrorVoiceCoach()
    // Opens the "edit affirmations" sheet.
    @State private var isEditingAffirmations = false
    // The SwiftData database. Used to save the finished session.
    @Environment(\.modelContext) private var modelContext

    // The shared affirmation lines. It is @Observable, so this screen redraws when they are edited.
    private let affirmationStore = MirrorAffirmationStore.shared

    /// Before Start: a preview of the lines. After Start: only the current line.
    private var showsCurrentLine: Bool { clock.runState != .idle }

    var body: some View {
        ZStack {
            MokoBackdrop()

            VStack(spacing: 0) {
                MirrorHeader()
                    .overlay(alignment: .topTrailing) {
                        // Hidden while running: the timer would keep going behind the sheet.
                        if clock.runState != .running {
                            MirrorEditAffirmationsButton {
                                isEditingAffirmations = true
                            }
                        }
                    }
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 18)

                affirmationsArea
                    .padding(.top, 22)
                    .padding(.horizontal, MokoScreenTheme.Space.page)

                statusArea
                    .padding(.top, 18)

                MirrorTimerRing(
                    progress: clock.progress,
                    isRunning: clock.runState == .running,
                    isCompleted: clock.runState == .completed,
                    isSpeaking: voice.isSpeaking,
                    voiceLevel: voice.audioLevel
                )
                .frame(width: 230, height: 230)
                .padding(.top, 10)

                Text(clock.timeText)
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .monospacedDigit()   // digits all the same width, so the text does not jump
                    .foregroundStyle(MirrorPalette.accent)
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                // Before Start, explain why the microphone will turn on.
                if clock.runState == .idle {
                    Text("Say each line out loud. Moko will listen and gently nudge you if you pause.")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MirrorPalette.subtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom) {
            MirrorTimerControls(clock: clock, onContinue: onContinue, onReset: clock.reset)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 12)
        }
        // Immersive session: keep the tab bar out of the way.
        .toolbar(.hidden, for: .tabBar)
        // Ask for the microphone while the user is still reading the lines.
        .task {
            await voice.prepare()
        }
        // Restarts every time the run state changes. See `MirrorSessionClock.run()`.
        .task(id: clock.runState) {
            switch clock.runState {
            case .running:
                // Start listening before the clock starts, so the first line is heard too.
                await voice.startListening()
            case .idle, .paused, .completed:
                voice.stopListening()
            }

            if await clock.run() {
                // Save the session so it shows up in Insights and achievements.
                voice.stopListening()
                modelContext.logCalmDown("Mirror Reflection", seconds: MirrorSessionClock.total)
            }
        }
        // A new affirmation is a fresh chance to start speaking before a nudge.
        .onChange(of: clock.lineIndex(count: affirmationStore.quotes.count)) { _, _ in
            voice.affirmationChanged()
        }
        // A very soft tap when Moko nudges, so it is felt without being loud.
        .sensoryFeedback(.impact(weight: .light), trigger: voice.nudgeCount)
        .onDisappear {
            voice.stop()
        }
        .sheet(isPresented: $isEditingAffirmations) {
            MirrorAffirmationsSheet(store: affirmationStore)
        }
    }

    // MARK: Status + voice

    /// The status line normally shows "Keep Going!" next to the listening pill.
    /// When the user goes quiet, Moko replaces it with a small speech bubble.
    private var statusArea: some View {
        ZStack {
            if let nudge = voice.nudge {
                MirrorNudgeBubble(text: nudge)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            } else {
                HStack(spacing: 10) {
                    Text(clock.statusText)
                        .mokoText(MokoScreenTheme.Typeface.title2)
                        .foregroundStyle(MirrorPalette.title)

                    if clock.runState == .running || voice.isUnavailable {
                        MirrorVoicePill(
                            state: voice.state,
                            isSpeaking: voice.isSpeaking,
                            level: voice.audioLevel
                        )
                    }
                }
                .transition(.opacity)
            }
        }
        // Fixed height keeps the ring from jumping when the bubble appears.
        .frame(height: 46)
        .animation(.easeInOut(duration: 0.25), value: voice.nudge)
    }

    // MARK: Affirmations

    private var affirmationsArea: some View {
        ZStack {
            if showsCurrentLine {
                currentAffirmation
                    .transition(.opacity)
            } else {
                affirmationWindow
                    .transition(.opacity)
            }
        }
        // Fixed height, so swapping the list for one line does not move the ring.
        .frame(height: MirrorAffirmationsWindow.height)
        .animation(.easeInOut(duration: 0.35), value: showsCurrentLine)
    }

    /// The current line, big. It crossfades into the next one every 15 seconds.
    private var currentAffirmation: some View {
        let index = clock.lineIndex(count: affirmationStore.quotes.count)

        return ZStack {
            Text(affirmationStore.quotes[index])
                .mokoText(MokoScreenTheme.Typeface.title2)
                .foregroundStyle(MirrorPalette.title)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // A new `id` makes SwiftUI treat it as a new view, so the transition plays.
                .id(index)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: index)
    }

    /// All lines in a small scrolling window, shown before Start.
    private var affirmationWindow: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(affirmationStore.quotes.indices, id: \.self) { index in
                    Text(affirmationStore.quotes[index])
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(MirrorPalette.subtext)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
        .defaultScrollAnchor(.top)
    }
}

/// Progress ring with a glowing end dot and a breathing Moko in the middle.
/// When the time is up, Moko is replaced by the completion animation.
struct MirrorTimerRing: View {
    var progress: Double
    var isRunning: Bool
    var isCompleted: Bool
    var isSpeaking: Bool = false
    var voiceLevel: Double = 0

    // The phone setting "Reduce Motion". If it is on, the glow and Moko stay still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Flipped once on appear. `repeatForever` then animates it back and forth on its own.
    @State private var pulse = false

    private let diameter: CGFloat = 206
    private let lineWidth: CGFloat = 16

    /// Where the end dot sits, in radians. -π/2 is 12 o'clock.
    private var endAngle: Double {
        -Double.pi / 2 + 2 * Double.pi * progress
    }

    var body: some View {
        ZStack {
            // Soft glow, stronger while running.
            Circle()
                .fill(
                    RadialGradient(
                        // The glow gets a little brighter as the user's voice rises.
                        colors: [MirrorPalette.accent.opacity(isRunning ? 0.18 + voiceLevel * 0.16 : 0.10),
                                 MirrorPalette.accent.opacity(0)],
                        center: .center,
                        startRadius: 40,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .scaleEffect(isRunning ? (pulse ? 1.06 : 0.94) : 1)

            // Empty track
            Circle()
                .stroke(MirrorPalette.track, lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Filled part. The -90° turn makes it start at 12 o'clock.
            Circle()
                .trim(from: 0, to: isCompleted ? 1 : CGFloat(progress))
                .stroke(
                    AngularGradient(
                        colors: [MirrorPalette.accentSoft, MirrorPalette.accent],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(isCompleted ? 360 : max(1, 360 * progress))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)

            // White dot at the end of the filled part.
            if !isCompleted && progress > 0.005 {
                Circle()
                    .fill(Color.white)
                    .frame(width: lineWidth * 0.95, height: lineWidth * 0.95)
                    .overlay(Circle().stroke(MirrorPalette.accent, lineWidth: 3))
                    .shadow(color: MirrorPalette.accent.opacity(0.4), radius: 6)
                    .offset(
                        x: CGFloat(cos(endAngle)) * diameter / 2,
                        y: CGFloat(sin(endAngle)) * diameter / 2
                    )
            }

            // Middle
            if isCompleted {
                MokoCompletionAnimation(ringDiameter: 140)
                    .transition(.opacity)
            } else {
                // Moko sits in the middle and breathes with the user's voice.
                MokoMirrorMascot(size: 72, isSpeaking: isSpeaking, level: voiceLevel)
                    .scaleEffect(1.5)
                    .scaleEffect(isRunning ? (pulse ? 1.05 : 0.95) : 1)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isCompleted)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Done screen

struct MirrorCompletionScreen: View {
    var onDone: () -> Void

    var body: some View {
        // The shared completion screen with mirror-reflection-specific content.
        // RelaxCompletionScreen plays the GPay sound automatically on appear.
        RelaxCompletionScreen(
            title: "You did it!",
            subtitle: "You took a moment to look at yourself with kindness and appreciate the person you are.",
            buttonLabel: "Done",
            accent: MirrorPalette.accent,
            onContinue: onDone
        )
        // Open the mint panels once to mark this moment of kindness.
        .mokoCompletionReveal()
    }
}

#Preview("Mirror timer") {
    MirrorTimerScreen(onContinue: {})
}

#Preview("Done") {
    MirrorCompletionScreen(onDone: {})
}
