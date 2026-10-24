//
//  MirrorFlow.swift
//  Moko
//
//  The full Mirror Reflection practice:
//  landing -> checklist (4 slide-to-confirm rows) -> 2:00 affirmation timer -> "You did it!"
//
//  Present MirrorFlowView full screen. onExit fires if the user backs out of the
//  landing screen; onFinish fires when they tap Done at the end.
//

import SwiftUI
import Combine

// MARK: - Shared palette
fileprivate enum MirrorPalette {
    static let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)  // #F2F2F7
    static let green = Color(red: 54/255, green: 89/255, blue: 72/255)        // #365948
    static let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    static let softGreen = Color(red: 120/255, green: 165/255, blue: 140/255)
    static let mint = Color(red: 203/255, green: 230/255, blue: 211/255)
    static let doneGreen = Color(red: 112/255, green: 142/255, blue: 125/255)
    static let title = Color(red: 47/255, green: 42/255, blue: 40/255)        // #2F2A28
    static let subtext = Color(red: 111/255, green: 103/255, blue: 98/255)    // #6F6762
    static let chip = Color(red: 237/255, green: 237/255, blue: 237/255)      // #EDEDED
    static let cream = Color(red: 252/255, green: 248/255, blue: 240/255)
}

// MARK: - Flow container
struct MirrorFlowView: View {
    var onExit: () -> Void = {}
    var onFinish: () -> Void = {}

    fileprivate enum Step {
        case landing, camera, checklist, timer, done
    }

    @State private var step: Step = .landing
    @State private var forward = true
    @State private var checked: [Bool] = Array(repeating: false, count: 4)

    private var slide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }

    var body: some View {
        ZStack {
            MirrorPalette.screenBg.ignoresSafeArea()

            switch step {
            case .landing:
                MirrorReflectionScreen(
                    onSelectOption: { option in
                        switch option {
                        case .mirror: go(.checklist, forward: true)
                        case .camera: go(.camera, forward: true)
                        }
                    },
                    onBack: { onExit() }
                )
                .transition(slide)

            case .camera:
                MirrorCameraSoonScreen(onBack: { go(.landing, forward: false) })
                    .transition(slide)

            case .checklist:
                MirrorChecklistScreen(
                    checked: $checked,
                    onBack: { go(.landing, forward: false) },
                    onContinue: { go(.timer, forward: true) }
                )
                .transition(slide)

            case .timer:
                MirrorTimerScreen(
                    onBack: { go(.checklist, forward: false) },
                    onContinue: { go(.done, forward: true) }
                )
                .transition(slide)

            case .done:
                MirrorCompletionScreen(onDone: { onFinish() })
                    .transition(slide)
            }
        }
    }

    private func go(_ next: Step, forward isForward: Bool) {
        // Set the direction first so the outgoing screen uses the right transition
        forward = isForward
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                step = next
            }
        }
    }
}

