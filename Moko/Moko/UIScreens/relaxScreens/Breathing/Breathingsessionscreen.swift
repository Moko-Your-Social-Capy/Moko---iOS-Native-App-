
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
        ZStack {
            screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                header
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                Spacer(minLength: 16)

                ring
                    .frame(width: 270, height: 270)

                VStack(spacing: 8) {
                    Text(phaseTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)

                    Text(phaseHint)
                        .font(.system(size: 15))
                        .foregroundColor(subtextGray)
                        .multilineTextAlignment(.center)
                        .frame(height: 40, alignment: .top)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 36)

                if runState != .completed {
                    Text(timeText)
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(cardGreen)
                        .padding(.top, 4)
                }

                Spacer(minLength: 16)

                controls
                    .padding(.bottom, 28)
            }
        }
        .onReceive(ticker) { now in
            tick(now)
        }
        // Haptics, SwiftUI only (iOS 17+)
        .sensoryFeedback(trigger: runState) { oldState, newState in
            switch (oldState, newState) {
            case (_, .completed):  return .success
            case (.idle, .running): return .impact(weight: .medium)
            default:               return .impact(weight: .light)
            }
        }
    }

    // MARK: - Top bar and header
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(chipBg))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(minutes) min")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(cardGreen)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(Capsule().fill(trackGreen.opacity(0.7)))
        }
    }

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

    // MARK: - Progress ring with breathing dots
    private var ring: some View {
        ZStack {
            Circle()
                .stroke(trackGreen, lineWidth: 14)

            Circle()
                .trim(from: 0, to: runState == .completed ? 1 : progress)
                .stroke(cardGreen, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if runState == .completed {
                completedBadge
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                breathingVisual
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: runState)
    }

    private var breathingVisual: some View {
        ZStack {
            // Soft glow that swells with the breath
            Circle()
                .fill(
                    RadialGradient(
                        colors: [cardGreen.opacity(0.22), cardGreen.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 115
                    )
                )
                .frame(width: 230, height: 230)
                .scaleEffect(breathScale)

            BreathingDotsIcon(color: cardGreen)
                .frame(width: 130, height: 130)
                .scaleEffect(breathScale)
        }
    }

    private var completedBadge: some View {
        ZStack {
            Circle()
                .fill(trackGreen)
                .frame(width: 200, height: 200)

            Circle()
                .fill(cardGreen)
                .frame(width: 156, height: 156)

            Image(systemName: "checkmark.circle")
                .font(.system(size: 86, weight: .regular))
                .foregroundColor(cream)
        }
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
                    circleButton(systemName: runState == .running ? "pause.fill" : "play.fill") { togglePause() }
                }
                .padding(.horizontal, 12)

            case .completed:
                primaryButton("Complete") {
                    onFinish?()
                    dismiss()
                }
            }
        }
        .padding(.horizontal, 28)
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
    BreathingSessionScreen(minutes: 1)
}

#Preview("Completed") {
    BreathingSessionScreen(minutes: 1, previewCompleted: true)
}
