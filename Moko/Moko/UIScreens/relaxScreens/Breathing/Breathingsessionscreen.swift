//
//  BreathingSessionScreen.swift
//  Moko
//
//  Guided breathing timer. One screen with four states:
//  idle (Start) -> running (pause / reset) -> paused (play / reset) -> completed.
//  The ring fills as the session runs, and the dot pattern inside breathes
//  in and out: 4s inhale, 6s exhale.
//

import SwiftUI
import SwiftData
import Combine

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

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    // Breathing rhythm
    private let inhaleDuration: TimeInterval = 4
    private let exhaleDuration: TimeInterval = 6

    // Palette matching the rest of the app
    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)     // #365948
    private let trackGreen = Color(red: 203/255, green: 230/255, blue: 211/255) // light ring track
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762
    private let chipBg = Color(red: 237/255, green: 237/255, blue: 237/255)     // #EDEDED
    private let cream = Color(red: 252/255, green: 248/255, blue: 240/255)
    private let mist = Color(red: 214/255, green: 233/255, blue: 216/255)       // #D6E9D8

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

    /// 0.6 (fully exhaled) ... 1.0 (fully inhaled), eased
    private var breathScale: CGFloat {
        switch runState {
        case .idle, .completed:
            return 0.6
        case .running, .paused:
            let t = elapsed.truncatingRemainder(dividingBy: cycle)
            let p = t < inhaleDuration
                ? t / inhaleDuration
                : 1 - (t - inhaleDuration) / exhaleDuration
            let eased = p * p * (3 - 2 * p)
            return 0.6 + 0.4 * CGFloat(eased)
        }
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
        // Foreground only. Moko lives in .background so it can never change the layout size.
        VStack(spacing: 14) {
            header
            phaseCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { mokoBackground }
        // Timer + controls sit above the home indicator, always fully visible
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomPanel
        }
        .navigationTitle("\(minutes) min")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onReceive(ticker) { now in
            tick(now)
        }
        .sensoryFeedback(trigger: runState) { oldState, newState in
            switch (oldState, newState) {
            case (_, .completed):
                return .success

            case (.idle, .running):
                return .impact(weight: .medium)

            default:
                return .impact(weight: .light)
            }
        }
    }

    /// Animation is 600x750; showing it at that ratio means Moko is never cropped or oversized.
    private var mokoBackground: some View {
        ZStack {
            mist.ignoresSafeArea()      // same colour as the animation's background
            MokoLottieView(animationType: .meditation, size: nil)
                .aspectRatio(600.0 / 750.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .offset(y: -30)
                .clipped()
        }
    }

    // MARK: - Phase card
    private var phaseCard: some View {
        VStack(spacing: 6) {
            Text(phaseTitle)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.black)

            Text(phaseHint)
                .font(.system(size: 15))
                .foregroundColor(subtextGray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cream.opacity(0.9))
        }
    }

    // MARK: - Bottom panel (timer + controls)
    private var bottomPanel: some View {
        VStack(spacing: 14) {
            if runState != .completed {
                Text(timeText)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(cardGreen)
            }
            controls
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(cream.opacity(0.94))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Gentle Breathing")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)

            Text("Set your own meditation timer for a calmer mind")
                .font(.system(size: 15))
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
                    onFinish?()
                    dismiss()
                }
            }
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.2), value: runState)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
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

    private func reset() {
        elapsed = 0
        lastTick = nil
        runState = .idle
    }
}

#Preview("Idle") {
    NavigationStack { BreathingSessionScreen(minutes: 1) }
}

#Preview("Completed") {
    NavigationStack { BreathingSessionScreen(minutes: 1, previewCompleted: true) }
}
