//
//  MirrorCameraFlow.swift
//  Moko
//
//  Camera version of Mirror Reflection: phone-themed illustration for the setup
//  checklist, then a 2:00 timer with your front camera live in the card and the
//  affirmations over it. Plugged into MirrorFlowView.
//

import SwiftUI
import Combine

// MARK: - Checklist illustration: an iPhone framing your face
struct CameraPhoneHero: View {
    /// 0...1: how bright the halo glows.
    var level: Double

    @State private var float = false

    private let green = MirrorPalette.green

    var body: some View {
        ZStack {
            // Halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [green.opacity(0.10 + 0.20 * level), green.opacity(0)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)

            // Phone
            ZStack {
                // Side buttons
                Capsule().fill(Color(red: 40/255, green: 50/255, blue: 45/255))
                    .frame(width: 4, height: 34).offset(x: -75, y: -62)
                Capsule().fill(Color(red: 40/255, green: 50/255, blue: 45/255))
                    .frame(width: 4, height: 54).offset(x: 75, y: -40)

                // Body
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 62/255, green: 74/255, blue: 68/255),
                                     Color(red: 28/255, green: 36/255, blue: 32/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 148, height: 278)
                    .shadow(color: green.opacity(0.28), radius: 20, x: 0, y: 12)

                // Screen
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 240/255, green: 248/255, blue: 243/255),
                                     MirrorPalette.mint],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 134, height: 264)

                // Glare
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 22, height: 250)
                    .rotationEffect(.degrees(20))
                    .offset(x: -34)
                    .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
                    .frame(width: 134, height: 264)
                    .clipped()

                // Dynamic island
                Capsule()
                    .fill(Color.black)
                    .frame(width: 46, height: 13)
                    .offset(y: -118)

                // Face inside the viewfinder
                ViewfinderCorners()
                    .stroke(green, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 92, height: 108)
                    .offset(y: -10)

                MirrorFaceIcon()
                    .frame(width: 72, height: 72)
                    .scaleEffect(1.2)
                    .offset(y: -10)

                // Shutter
                Circle()
                    .stroke(green, lineWidth: 3)
                    .frame(width: 38, height: 38)
                    .offset(y: 100)
                Circle()
                    .fill(green)
                    .frame(width: 28, height: 28)
                    .offset(y: 100)
            }
            .rotationEffect(.degrees(-5))
            .offset(y: float ? -5 : 5)

            // Twinkles
            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(green.opacity(0.55))
                .offset(x: 108, y: -108)
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(green.opacity(0.45))
                .offset(x: -112, y: 80)
        }
        .frame(height: 320)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                float = true
            }
        }
    }
}

/// Four rounded corner brackets, like a camera viewfinder.
struct ViewfinderCorners: Shape {
    var length: CGFloat = 18
    var radius: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var p = Path()

        // top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        p.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        // top-right
        p.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        // bottom-right
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        // bottom-left
        p.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return p
    }
}

// MARK: - Timer screen with live camera (fixed 2:00)
struct CameraTimerScreen: View {
    var onBack: () -> Void
    var onContinue: () -> Void

    private enum RunState {
        case idle, running, paused, completed
    }

    @StateObject private var camera = FrontCameraModel()
    @Environment(\.openURL) private var openURL

    @State private var runState: RunState = .idle
    @State private var elapsed: TimeInterval = 0
    @State private var lastTick: Date?

    private let total: TimeInterval = 120 // fixed, not customisable
    private let cardRadius: CGFloat = 32
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
    private var hasFeed: Bool { camera.status == .running }

    private var activeIndex: Int {
        min(affirmations.count - 1, Int(elapsed / (total / Double(affirmations.count))))
    }

    private var chipText: String {
        switch runState {
        case .idle:              return "Let’s Start"
        case .running, .paused:  return "Keep Going!"
        case .completed:         return "Well done"
        }
    }

    var body: some View {
        ZStack {
            MirrorPalette.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                MirrorHeader()
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                cameraCard
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                Text(timeText)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(MirrorPalette.green)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            controls
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
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

    // MARK: Camera card
    private var cameraCard: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MirrorPalette.mint.opacity(0.55), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if runState == .completed {
                MirrorCompletionBadge(size: 170, showRipples: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                cameraLayer
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if hasFeed {
                    // Darkens the lower part so the affirmations stay readable
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 250)
                    .allowsHitTesting(false)
                }

                affirmationsView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .overlay(alignment: .topLeading) {
            Text(chipText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(hasFeed && runState != .completed ? Color.white : MirrorPalette.green)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .overlay { progressOutline }
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .frame(maxHeight: .infinity)
    }

    /// Track + progress drawn around the card's edge
    private var progressOutline: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .stroke(MirrorPalette.mint, lineWidth: 6)

            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .trim(from: 0, to: runState == .completed ? 1 : CGFloat(progress))
                .stroke(MirrorPalette.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        switch camera.status {
        case .running:
            CameraPreviewView(session: camera.camera.session)

        case .checking:
            ProgressView()
                .tint(MirrorPalette.green)

        case .denied, .unavailable:
            VStack(spacing: 10) {
                Image(systemName: "video.slash")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(MirrorPalette.green)

                Text(camera.status == .denied ? "Camera access is off" : "Camera isn’t available here")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MirrorPalette.title)

                Text(camera.status == .denied
                     ? "Turn it on in Settings to see yourself during the practice. You can still continue without it."
                     : "Try this on an iPhone to see yourself here. You can still continue without it.")
                    .font(.system(size: 14))
                    .foregroundColor(MirrorPalette.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if camera.status == .denied {
                    Button {
                        if let url = mokoOpenAppSettingsURL() {
                            openURL(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 36)
                            .background(Capsule().fill(MirrorPalette.green))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 150) // keep clear of the affirmations
        }
    }

    private var affirmationsView: some View {
        VStack(spacing: 8) {
            ForEach(affirmations.indices, id: \.self) { index in
                let highlighted = isActive && index == activeIndex

                Text(affirmations[index])
                    .font(.system(size: 14, weight: highlighted ? .semibold : .regular))
                    .foregroundColor(
                        hasFeed
                            ? Color.white
                            : (highlighted ? MirrorPalette.title : MirrorPalette.subtext)
                    )
                    .shadow(color: hasFeed ? Color.black.opacity(0.5) : Color.clear, radius: 3, y: 1)
                    .multilineTextAlignment(.center)
                    .opacity(isActive ? (highlighted ? 1 : 0.55) : 0.95)
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
            camera.stop()
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
        camera.start() // bring the preview back after a completed run
    }
}

#Preview("Camera timer") {
    CameraTimerScreen(onBack: {}, onContinue: {})
}

#Preview("Phone hero") {
    CameraPhoneHero(level: 0.5)
        .padding()
        .background(MirrorPalette.screenBg)
}
