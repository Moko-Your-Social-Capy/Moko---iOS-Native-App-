//
//  BreathingSessionScreen.swift
//  Moko
//
//  Guided breathing timer. One screen with four states:
//  idle (Start) -> running (pause / reset) -> paused (play / reset) -> completed.
//  The progress ring fills during the session; the capybara follows a 4s inhale / 6s exhale rhythm.
//  When the timer completes, a looping green pulse-and-check Lottie replaces the capybara.
//

import SwiftUI
import SwiftData
import Combine
import Lottie

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

    // A soft lime palette with a deep green accent.
    private let screenBg = Color(red: 0.96, green: 0.98, blue: 0.91)
    private let cardGreen = Color(red: 0.24, green: 0.38, blue: 0.20)
    private let subtextGray = Color(red: 0.36, green: 0.39, blue: 0.31)
    private let cream = Color(red: 0.99, green: 1.00, blue: 0.95)
    private let mist = Color(red: 0.90, green: 0.96, blue: 0.72)

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
        VStack(spacing: 0) {
            header
            Spacer(minLength: 12)
            breathingFocus
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(screenBg.ignoresSafeArea())
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
                Circle()
                    .fill(mist.opacity(0.58))
                    .frame(width: 250, height: 250)
                Circle()
                    .stroke(cardGreen.opacity(0.12), lineWidth: 5)
                    .frame(width: 270, height: 270)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        cardGreen,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 270, height: 270)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0 / 30.0), value: progress)
                    .accessibilityLabel("Session progress, \(Int(progress * 100)) percent")

                Group {
                    if runState == .completed {
                        CompletionPulseLottieView()
                            .frame(width: 250, height: 250)
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    } else {
                        MokoLottieView(animationType: .meditation, size: 200)
                            .frame(width: 200, height: 200)
                    }
                }
                .animation(.easeInOut(duration: 0.24), value: runState)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(runState == .completed ? "Breathing session complete" : "Moko breathing animation")

            Text(phaseTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(cardGreen)
                .contentTransition(.opacity)

            Text(phaseHint)
                .font(.system(size: 15))
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
                .fill(cream.opacity(0.96))
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


/// Plays the transparent green completion Lottie in a fixed, clipped viewport.
private struct CompletionPulseLottieView: UIViewRepresentable {
    private let animationName = "MokoComplete"

    final class Coordinator {
        weak var animationView: LottieAnimationView?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true

        let paths: [String?] = [
            "Resources/Animations",
            "Animations",
            nil
        ]

        for path in paths {
            guard let animation = LottieAnimation.named(
                animationName,
                bundle: .main,
                subdirectory: path
            ) else {
                continue
            }

            let animationView = LottieAnimationView(
                animation: animation,
                configuration: LottieConfiguration(renderingEngine: .mainThread)
            )
            animationView.translatesAutoresizingMaskIntoConstraints = false
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = .loop
            animationView.backgroundBehavior = .pauseAndRestore
            animationView.backgroundColor = .clear
            animationView.clipsToBounds = true
            context.coordinator.animationView = animationView

            container.addSubview(animationView)
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: container.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            print("MOKO SUCCESS: Loaded completion animation \(animationName) from \(path ?? "Bundle Root")")
            return container
        }

        print("MOKO ERROR: Could not find completion animation: \(animationName).json")
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Start after SwiftUI has inserted the representable, and recover if the
        // completion view is updated while the session is already complete.
        guard let animationView = context.coordinator.animationView,
              let animation = animationView.animation,
              !animationView.isAnimationPlaying else { return }
        animationView.play(
            fromFrame: animation.startFrame,
            toFrame: animation.endFrame,
            loopMode: .loop
        )
    }
}
