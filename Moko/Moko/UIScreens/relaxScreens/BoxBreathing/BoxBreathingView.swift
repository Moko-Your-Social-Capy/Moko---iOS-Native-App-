//
//  BoxBreathingView.swift
//  Moko
//
//  Relax → Box Breathing. Breathe in 4 s, hold 4 s, out 4 s, hold 4 s.
//  Each 4-second phase fills one side of the box.
//
//  How the timer works (good place to start debugging):
//  - `elapsed` is the only number that moves. Everything on screen (which side
//    is filling, the phase name, the countdown) is worked out from it.
//  - `.task(id: state)` runs `runClock()`. While running it calls `tick()`
//    about 30 times a second. Changing `state` stops the old loop and starts a new one.
//

import SwiftUI
import SwiftData

/// Box Breathing colours, shared with `BoxBreathingInfoView`.
enum BBColor {
    static let button     = MokoScreenTheme.Colors.dataVioletDeep   // buttons
    static let dark       = MokoScreenTheme.Colors.dataVioletDeep   // corner dots + filled box edges
    static let track      = MokoScreenTheme.Colors.surfaceLavender  // the empty box edges and arc
    static let title      = MokoScreenTheme.Colors.textTitle
    static let subtitle   = MokoScreenTheme.Colors.textMuted
    static let muted      = MokoScreenTheme.Colors.textBody
    static let titleBrown = MokoScreenTheme.Colors.textTitle
}

/// Where the session is right now.
private enum SessionState: Equatable {
    case idle        // Start screen
    case running
    case paused
    case finishing   // the short moment after the last phase, timer shows 0:00
    case complete    // "You did it!"
}

/// The four parts of one breath. The raw value (0–3) is also the box side that fills.
private enum BreathPhase: Int {
    case inhale, holdFull, exhale, holdEmpty

    var title: String {
        switch self {
        case .inhale: return "Inhale"
        case .exhale: return "Exhale"
        case .holdFull, .holdEmpty: return "Hold"
        }
    }
}

/// Corner positions of the box, measured from the Figma (inside a 245 x 238.4 frame).
private enum BoxGeometry {
    static let size = CGSize(width: 245, height: 238.4)
    static let topLeft     = CGPoint(x: 13.6,  y: 13.6)
    static let topRight    = CGPoint(x: 231.4, y: 13.6)
    static let bottomRight = CGPoint(x: 231.4, y: 224.8)
    static let bottomLeft  = CGPoint(x: 13.6,  y: 224.8)
}

/// One straight side of the box. Being a Shape lets us use `.trim` to fill it gradually.
private struct Edge: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

// MARK: - The screen

struct BoxBreathingView: View {
    // How many full boxes (cycles) to do. Chosen on the info sheet.
    let initialCycles: Int
    // Runs when the user taps "Complete" on the done screen.
    var onComplete: () -> Void = {}

    init(initialCycles: Int = 2, onComplete: @escaping () -> Void = {}) {
        self.initialCycles = initialCycles
        self.onComplete = onComplete
    }

    // Tells us when the app goes to the background, so we can pause.
    @Environment(\.scenePhase) private var scenePhase
    // The SwiftData database. Used to save the finished session.
    @Environment(\.modelContext) private var modelContext

    @State private var state: SessionState = .idle
    @State private var elapsed: TimeInterval = 0          // seconds since the session began
    @State private var elapsedAtResume: TimeInterval = 0  // elapsed when the current run started
    @State private var resumeDate: Date?                  // when the current run started

    // Seconds per phase. One cycle = 4 phases = 16 s.
    private let phaseLength: TimeInterval = 4
    private var cycleLength: TimeInterval { phaseLength * 4 }
    private var totalLength: TimeInterval { cycleLength * Double(initialCycles) }

    // MARK: Values worked out from `elapsed`

    /// Which phase we are in, counted from the very start (0, 1, 2, ...).
    private var stepIndex: Int {
        min(Int(elapsed / phaseLength), initialCycles * 4 - 1)
    }

    private var phase: BreathPhase {
        BreathPhase(rawValue: stepIndex % 4) ?? .inhale
    }

    /// 1-based index of the cycle currently in progress (clamped to initialCycles).
    private var currentCycle: Int {
        guard state == .running || state == .paused || state == .finishing else { return 1 }
        return min(Int(elapsed / cycleLength) + 1, initialCycles)
    }

