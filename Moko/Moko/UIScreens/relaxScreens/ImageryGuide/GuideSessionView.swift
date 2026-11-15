//
//  GuideSessionView.swift
//  Moko
//
//  The guided imagery session: a full-screen photo, a card with the current
//  step, a progress bar and soft looping background music.
//  When the timer ends it saves a calm-down entry and shows "Continue".
//
//  How the timer works: `.task(id: isRunning)` runs `runClock()`, which adds the
//  real time that passed 10 times a second. Pausing flips `isRunning`, which
//  cancels the loop.
//

import SwiftUI
import SwiftData
import Combine        // only for the "is the song ready?" listener below
import AVFoundation
import OSLog

struct GuideSessionView: View {
    let guide: ImageryGuide
    var onContinue: () -> Void = {}

    // Shared text and settings loaded from Supabase (titles, button labels, …).
    @Environment(ImageryGuideStore.self) private var store
    // SwiftData's "save box". We use it to record the finished session.
    @Environment(\.modelContext) private var modelContext

    // Seconds played so far.
    @State private var elapsed: TimeInterval = 0
    // True while the timer is counting. Starts as soon as the screen opens.
    @State private var isRunning = true
    // The music player. `nil` until the music is set up.
    @State private var audioPlayer: AVPlayer?
    // Listens for "song finished" so we can loop it.
    @State private var loopObserver: NSObjectProtocol?
    // Keeps the "is the song ready?" listener alive.
    @State private var audioCancellables = Set<AnyCancellable>()

    private let accent   = MokoScreenTheme.Colors.dataVioletDeep
    private let tileFill = MokoScreenTheme.Colors.surfaceLavender
    private let ink      = MokoScreenTheme.Colors.textTitle
    private let caption  = MokoScreenTheme.Colors.textBody
    private let track    = MokoScreenTheme.Colors.surfaceLavender

    // MARK: Derived state

    private var screen: ImageryGuideScreenContent? { store.screen }
    private var totalSeconds: TimeInterval { TimeInterval(guide.durationSeconds) }
    private var steps: [String] { guide.sessionSteps.isEmpty ? [""] : guide.sessionSteps }
    private var isComplete: Bool { elapsed >= totalSeconds }

    /// Which step to show. The session is split into equal time slices, one per step.
    private var stepIndex: Int {
        let perStep = totalSeconds / Double(steps.count)
        return min(Int(elapsed / perStep), steps.count - 1)
    }

    private var headerText: String {
        guard let screen else { return "" }
        if isComplete { return screen.sessionCompleteHeader }

        let step = screen.format(screen.sessionStepFormat, [
            "current": "\(stepIndex + 1)",
            "total": "\(steps.count)"
        ])
        return isRunning ? step : step + screen.sessionPausedSuffix
    }

    private var instruction: String {
        if isComplete {
            guard let screen else { return "" }
            return screen.format(screen.sessionCompleteInstructionFormat, [
                "duration": format(Int(totalSeconds))
            ])
        }
        return steps[stepIndex]
    }