// MARK: - Shared bits
fileprivate struct MirrorBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 38, height: 38)
                .background(Circle().fill(MirrorPalette.chip))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct MirrorHeader: View {
    var centered = false

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 4) {
            Text("Mirror Reflection")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(MirrorPalette.title)

            Text("A self-reflective confidence practice")
                .font(.system(size: 15))
                .foregroundColor(MirrorPalette.subtext)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

fileprivate struct MirrorPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(MirrorPalette.green))
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct MirrorCircleButton: View {
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(MirrorPalette.green))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: checklist
fileprivate struct MirrorChecklistScreen: View {
    @Binding var checked: [Bool]
    var onBack: () -> Void
    var onContinue: () -> Void

    private let items = [
        "Find a comfortable spot",
        "Take a gentle breath",
        "Look at yourself kindly",
        "Let go of judgement"
    ]

    private var doneCount: Int { checked.filter { $0 }.count }
    private var allDone: Bool { doneCount == items.count }

    var body: some View {
        ZStack {
            MirrorPalette.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        MirrorBackButton(action: onBack)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    MirrorHeader()
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    // The mirror glows brighter as each step is confirmed
                    MirrorHero(showCaption: false, level: Double(doneCount) / Double(items.count))
                        .scaleEffect(0.72)
                        .frame(height: 220)
                        .padding(.top, 8)

                    Text("Arrive in Front of Your Mirror")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(MirrorPalette.title)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)

                    HStack {
                        Text("Your Checklist")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(MirrorPalette.subtext)

                        Spacer()

                        Text("\(doneCount)/\(items.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(MirrorPalette.green)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 26)

                    VStack(spacing: 12) {
                        ForEach(items.indices, id: \.self) { index in
                            SlideChecklistRow(title: items[index], isDone: $checked[index])
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if allDone {
                MirrorPrimaryButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: allDone)
    }
}

/// One checklist row: slide the knob to the right to confirm. Tap a finished row to undo it.
fileprivate struct SlideChecklistRow: View {
    let title: String
    @Binding var isDone: Bool

    @State private var drag: CGFloat = 0

    private let rowHeight: CGFloat = 54
    private let knobSize: CGFloat = 42
    private let inset: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let maxDrag = max(1, geo.size.width - knobSize - inset * 2)
            let fraction = min(1, max(0, drag / maxDrag))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(isDone ? MirrorPalette.doneGreen : Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                // Fill that trails the knob
                if !isDone {
                    Capsule()
                        .fill(MirrorPalette.green.opacity(0.14))
                        .frame(width: inset + knobSize + drag + inset)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isDone ? Color.white : MirrorPalette.title)
                    .opacity(isDone ? 1 : 1 - 0.6 * fraction)
                    .frame(maxWidth: .infinity)

                ZStack {
                    Circle()
                        .fill(isDone ? Color.white : MirrorPalette.green)

                    Image(systemName: isDone ? "checkmark" : "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isDone ? MirrorPalette.doneGreen : Color.white)
                }
                .frame(width: knobSize, height: knobSize)
                // Finished rows park the check at the right end
                .offset(x: isDone ? inset + maxDrag : inset + drag)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !isDone else { return }
                            drag = min(max(0, value.translation.width), maxDrag)
                        }
                        .onEnded { _ in
                            guard !isDone else { return }
                            if drag > maxDrag * 0.7 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isDone = true
                                    drag = 0
                                }
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    drag = 0
                                }
                            }
                        }
                )
            }
            .contentShape(Capsule())
            .onTapGesture {
                if isDone {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isDone = false
                    }
                }
            }
        }
        .frame(height: rowHeight)
        .sensoryFeedback(.impact(weight: .medium), trigger: isDone)
    }
}

