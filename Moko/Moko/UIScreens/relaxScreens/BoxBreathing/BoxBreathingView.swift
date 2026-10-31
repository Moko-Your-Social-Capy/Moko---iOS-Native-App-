import SwiftUI
import SwiftData

enum BBColor {
    static let background = Color(red: 246/255, green: 250/255, blue: 232/255)   // pale lime
    static let button     = Color(red: 54/255, green: 89/255, blue: 72/255)   // buttons, check circle, "Not now"
    static let dark       = Color(red: 27/255, green: 66/255, blue: 47/255)    // corner dots + filled box edges
    static let track      = Color(red: 226/255, green: 245/255, blue: 177/255)   // lime track
    static let title      = Color(red: 92/255, green: 67/255, blue: 48/255)
    static let subtitle   = Color(red: 138/255, green: 123/255, blue: 104/255)
    static let muted      = Color(red: 111/255, green: 103/255, blue: 98/255)
    static let card       = Color(red: 252/255, green: 248/255, blue: 240/255)   // cream icon circle
    static let lime       = Color(red: 226/255, green: 245/255, blue: 177/255)
    static let titleBrown = Color(red: 92/255, green: 67/255, blue: 48/255)
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
    let initialCycles: Int
    var onComplete: () -> Void = {}

    init(initialCycles: Int = 2, onComplete: @escaping () -> Void = {}) {
        self.initialCycles = initialCycles
        self.onComplete = onComplete
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var state: SessionState = .idle
    @State private var elapsed: TimeInterval = 0          // seconds since the session began
    @State private var elapsedAtResume: TimeInterval = 0  // elapsed when the current run started
    @State private var resumeDate: Date?                  // when the current run started

    private let phaseLength: TimeInterval = 4
    private var cycleLength: TimeInterval { phaseLength * 4 }
    private var totalLength: TimeInterval { cycleLength * Double(initialCycles) }

    // MARK: Values worked out from `elapsed`

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
        initialCycles == 1 ? "1 CYCLE" : "\(initialCycles) CYCLES"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BBColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if state == .complete {
                    completeContent.transition(.opacity)
                } else {
                    breathingContent.transition(.opacity)
                }
            }
        }
        .navigationTitle("Box Breathing")
        .navigationBarTitleDisplayMode(.inline)
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

                // Cycle counter — only visible once the session has started
                if state == .running || state == .paused || state == .finishing {
                    Text("Cycle \(currentCycle) of \(initialCycles)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BBColor.muted)
                        .monospacedDigit()
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.25), value: state)
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
                .foregroundStyle(BBColor.titleBrown)

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

            // Use the same completion animation as the guided breathing timer.
            ZStack {
                Circle()
                    .stroke(BBColor.lime, lineWidth: 14)
                    .frame(width: 270, height: 270)
                Circle()
                    .fill(BBColor.lime.opacity(0.58))
                    .frame(width: 230, height: 230)
                MokoLottieView(animationType: .complete, size: 210)
            }
            .frame(width: 270, height: 270)
            .accessibilityHidden(true)

            Text("You did it!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(BBColor.titleBrown)
                .padding(.top, 8)

            Text("You took a moment to pause, breathe, and find your calm. Be proud of yourself for showing up!")
                .font(.system(size: 16))
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

// MARK: - Completion animation components

/// Custom check shape that can be drawn progressively with .trim
private struct BBCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.70))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.32))
        return path
    }
}

/// Animated badge: pops in with spring, check draws itself, ripple rings pulse outward
private struct BBCompletionBadge: View {
    var size: CGFloat

    @State private var popped = false
    @State private var drawn: CGFloat = 0
    @State private var ripple = false

    private let softGreen  = Color(red: 120/255, green: 165/255, blue: 140/255)
    private let mint       = Color(red: 226/255, green: 245/255, blue: 177/255)
    private let cream      = Color(red: 252/255, green: 248/255, blue: 240/255)