    /// Turns seconds into "m:ss", for example 75 → "1:15".
    private func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            panel
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 22)
        }
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
        // Immersive session: give the guidance panel the full screen.
        .toolbar(.hidden, for: .tabBar)
        // `.task` runs when the screen appears and is cancelled when it goes away.
        .task { await store.loadIfNeeded() }
        .onAppear { setupAmbientAudio() }
        // Restarts every time the timer is played or paused. See `runClock()`.
        .task(id: isRunning) { await runClock() }
        // Play or pause the music whenever the timer is played or paused.
        .onChange(of: isRunning, initial: false) { _, newValue in
            if newValue { playAmbientAudio() } else { pauseAmbientAudio() }
        }
        // Stop the timer and music when the user leaves the screen.
        .onDisappear {
            isRunning = false
            stopAmbientAudio()
        }
        // A light buzz on every new step, and a success buzz at the end.
        .sensoryFeedback(.impact(weight: .light), trigger: stepIndex)
        .sensoryFeedback(.success, trigger: isComplete)
    }

    // MARK: Background photo

    private var background: some View {
        // Keep the photo in an overlay so its intrinsic size can never stretch
        // the session's layout beyond the screen edges.
        Color.clear
            .overlay {
                ZStack {
                    tileFill

                    if let url = guide.artworkURL {
                        // AsyncImage downloads the photo. `phase` tells us loading / done / failed.
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(guide.sessionImageScale, anchor: .top)
                                    .offset(x: guide.sessionImageShift)   // framing comes from Supabase
                            case .empty:
                                ProgressView()
                                    .tint(accent)
                            case .failure:
                                iconArtwork
                            @unknown default:
                                iconArtwork
                            }
                        }
                    } else {
                        iconArtwork
                    }
                }
            }
            .clipped()
            .ignoresSafeArea()
    }

    private var iconArtwork: some View {
        Image(systemName: guide.icon)
            .font(.system(size: 140, weight: .semibold))
            .foregroundStyle(accent.opacity(0.35))
    }

    // MARK: Guidance panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step label + subtle controls
            HStack {
                Text(headerText)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .tracking(0.3)
                    .foregroundStyle(caption)
                Spacer()
                if !isComplete { controls }
            }
            .frame(minHeight: 44)

            // Instruction (cross-fades when it changes)
            ZStack(alignment: .topLeading) {
                Text(instruction)
                    .mokoText(MokoScreenTheme.Typeface.section)
                    .lineSpacing(3)
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(instruction)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            .padding(.top, 4)
            .animation(.easeInOut(duration: 0.4), value: instruction)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(track)
                    Capsule().fill(accent)
                        .frame(width: geo.size.width * CGFloat(elapsed / totalSeconds))
                }
            }
            .frame(height: 6)
            .padding(.top, 14)

            // Elapsed / remaining
            HStack {
                Text(elapsedLabel)
                Spacer()
                Text(remainingLabel)
            }
            .mokoText(MokoScreenTheme.Typeface.body)
            .monospacedDigit()
            .foregroundStyle(caption)
            .padding(.top, 10)

            // Appears once the timer is over
            if isComplete {
                Button(action: onContinue) {
                    Text(screen?.sessionContinueButton ?? "")
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accent, in: Capsule())
                }
                .padding(.top, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .mokoCard()
        .animation(.spring(duration: 0.4), value: isComplete)
    }

    private var elapsedLabel: String {
        guard let screen else { return "" }
        return screen.format(screen.sessionElapsedFormat, [
            "duration": format(Int(elapsed))
        ])
    }

    private var remainingLabel: String {
        guard let screen else { return "" }
        return screen.format(screen.sessionRemainingFormat, [
            "duration": format(Int(totalSeconds) - Int(elapsed))
        ])
    }

    // MARK: Subtle reset + play/pause

    private var controls: some View {
        HStack(spacing: 8) {
            controlButton(icon: screen?.sessionRestartIcon ?? "",
                          label: screen?.sessionRestartLabel ?? "") {
                elapsed = 0
                // Restart the ambient music from the beginning too.
                audioPlayer?.seek(to: .zero)
                isRunning = true
                playAmbientAudio()
            }
            controlButton(icon: isRunning ? (screen?.sessionPauseIcon ?? "") : (screen?.sessionPlayIcon ?? ""),
                          label: isRunning ? (screen?.sessionPauseLabel ?? "") : (screen?.sessionPlayLabel ?? "")) {
                isRunning.toggle()
            }
        }
    }

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(caption)
                .frame(width: 44, height: 44)
                .background(Circle().fill(track))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Clock

    /// Runs inside `.task(id: isRunning)`. SwiftUI cancels it when `isRunning` changes.
    private func runClock() async {
        guard isRunning else { return }
        var lastTick = Date()
        while !Task.isCancelled && !isComplete {
            try? await Task.sleep(for: .milliseconds(100))
            // Paused while we slept: do not add that time.
            guard !Task.isCancelled else { return }
            let now = Date()
            // Capped at 0.5 s, so a frozen app cannot jump ahead.
            elapsed = min(totalSeconds, elapsed + min(now.timeIntervalSince(lastTick), 0.5))
            lastTick = now
            if isComplete {
                isRunning = false
                // Save the session so it shows up in Insights and achievements.
                modelContext.logCalmDown("Imagery Guide", seconds: totalSeconds)
            }
        }
    }

    // MARK: Ambient background music

    /// Creates the AVPlayer for the guide's ambient track and starts it if the
    /// session is already running. The track loops softly for the whole session.
    private func setupAmbientAudio() {
        guard audioPlayer == nil else { return }
        guard let audioURL = guide.sessionAudioURL else {
            Logger.audio.info("No audio URL for guide \(guide.title, privacy: .public)")
            return
        }

        // Configure the audio session so sound plays through the speakers
        // even on Mac / when the device is silent.
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.audio.error("Failed to configure AVAudioSession: \(error.localizedDescription, privacy: .public)")
        }

        let player = AVPlayer(url: audioURL)
        // Don't stop at the end of the song; we loop it ourselves below.
        player.actionAtItemEnd = .none
        player.volume = 0.5

        // Loop the ambient track seamlessly.
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        // Log when the song is ready or fails, so a bad URL is easy to spot in the console.
        let fileName = audioURL.lastPathComponent
        player.currentItem?.publisher(for: \.status)
            .sink { [weak player] status in
                switch status {
                case .readyToPlay:
                    Logger.audio.info("Ready to play: \(fileName, privacy: .public)")
                case .failed:
                    let reason = player?.currentItem?.error?.localizedDescription ?? "unknown"
                    Logger.audio.error("Failed to load \(fileName, privacy: .public): \(reason, privacy: .public)")
                default:
                    break
                }
            }
            .store(in: &audioCancellables)

        audioPlayer = player
        if isRunning { playAmbientAudio() }
    }

    private func playAmbientAudio() {
        audioPlayer?.play()
    }

    private func pauseAmbientAudio() {
        audioPlayer?.pause()
    }

    /// Stops the music and removes the loop listener so nothing keeps running in the background.
    private func stopAmbientAudio() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
        audioPlayer = nil
    }
}

#Preview {
    GuideSessionView(guide: .preview)
        .environment(ImageryGuideStore())
}