// MARK: - Step 3: affirmation timer (fixed 2:00)
fileprivate struct MirrorTimerScreen: View {
    var onBack: () -> Void
    var onContinue: () -> Void

    private enum RunState {
        case idle, running, paused, completed
    }

    @State private var runState: RunState = .idle
    @State private var elapsed: TimeInterval = 0
    @State private var lastTick: Date?

    private let total: TimeInterval = 120 // fixed, not customisable
    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private let affirmations = [
        "I am good and getting better.",
        "I am growing and I am going at my own pace.",
        "I am held and supported by those who love me.",
        "I am in charge of how I feel and I choose to feel happy."
    ]

    private var progress: Double { min(1, elapsed / total) }
    private var remainingSeconds: Int { max(0, Int(ceil(total - elapsed))) }
    private var timeText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private var isActive: Bool { runState == .running || runState == .paused }

    /// Which affirmation is highlighted (each gets an equal share of the 2 minutes)
    private var activeIndex: Int {
        min(affirmations.count - 1, Int(elapsed / (total / Double(affirmations.count))))
    }

    private var titleText: String {
        switch runState {
        case .idle:               return "Let’s Start"
        case .running, .paused:   return "Keep Going!"
        case .completed:          return "Well done"
        }
    }

    var body: some View {
        ZStack {
            MirrorPalette.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        MirrorBackButton(action: onBack)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    MirrorHeader()
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    affirmationsView
                        .padding(.top, 26)
                        .padding(.horizontal, 28)

                    Text(titleText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(MirrorPalette.title)
                        .padding(.top, 28)

                    MirrorTimerRing(
                        progress: progress,
                        isRunning: runState == .running,
                        isCompleted: runState == .completed
                    )
                    .frame(width: 250, height: 250)
                    .padding(.top, 14)

                    Text(timeText)
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(MirrorPalette.green)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            controls
        }
        .onReceive(ticker) { now in
            tick(now)
        }
        .sensoryFeedback(trigger: runState) { oldState, newState in
            switch (oldState, newState) {
            case (_, .completed):    return .success
            case (.idle, .running):  return .impact(weight: .medium)
            default:                 return .impact(weight: .light)
            }
        }
    }

    // MARK: Affirmations
    private var affirmationsView: some View {
        VStack(spacing: 10) {
            ForEach(affirmations.indices, id: \.self) { index in
                let highlighted = isActive && index == activeIndex

                Text(affirmations[index])
                    .font(.system(size: 15, weight: highlighted ? .semibold : .regular))
                    .foregroundColor(highlighted ? MirrorPalette.title : MirrorPalette.subtext)
                    .multilineTextAlignment(.center)
                    .opacity(isActive ? (highlighted ? 1 : 0.35) : 0.9)
                    .scaleEffect(highlighted ? 1.04 : 1)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.4), value: activeIndex)
        .animation(.easeInOut(duration: 0.4), value: runState)
    }

    // MARK: Controls
    @ViewBuilder
    private var controls: some View {
        Group {
            switch runState {
            case .idle:
                MirrorPrimaryButton(title: "Start") { start() }

            case .running, .paused:
                HStack {
                    MirrorCircleButton(systemName: runState == .running ? "pause.fill" : "play.fill") {
                        togglePause()
                    }
                    Spacer()
                    MirrorCircleButton(systemName: "arrow.counterclockwise") { reset() }
                }
                .padding(.horizontal, 8)

            case .completed:
                HStack(spacing: 16) {
                    MirrorPrimaryButton(title: "Continue", action: onContinue)
                    MirrorCircleButton(systemName: "arrow.counterclockwise") { reset() }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.2), value: runState)
    }

    // MARK: Timer logic
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

/// Progress ring: gradient stroke with a glowing end cap, a breathing face in the middle,
/// and the completion badge once the time is up.
fileprivate struct MirrorTimerRing: View {
    var progress: Double
    var isRunning: Bool
    var isCompleted: Bool

    @State private var pulse = false

    private let diameter: CGFloat = 206
    private let lineWidth: CGFloat = 16

    private var endAngle: Double {
        -Double.pi / 2 + 2 * Double.pi * progress
    }

    var body: some View {
        ZStack {
            // Soft halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MirrorPalette.green.opacity(isRunning ? 0.22 : 0.10),
                                 MirrorPalette.green.opacity(0)],
                        center: .center,
                        startRadius: 40,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .scaleEffect(isRunning ? (pulse ? 1.06 : 0.94) : 1)

            // Track
            Circle()
                .stroke(MirrorPalette.mint, lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Progress
            Circle()
                .trim(from: 0, to: isCompleted ? 1 : CGFloat(progress))
                .stroke(
                    AngularGradient(
                        colors: [MirrorPalette.softGreen, MirrorPalette.deepGreen],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(isCompleted ? 360 : max(1, 360 * progress))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)

            // Glowing end cap
            if !isCompleted && progress > 0.005 {
                Circle()
                    .fill(Color.white)
                    .frame(width: lineWidth * 0.95, height: lineWidth * 0.95)
                    .overlay(Circle().stroke(MirrorPalette.deepGreen, lineWidth: 3))
                    .shadow(color: MirrorPalette.green.opacity(0.4), radius: 6)
                    .offset(
                        x: CGFloat(cos(endAngle)) * diameter / 2,
                        y: CGFloat(sin(endAngle)) * diameter / 2
                    )
            }

            // Center
            if isCompleted {
                MirrorCompletionBadge(size: 156, showRipples: false)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else {
                MirrorFaceIcon()
                    .frame(width: 72, height: 72)
                    .scaleEffect(1.5)
                    .scaleEffect(isRunning ? (pulse ? 1.05 : 0.95) : 1)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isCompleted)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Step 4: "You did it!"
fileprivate struct MirrorCompletionScreen: View {
    var onDone: () -> Void

    var body: some View {
        ZStack {
            MirrorPalette.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                MirrorHeader(centered: true)
                    .padding(.horizontal, 24)
                    .padding(.top, 26)

                Spacer(minLength: 12)

                ZStack {
                    MirrorConfettiBurst(radius: 150)
                    MirrorCompletionBadge(size: 190, showRipples: true)
                }
                .frame(height: 340)

                Text("You did it!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(MirrorPalette.title)
                    .padding(.top, 8)

                Text("You took a moment to look at yourself with kindness and appreciate the person you are.")
                    .font(.system(size: 16))
                    .foregroundColor(MirrorPalette.subtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .padding(.horizontal, 36)

                Spacer(minLength: 12)

                MirrorPrimaryButton(title: "Done", action: onDone)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Completion illustration
fileprivate struct MirrorCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.27, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.69))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.33))
        return path
    }
}

/// Badge that pops in, with rippling rings and a check that draws itself.
fileprivate struct MirrorCompletionBadge: View {
    var size: CGFloat
    var showRipples: Bool

    @State private var popped = false
    @State private var drawn: CGFloat = 0
    @State private var ripple = false

    var body: some View {
        ZStack {
            if showRipples {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(MirrorPalette.mint, lineWidth: 3)
                        .frame(width: size, height: size)
                        .scaleEffect(ripple ? 1.6 : 1)
                        .opacity(ripple ? 0 : 0.9)
                        .animation(
                            .easeOut(duration: 2.2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 1.1),
                            value: ripple
                        )
                }
            }

            Circle()
                .fill(MirrorPalette.mint.opacity(0.7))
                .frame(width: size, height: size)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [MirrorPalette.softGreen, MirrorPalette.green, MirrorPalette.deepGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.78, height: size * 0.78)
                .shadow(color: MirrorPalette.deepGreen.opacity(0.35), radius: size * 0.08, x: 0, y: size * 0.04)

            Circle()
                .stroke(MirrorPalette.cream.opacity(0.35), lineWidth: 2)
                .frame(width: size * 0.66, height: size * 0.66)

            MirrorCheckShape()
                .trim(from: 0, to: drawn)
                .stroke(
                    MirrorPalette.cream,
                    style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round, lineJoin: .round)
                )
                .frame(width: size * 0.78, height: size * 0.78)
        }
        .scaleEffect(popped ? 1 : 0.6)
        .opacity(popped ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                popped = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                drawn = 1
            }
            ripple = true
        }
    }
}

fileprivate let mirrorConfettiColors: [Color] = [
    MirrorPalette.green,
    MirrorPalette.softGreen,
    Color(red: 244/255, green: 190/255, blue: 70/255),   // yellow
    Color(red: 230/255, green: 110/255, blue: 90/255),   // coral
    Color(red: 130/255, green: 185/255, blue: 175/255),  // teal
    Color(red: 140/255, green: 175/255, blue: 200/255)   // blue
]

/// Leaves and petals that burst outward once, in the same palette as the other illustrations.
fileprivate struct MirrorConfettiBurst: View {
    var radius: CGFloat

    @State private var burst: CGFloat = 0

    private struct Piece {
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
        let isLeaf: Bool
    }

    private let pieces: [Piece] = (0..<16).map { index in
        let jitter: Double = index % 2 == 0 ? 0.1 : -0.1
        let angle = Double(index) / 16 * 2 * Double.pi + jitter
        let distances: [CGFloat] = [1.0, 0.8, 0.92]
        let sizes: [CGFloat] = [20, 13, 16]
        return Piece(
            angle: angle,
            distance: distances[index % 3],
            size: sizes[(index + 1) % 3],
            color: mirrorConfettiColors[index % mirrorConfettiColors.count],
            isLeaf: index % 2 == 0
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
                            .frame(width: piece.size * 0.5, height: piece.size)
                            .rotationEffect(.radians(piece.angle + Double.pi / 2))
                    } else {
                        Circle()
                            .fill(piece.color)
                            .frame(width: piece.size * 0.7, height: piece.size * 0.7)
                    }
                }
                .offset(
                    x: CGFloat(cos(piece.angle)) * radius * piece.distance * burst,
                    y: CGFloat(sin(piece.angle)) * radius * piece.distance * burst
                )
                .scaleEffect(0.3 + 0.7 * burst)
                .opacity(Double(min(1, burst * 2)))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.65).delay(0.25)) {
                burst = 1
            }
        }
    }
}

// MARK: - Camera option (not built yet)
fileprivate struct MirrorCameraSoonScreen: View {
    var onBack: () -> Void

    var body: some View {
        ZStack {
            MirrorPalette.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    MirrorBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                ZStack {
                    Circle()
                        .fill(MirrorPalette.mint.opacity(0.7))
                        .frame(width: 140, height: 140)
                    Image(systemName: "camera")
                        .font(.system(size: 52, weight: .regular))
                        .foregroundColor(MirrorPalette.green)
                }

                Text("Practice with your camera")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MirrorPalette.title)
                    .padding(.top, 28)

                Text("This option is coming soon.")
                    .font(.system(size: 16))
                    .foregroundColor(MirrorPalette.subtext)
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview("Full flow") {
    MirrorFlowView()
}