    /// How full one side of the box is, from 0 (empty) to 1 (full).
    private func sideProgress(_ side: Int) -> CGFloat {
        if state == .finishing { return 1 }
        let inCycle = elapsed.truncatingRemainder(dividingBy: cycleLength) / phaseLength
        return CGFloat(min(max(inCycle - Double(side), 0), 1))
    }

    /// Seconds left in the current phase, e.g. "0:03".
    private var timeString: String {
        switch state {
        case .idle, .finishing, .complete:
            return "0:00"
        case .running, .paused:
            let intoPhase = elapsed.truncatingRemainder(dividingBy: phaseLength)
            let secondsLeft = Int((phaseLength - intoPhase).rounded(.up))
            return String(format: "0:%02d", secondsLeft)
        }
    }

    private var cyclesText: String {
        initialCycles == 1 ? "1 cycle" : "\(initialCycles) cycles"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            MokoBackdrop()

            VStack(spacing: 0) {
                if state == .complete {
                    completeContent.transition(.opacity)
                } else {
                    breathingContent.transition(.opacity)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Immersive session: keep the tab bar out of the way.
        .toolbar(.hidden, for: .tabBar)
        // Restarts every time `state` changes. See `runClock()`.
        .task(id: state) { await runClock() }
        // If the app leaves the screen (phone call, home button), pause the session.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active && state == .running { pause() }
        }
        // A light buzz at the start of each new phase.
        .sensoryFeedback(trigger: stepIndex) { old, new in
            (state == .running && new > old) ? .impact(weight: .light) : nil
        }
        // A "success" buzz when the session is done.
        .sensoryFeedback(trigger: state) { _, new in
            new == .complete ? .success : nil
        }
    }

    // MARK: Start / running / paused screen

    private var breathingContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 12)

            boxView
                .padding(.top, 28)

            phaseLabel
                .padding(.top, 20)

            timerArc
                .padding(.top, 28)

            Spacer(minLength: 12)

            controls
                .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Box Breathing")
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(BBColor.titleBrown)
                .padding(.horizontal, MokoScreenTheme.Space.page)

            HStack {
                Text(cyclesText)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(BBColor.muted)

                Spacer()

                // Cycle counter — only visible once the session has started
                if state == .running || state == .paused || state == .finishing {
                    Text("Cycle \(currentCycle) of \(initialCycles)")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(BBColor.muted)
                        .monospacedDigit()
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .animation(.easeInOut(duration: 0.25), value: state)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The box: 4 grey sides, 4 coloured sides on top that fill with `.trim`, and 4 corner dots.
    private var boxView: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { side in
                edge(side)
                    .stroke(BBColor.track, style: StrokeStyle(lineWidth: 9))
            }
            ForEach(0..<4, id: \.self) { side in
                edge(side)
                    .trim(from: 0, to: sideProgress(side))
                    .stroke(BBColor.dark, style: StrokeStyle(lineWidth: 9))
            }
            ForEach(0..<4, id: \.self) { corner in
                Circle()
                    .fill(BBColor.dark)
                    .frame(width: 27.2, height: 27.2)
                    .position(cornerPoint(corner))
            }
        }
        .frame(width: BoxGeometry.size.width, height: BoxGeometry.size.height)
        .accessibilityHidden(true)
    }

    /// Side 0 is the top, then right, bottom and left (clockwise).
    private func edge(_ side: Int) -> Edge {
        switch side {
        case 0:  return Edge(from: BoxGeometry.topLeft,     to: BoxGeometry.topRight)
        case 1:  return Edge(from: BoxGeometry.topRight,    to: BoxGeometry.bottomRight)
        case 2:  return Edge(from: BoxGeometry.bottomRight, to: BoxGeometry.bottomLeft)
        default: return Edge(from: BoxGeometry.bottomLeft,  to: BoxGeometry.topLeft)
        }
    }

    private func cornerPoint(_ corner: Int) -> CGPoint {
        [BoxGeometry.topLeft, BoxGeometry.topRight,
         BoxGeometry.bottomRight, BoxGeometry.bottomLeft][corner]
    }

