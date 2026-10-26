import SwiftUI

// MARK: - Small helper types

private enum SessionState: Equatable {
    case idle        // Start screen
    case running
    case paused
    case finishing   // CHANGED: the short moment after the last phase, timer shows 0:00
    case complete    // "You did it!"
}

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
    /// Number of full breathing cycles (16 seconds each). The user picks it on the Start screen.
    @State private var cycles: Int = 2
    /// Called when the user taps "Complete".
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var state: SessionState = .idle
    @State private var elapsed: TimeInterval = 0          // seconds since the session began
    @State private var elapsedAtResume: TimeInterval = 0  // elapsed when the current run started
    @State private var resumeDate: Date?                  // when the current run started

    private let phaseLength: TimeInterval = 4
    private var cycleLength: TimeInterval { phaseLength * 4 }
    private var totalLength: TimeInterval { cycleLength * Double(cycles) }

    // MARK: Values worked out from `elapsed`

    /// 0 ... (cycles * 4 - 1): which 4-second step we are in.
    private var stepIndex: Int {
        min(Int(elapsed / phaseLength), cycles * 4 - 1)
    }

    private var phase: BreathPhase {
        BreathPhase(rawValue: stepIndex % 4) ?? .inhale
    }

    /// How full (0...1) each side of the box is. Side 0 = top, 1 = right, 2 = bottom, 3 = left.
    private func sideProgress(_ side: Int) -> CGFloat {
        if state == .finishing { return 1 }     // CHANGED: box stays completely full at the very end
        let inCycle = elapsed.truncatingRemainder(dividingBy: cycleLength) / phaseLength
        return CGFloat(min(max(inCycle - Double(side), 0), 1))
    }

    // CHANGED: the timer now counts DOWN inside every phase: 0:04, 0:03, 0:02, 0:01, then the
    // next phase starts again at 0:04. It shows 0:00 on the Start screen and after the last phase.
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
        cycles == 1 ? "1 CYCLE" : "\(cycles) CYCLES"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BBColor.background.ignoresSafeArea()

            if state == .complete {
                completeContent.transition(.opacity)
            } else {
                breathingContent.transition(.opacity)
            }
        }
        // Native navigation bar: the system back button shows automatically when this
        // screen is pushed. It is hidden on the final "You did it!" screen.
        .navigationBarBackButtonHidden(state == .complete)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            // Centred title that only appears on the final screen
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Box Breathing")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(BBColor.title)
                    Text("4 Seconds Breathing Pattern")
                        .font(.system(size: 12))
                        .foregroundStyle(BBColor.subtitle)
                }
                .opacity(state == .complete ? 1 : 0)
            }
        }
        // The clock: runs only while needed (restarts / cancels when state changes)
        .task(id: state) { await runClock() }
        // Pause automatically if the app goes to the background
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active && state == .running { pause() }
        }
        // Haptics: light tap on every new phase, success buzz at the end
        .sensoryFeedback(trigger: stepIndex) { old, new in
            (state == .running && new > old) ? .impact(weight: .light) : nil
        }
        .sensoryFeedback(trigger: state) { _, new in
            new == .complete ? .success : nil
        }
    }

    // MARK: Start / running / paused screen

    private var breathingContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 18)

            boxView
                .padding(.top, 37)

            phaseLabel
                .padding(.top, 24)

            timerArc
                .padding(.top, 38)

            Spacer(minLength: 16)

            controls
                .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Box Breathing")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(BBColor.title)

            HStack(alignment: .firstTextBaseline) {
                Text("4 Seconds Breathing Pattern")
                    .font(.system(size: 12))
                    .foregroundStyle(BBColor.subtitle)
                Spacer()
                cyclesLabel
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .padding(.trailing, 39)
    }

    /// The choices in the menu. Change these numbers to offer different options.
    /// The choices in the menu. Change these numbers to offer different options.
    private static let cycleOptions = [2, 4, 6, 8, 10]

    @ViewBuilder
    private var cyclesLabel: some View {
        if state == .idle {
            // Start screen: tapping opens a native iOS menu
            Menu {
                Picker("Cycles", selection: $cycles) {
                    ForEach(Self.cycleOptions, id: \.self) { count in
                        Text("\(count) cycles").tag(count)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(cyclesText)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(BBColor.muted)
            }
            .accessibilityLabel("Number of cycles")
            .accessibilityValue(cyclesText)
        } else {
            // While running, paused and on the final screen: plain text, no changes allowed
            Text(cyclesText)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(BBColor.muted)
        }
    }

    // The box that fills up, side by side, clockwise
    private var boxView: some View {
        ZStack {
            // 1. empty grey sides
            ForEach(0..<4, id: \.self) { side in
                edge(side)
                    .stroke(BBColor.track, style: StrokeStyle(lineWidth: 9))
            }
            // 2. green fill on top, trimmed to the current progress
            ForEach(0..<4, id: \.self) { side in
                edge(side)
                    .trim(from: 0, to: sideProgress(side))
                    .stroke(BBColor.dark, style: StrokeStyle(lineWidth: 9))
            }
            // 3. the four corner dots
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
                .font(.system(size: 40, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(.black)

            // Kept in the layout (just invisible) on the Start screen so nothing jumps
            Text("For \(Int(phaseLength)) Seconds")
                .font(.system(size: 11))
                .foregroundStyle(BBColor.subtitle)
                .opacity(state == .idle ? 0 : 1)
        }
        .accessibilityElement(children: .combine)
    }

    // Half-circle with the countdown inside
    private var timerArc: some View {
        Circle()
            .trim(from: 0.5, to: 1)               // top half only
            .stroke(BBColor.track, lineWidth: 5)
            .frame(width: 195, height: 195)
            .frame(width: 200, height: 100, alignment: .top)
            .overlay(alignment: .bottom) {
                Text(timeString)
                    .font(.system(size: 40, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.black)
            }
    }

    @ViewBuilder
    private var controls: some View {
        switch state {
        case .idle:
            BreathingPillButton(title: "Start", action: start)
                .padding(.horizontal, 36)

        case .running, .paused, .finishing:     // CHANGED: .finishing shows the same buttons, locked
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

    // MARK: Final "You did it!" screen

    private var completeContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                cyclesLabel
            }
            .padding(.trailing, 39)
            .padding(.top, 50)

            ZStack {
                Circle().fill(BBColor.button)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 128, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 190, height: 190)
            .padding(.top, 60)
            .accessibilityHidden(true)

            Text("You did it!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 70)

            Text("You took a moment to pause, breathe, and find your calm. Be proud of yourself for showing up!")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .padding(.horizontal, 34)
                .padding(.top, 12)

            Spacer(minLength: 16)

            HStack(spacing: 25) {
                BreathingPillButton(title: "Complete") {
                    onComplete()
                    dismiss()
                }
                .frame(width: 192)

                RoundIconButton(systemName: "clock.arrow.circlepath", label: "Reset", action: reset)
            }
            .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Clock + actions

    // CHANGED: handles two jobs now – ticking while running, and the short 0:00 moment at the end.
    private func runClock() async {
        switch state {
        case .running:
            // Checks the time about 30 times a second
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                tick()
            }

        case .finishing:
            // Show 0:00 for a moment, then move to the "You did it!" screen
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { state = .complete }

        default:
            break
        }
    }

    private func tick() {
        guard state == .running, let began = resumeDate else { return }
        let now = elapsedAtResume + Date().timeIntervalSince(began)
        if now >= totalLength {
            elapsed = totalLength
            state = .finishing              // CHANGED: was .complete straight away
        } else {
            elapsed = now
        }
    }

    private func start() {
        elapsed = 0
        elapsedAtResume = 0
        resumeDate = Date()
        state = .running
    }

    private func pause() {
        tick()                              // capture the latest time first
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

// MARK: - Buttons

/// Wide dark-green capsule ("Start", "Complete").
private struct BreathingPillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 63)
                .background(Capsule().fill(BBColor.button))
        }
        .buttonStyle(.plain)
    }
}

/// Round 63pt icon button (pause / play / reset).
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
