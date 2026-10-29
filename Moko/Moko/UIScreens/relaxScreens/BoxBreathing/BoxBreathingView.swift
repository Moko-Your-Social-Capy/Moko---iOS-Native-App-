import SwiftUI
import SwiftData

enum BBColor {
    static let background = Color(red: 242/255, green: 242/255, blue: 247/255)   // screen background
    static let button     = Color(red: 54/255, green: 89/255, blue: 72/255)   // buttons, check circle, "Not now"
    static let dark       = Color(red: 27/255, green: 66/255, blue: 47/255)    // corner dots + filled box edges
    static let track      = Color(red: 217/255, green: 217/255, blue: 217/255)   // empty box edges + timer arc
    static let title      = Color(red: 41/255, green: 43/255, blue: 38/255)
    static let subtitle   = Color(red: 138/255, green: 123/255, blue: 104/255)
    static let muted      = Color(red: 111/255, green: 103/255, blue: 98/255)
    static let card       = Color(red: 252/255, green: 248/255, blue: 240/255)   // cream icon circle
}

private enum SessionState: Equatable {
    case idle        // Start screen
    case running
    case paused
    case finishing   // the short moment after the last phase, timer shows 0:00
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
    @State private var cycles: Int
    var initialCycles: Int = 2
    var onComplete: () -> Void = {}

    init(initialCycles: Int = 2, onComplete: @escaping () -> Void = {}) {
        self.initialCycles = initialCycles
        _cycles = State(initialValue: initialCycles)
        self.onComplete = onComplete
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext  

    @State private var state: SessionState = .idle
    @State private var elapsed: TimeInterval = 0          // seconds since the session began
    @State private var elapsedAtResume: TimeInterval = 0  // elapsed when the current run started
    @State private var resumeDate: Date?                  // when the current run started

    private let phaseLength: TimeInterval = 4
    private var cycleLength: TimeInterval { phaseLength * 4 }
    private var totalLength: TimeInterval { cycleLength * Double(cycles) }

    // MARK: Values worked out from `elapsed`

    private var stepIndex: Int {
        min(Int(elapsed / phaseLength), cycles * 4 - 1)
    }

    private var phase: BreathPhase {
        BreathPhase(rawValue: stepIndex % 4) ?? .inhale
    }

    private func sideProgress(_ side: Int) -> CGFloat {
        if state == .finishing { return 1 }
        let inCycle = elapsed.truncatingRemainder(dividingBy: cycleLength) / phaseLength
        return CGFloat(min(max(inCycle - Double(side), 0), 1))
    }

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

            VStack(spacing: 0) {
                topBar

                if state == .complete {
                    completeContent.transition(.opacity)
                } else {
                    breathingContent.transition(.opacity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: state) { await runClock() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active && state == .running { pause() }
        }
        .sensoryFeedback(trigger: stepIndex) { old, new in
            (state == .running && new > old) ? .impact(weight: .light) : nil
        }
        .sensoryFeedback(trigger: state) { _, new in
            new == .complete ? .success : nil
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color(red: 237/255, green: 237/255, blue: 237/255)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(BBColor.title)
                .padding(.horizontal, 16)

            HStack {
                Text(cyclesText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBColor.muted)
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

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

            Text("For \(Int(phaseLength)) Seconds")
                .font(.system(size: 11))
                .foregroundStyle(BBColor.subtitle)
                .opacity(state == .idle ? 0 : 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var timerArc: some View {
        Circle()
            .trim(from: 0.5, to: 1)
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBColor.muted)
            }
            .padding(.trailing, 39)
            .padding(.top, 40)

            ZStack {
                Circle().fill(BBColor.button)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 128, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 190, height: 190)
            .padding(.top, 40)
            .accessibilityHidden(true)

            Text("You did it!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 40)

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

    private func runClock() async {
        switch state {
        case .running:
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                tick()
            }
        case .finishing:
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { state = .complete }
            modelContext.logCalmDown("Box Breathing", seconds: totalLength)
        default:
            break
        }
    }

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

    private func start() {
        elapsed = 0
        elapsedAtResume = 0
        resumeDate = Date()
        state = .running
    }

    private func pause() {
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