    private var phaseLabel: some View {
        VStack(spacing: 0) {
            Text(phase.title)
                .mokoText(MokoScreenTheme.Typeface.title1)
                .tracking(-0.5)
                .foregroundStyle(BBColor.titleBrown)

            Text("For \(Int(phaseLength)) Seconds")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(BBColor.subtitle)
                .opacity(state == .idle ? 0 : 1)
        }
        .accessibilityElement(children: .combine)
    }

    /// A half circle with the countdown under it.
    private var timerArc: some View {
        Circle()
            .trim(from: 0.5, to: 1)
            .stroke(BBColor.track, lineWidth: 5)
            .frame(width: 195, height: 195)
            .frame(width: 200, height: 100, alignment: .top)
            .overlay(alignment: .bottom) {
                Text(timeString)
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .monospacedDigit()
                    .foregroundStyle(MokoScreenTheme.Colors.dataNumeral)
            }
    }

    /// The buttons change with the state: Start, or Pause/Resume + Reset.
    @ViewBuilder
    private var controls: some View {
        switch state {
        case .idle:
            BreathingPillButton(title: "Start", action: start)
                .padding(.horizontal, MokoScreenTheme.Space.page)

        case .running, .paused, .finishing:
            HStack {
                RoundIconButton(
                    systemName: state == .paused ? "play.fill" : "pause.fill",
                    label: state == .paused ? "Resume" : "Pause",
                    action: togglePause
                )
                Spacer(minLength: 0)
                RoundIconButton(systemName: "clock.arrow.circlepath", label: "Reset", action: reset)
            }
            .frame(width: 280)
            .disabled(state == .finishing)

        case .complete:
            EmptyView()
        }
    }

    private var completeContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(cyclesText)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(BBColor.muted)
            }
            .padding(.trailing, 39)
            .padding(.top, 40)

            MokoCompletionAnimation(ringDiameter: 190)

            Text("You did it!")
                .mokoText(MokoScreenTheme.Typeface.title2)
                .foregroundStyle(BBColor.titleBrown)
                .padding(.top, 8)

            Text("You took a moment to pause, breathe, and find your calm. Be proud of yourself for showing up!")
                .mokoText(MokoScreenTheme.Typeface.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(BBColor.titleBrown)
                .padding(.horizontal, 34)
                .padding(.top, 12)

            Spacer(minLength: 16)

            HStack(spacing: 25) {
                BreathingPillButton(title: "Complete") {
                    onComplete()
                }
                .frame(width: 192)

                RoundIconButton(systemName: "clock.arrow.circlepath", label: "Reset", action: reset)
            }
            .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Clock

    /// Runs inside `.task(id: state)`. SwiftUI cancels it when `state` changes.
    private func runClock() async {
        switch state {
        case .running:
            // About 30 updates a second keeps the box filling smoothly.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                tick()
            }
        case .finishing:
            // Show 0:00 and the full box for a moment, then the done screen.
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { state = .complete }
            // Save the session so it shows up in Insights and achievements.
            modelContext.logCalmDown("Box Breathing", seconds: totalLength)
        default:
            break
        }
    }

    /// Works out `elapsed` from the real clock, so pauses and slow frames never drift.
    private func tick() {
        guard state == .running, let began = resumeDate else { return }
        let now = elapsedAtResume + Date().timeIntervalSince(began)
        if now >= totalLength {
            elapsed = totalLength
            state = .finishing
        } else {
            elapsed = now
        }
    }

    // MARK: Buttons

    private func start() {
        elapsed = 0
        elapsedAtResume = 0
        resumeDate = Date()
        state = .running
    }

    private func pause() {
        // Update `elapsed` one last time so we resume from the exact spot.
        tick()
        if state == .running { state = .paused }
    }

    private func resume() {
        elapsedAtResume = elapsed
        resumeDate = Date()
        state = .running
    }

    private func togglePause() {
        state == .running ? pause() : resume()
    }

    private func reset() {
        elapsed = 0
        elapsedAtResume = 0
        resumeDate = nil
        withAnimation(.easeInOut(duration: 0.3)) { state = .idle }
    }
}

/// The big rounded "Start" / "Complete" button.
private struct BreathingPillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .mokoText(MokoScreenTheme.Typeface.section)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 63)
                .background(Capsule().fill(BBColor.button))
        }
        .buttonStyle(.plain)
    }
}

/// A round button with an icon (pause, play, reset).
private struct RoundIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 63, height: 63)
                .background(Circle().fill(BBColor.button))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    NavigationStack { BoxBreathingView() }
}
