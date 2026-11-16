//
//  MirrorCameraFlow.swift
//  Moko
//
//  Camera version of Mirror Reflection:
//  - `CameraPhoneHero`: the iPhone picture on the prep checklist.
//  - `CameraTimerScreen`: the 2:00 timer with the front camera live in a card
//    and the affirmations on top of it.
//  The timer itself is `MirrorSessionClock` (in MirrorFlow.swift), shared with
//  the mirror version. The camera is `FrontCameraModel` (in Frontcamera.swift).
//

import SwiftUI
import SwiftData

// MARK: - Checklist illustration: an iPhone framing your face

/// A tilted phone showing a face in a viewfinder. It floats gently up and down.
struct CameraPhoneHero: View {
    /// 0...1: how bright the glow is. The prep screen raises it as points appear.
    var level: Double

    // The phone setting "Reduce Motion". If it is on, the phone stays still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Flipped once on appear. `repeatForever` then moves the phone up and down on its own.
    @State private var float = false

    private let green = MirrorPalette.accent
    private let phoneEdge = Color(red: 40/255, green: 50/255, blue: 45/255)

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
                Capsule().fill(phoneEdge)
                    .frame(width: 4, height: 34).offset(x: -75, y: -62)
                Capsule().fill(phoneEdge)
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
                                     MirrorPalette.track],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 134, height: 264)

                // Glare, cut to the screen shape.
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
                .foregroundStyle(green.opacity(0.55))
                .offset(x: 108, y: -108)
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(green.opacity(0.45))
                .offset(x: -112, y: 80)
        }
        .frame(height: 320)
        .accessibilityHidden(true)   // decoration only
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                float = true
            }
        }
    }
}

/// Four rounded corner brackets, like a camera viewfinder.
/// Each corner: a short line, a small curve round the corner, then another short line.
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
    var onContinue: () -> Void

    // Owns the camera and its permission state. @State keeps it alive while this screen is open.
    @State private var camera = FrontCameraModel()
    // The 2:00 clock. See `MirrorSessionClock` in MirrorFlow.swift.
    @State private var clock = MirrorSessionClock()
    // Opens the "edit affirmations" sheet.
    @State private var isEditingAffirmations = false
    // Opens links such as the Settings app.
    @Environment(\.openURL) private var openURL
    // The SwiftData database. Used to save the finished session.
    @Environment(\.modelContext) private var modelContext

    private let cardRadius = MokoScreenTheme.Radius.card

    // The shared affirmation lines. It is @Observable, so this screen redraws when they are edited.
    private let affirmationStore = MirrorAffirmationStore.shared

    /// Before Start: a preview of the lines. After Start: only the current line.
    private var showsCurrentLine: Bool { clock.runState != .idle }
    /// True when the live camera picture is showing. Text turns white to stay readable on it.
    private var hasFeed: Bool { camera.status == .running }

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

                cameraCard
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.top, 18)

                Text(clock.timeText)
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .monospacedDigit()   // digits all the same width, so the text does not jump
                    .foregroundStyle(MirrorPalette.accent)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            MirrorTimerControls(clock: clock, onContinue: onContinue, onReset: reset)
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
        }
        // Immersive session: keep the tab bar out of the way.
        .toolbar(.hidden, for: .tabBar)
        // Turn the camera on while this screen is visible, and off when it goes away.
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        // Restarts every time the run state changes. See `MirrorSessionClock.run()`.
        .task(id: clock.runState) {
            if await clock.run() {
                camera.stop()
                // Save the session so it shows up in Insights and achievements.
                modelContext.logCalmDown("Mirror Reflection", seconds: MirrorSessionClock.total)
            }
        }
        .sheet(isPresented: $isEditingAffirmations) {
            MirrorAffirmationsSheet(store: affirmationStore)
        }
    }

    // MARK: Camera card

    /// The big card: camera picture (or a message), affirmations at the bottom,
    /// a status chip top-left, and the progress drawn around the edge.
    private var cameraCard: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MirrorPalette.track.opacity(0.55), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if clock.runState == .completed {
                MokoCompletionAnimation(ringDiameter: 150)
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

                affirmationsArea
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .overlay(alignment: .topLeading) {
            Text(clock.statusText)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(MokoScreenTheme.Colors.surfaceLavender, in: Capsule())
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .overlay { progressOutline }
        .mokoCard()
        .frame(maxHeight: .infinity)
    }

    /// Track + progress drawn around the card's edge. `.trim` draws only part of the outline.
    private var progressOutline: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .stroke(MirrorPalette.track, lineWidth: 6)

            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .trim(from: 0, to: clock.runState == .completed ? 1 : CGFloat(clock.progress))
                .stroke(MirrorPalette.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
        }
    }

    /// What fills the card: the live camera, a loader, or a "camera is off" message.
    @ViewBuilder
    private var cameraLayer: some View {
        switch camera.status {
        case .running:
            CameraPreviewView(session: camera.camera.session)

        case .checking:
            MokoLoadingView()
                .frame(width: 84, height: 84)

        case .denied, .unavailable:
            VStack(spacing: 10) {
                Image(systemName: "video.slash")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(MirrorPalette.accent)

                Text(camera.status == .denied ? "Camera access is off" : "Camera isn’t available here")
                    .mokoText(MokoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(MirrorPalette.title)

                Text(camera.status == .denied
                     ? "Turn it on in Settings to see yourself during the practice. You can still continue without it."
                     : "Try this on an iPhone to see yourself here. You can still continue without it.")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MirrorPalette.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MokoScreenTheme.Space.page)

                if camera.status == .denied {
                    Button {
                        if let url = mokoOpenAppSettingsURL() {
                            openURL(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .mokoText(MokoScreenTheme.Typeface.slider)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 36)
                            .background(Capsule().fill(MirrorPalette.accent))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 150) // keep clear of the affirmations
        }
    }

    /// Same as the mirror version: a preview of the lines before Start, then only the current line.
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
        .frame(height: MirrorAffirmationsWindow.height)
        .animation(.easeInOut(duration: 0.35), value: showsCurrentLine)
    }

    /// The current line, big. It crossfades into the next one every 15 seconds.
    private var currentAffirmation: some View {
        let index = clock.lineIndex(count: affirmationStore.quotes.count)

        return ZStack {
            Text(affirmationStore.quotes[index])
                .mokoText(MokoScreenTheme.Typeface.title2)
                .foregroundStyle(hasFeed ? Color.white : MirrorPalette.title)
                .shadow(color: hasFeed ? Color.black.opacity(0.55) : Color.clear, radius: 4, y: 1)
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
            VStack(spacing: 8) {
                ForEach(affirmationStore.quotes.indices, id: \.self) { index in
                    Text(affirmationStore.quotes[index])
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(hasFeed ? Color.white : MirrorPalette.subtext)
                        .shadow(color: hasFeed ? Color.black.opacity(0.5) : Color.clear, radius: 3, y: 1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
        .defaultScrollAnchor(.top)
    }

    // MARK: Actions

    private func reset() {
        clock.reset()
        camera.start() // the camera was stopped when the session finished, so turn it back on
    }
}

#Preview("Camera timer") {
    CameraTimerScreen(onContinue: {})
}

#Preview("Phone hero") {
    CameraPhoneHero(level: 0.5)
        .padding()
        .background { MokoBackdrop() }
}