    var body: some View {
        ZStack {
            // Expanding ripple rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(mint, lineWidth: 2.5)
                    .frame(width: size, height: size)
                    .scaleEffect(ripple ? 1.7 : 1)
                    .opacity(ripple ? 0 : 0.85)
                    .animation(
                        .easeOut(duration: 2.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.8),
                        value: ripple
                    )
            }

            // Outer mint halo
            Circle()
                .fill(mint.opacity(0.65))
                .frame(width: size, height: size)

            // Main filled circle — same green as BBColor.button
            Circle()
                .fill(
                    LinearGradient(
                        colors: [softGreen, BBColor.button, BBColor.dark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.78, height: size * 0.78)
                .shadow(color: BBColor.dark.opacity(0.35), radius: size * 0.08, x: 0, y: size * 0.04)

            // Inner cream ring
            Circle()
                .stroke(cream.opacity(0.3), lineWidth: 2)
                .frame(width: size * 0.66, height: size * 0.66)

            // Animated check
            BBCheckShape()
                .trim(from: 0, to: drawn)
                .stroke(
                    cream,
                    style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round, lineJoin: .round)
                )
                .frame(width: size * 0.78, height: size * 0.78)
        }
        .scaleEffect(popped ? 1 : 0.55)
        .opacity(popped ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.58)) {
                popped = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.28)) {
                drawn = 1
            }
            ripple = true
        }
    }
}

private let bbConfettiColors: [Color] = [
    BBColor.button,
    Color(red: 120/255, green: 165/255, blue: 140/255),   // soft green
    Color(red: 244/255, green: 190/255, blue: 70/255),     // yellow
    Color(red: 230/255, green: 130/255, blue: 100/255),    // coral
    Color(red: 130/255, green: 185/255, blue: 175/255),    // teal
    Color(red: 160/255, green: 195/255, blue: 215/255),    // sky blue
    Color(red: 203/255, green: 230/255, blue: 211/255),    // mint
]

/// Confetti pieces that burst outward once on appear — same mechanic as MirrorConfettiBurst
private struct BBConfettiBurst: View {
    var radius: CGFloat

    @State private var burst: CGFloat = 0

    private struct Piece {
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
        let isLeaf: Bool
        let rotation: Double
    }

    private let pieces: [Piece] = (0..<20).map { index in
        let jitter: Double = (index % 3 == 0) ? 0.12 : (index % 3 == 1 ? -0.08 : 0.04)
        let angle = Double(index) / 20.0 * 2 * Double.pi + jitter
        let distances: [CGFloat] = [1.0, 0.82, 0.94, 0.76]
        let sizes: [CGFloat] = [18, 12, 15, 10]
        return Piece(
            angle: angle,
            distance: distances[index % 4],
            size: sizes[index % 4],
            color: bbConfettiColors[index % bbConfettiColors.count],
            isLeaf: index % 2 == 0,
            rotation: Double(index) * 37.0
        )
    }

    var body: some View {
        ZStack {
            ForEach(pieces.indices, id: \.self) { index in
                let piece = pieces[index]

                Group {
                    if piece.isLeaf {
                        Capsule()
                            .fill(piece.color)
                            .frame(width: piece.size * 0.45, height: piece.size)
                            .rotationEffect(.radians(piece.angle + .pi / 2))
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(piece.color)
                            .frame(width: piece.size * 0.6, height: piece.size * 0.6)
                            .rotationEffect(.degrees(piece.rotation))
                    }
                }
                .offset(
                    x: CGFloat(cos(piece.angle)) * radius * piece.distance * burst,
                    y: CGFloat(sin(piece.angle)) * radius * piece.distance * burst
                )
                .scaleEffect(0.25 + 0.75 * burst)
                .opacity(Double(min(1, burst * 1.8)))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.62).delay(0.15)) {
                burst = 1
            }
        }
    }
}

#Preview {
    NavigationStack { BoxBreathingView() }
}
