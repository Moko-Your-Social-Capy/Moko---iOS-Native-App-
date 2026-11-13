//
//  GuideSessionView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI
import SwiftData
import Combine
import AVFoundation

struct GuideSessionView: View {
    let guide: ImageryGuide
    var onContinue: () -> Void = {}

    @Environment(ImageryGuideStore.self) private var store
    @State private var elapsed: TimeInterval = 0
    @State private var isRunning = true           // starts as soon as the screen opens
    @State private var lastTick = Date()
    @State private var audioPlayer: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?
    @State private var audioCancellables = Set<AnyCancellable>()
    @Environment(\.modelContext) private var modelContext

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let accent   = MocoScreenTheme.Colors.dataVioletDeep
    private let tileFill = MocoScreenTheme.Colors.surfaceLavender
    private let ink      = MocoScreenTheme.Colors.textTitle
    private let caption  = MocoScreenTheme.Colors.textBody
    private let track    = MocoScreenTheme.Colors.surfaceLavender

    // MARK: Derived state

    private var screen: ImageryGuideScreenContent? { store.screen }
    private var totalSeconds: TimeInterval { TimeInterval(guide.durationSeconds) }
    private var steps: [String] { guide.sessionSteps.isEmpty ? [""] : guide.sessionSteps }
    private var isComplete: Bool { elapsed >= totalSeconds }

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

    private func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            panel
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.bottom, 22)
        }
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
        // Immersive session: give the guidance panel the full screen.
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadIfNeeded() }
        .onAppear { setupAmbientAudio() }
        .onChange(of: isRunning, initial: false) { _, newValue in
            if newValue { playAmbientAudio() } else { pauseAmbientAudio() }
        }
        .onReceive(ticker) { date in
            let dt = min(date.timeIntervalSince(lastTick), 0.5)
            lastTick = date
            guard isRunning, !isComplete else { return }
            elapsed = min(totalSeconds, elapsed + dt)
            if elapsed >= totalSeconds {
                isRunning = false
                modelContext.logCalmDown("Imagery Guide", seconds: totalSeconds)
            }
        }
        .onDisappear {
            isRunning = false
            stopAmbientAudio()
        }
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
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .tracking(0.3)
                    .foregroundStyle(caption)
                Spacer()
                if !isComplete { controls }
            }
            .frame(minHeight: 44)

            // Instruction (cross-fades when it changes)
            ZStack(alignment: .topLeading) {
                Text(instruction)
                    .mocoText(MocoScreenTheme.Typeface.section)
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
            .mocoText(MocoScreenTheme.Typeface.body)
            .monospacedDigit()
            .foregroundStyle(caption)
            .padding(.top, 10)

            // Appears once the timer is over
            if isComplete {
                Button(action: onContinue) {
                    Text(screen?.sessionContinueButton ?? "")
                        .mocoText(MocoScreenTheme.Typeface.cardTitle)
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
        .mocoCard()
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
                lastTick = Date()
                // Restart the ambient music from the beginning too.
                audioPlayer?.seek(to: .zero)
                if isRunning { playAmbientAudio() } else { pauseAmbientAudio() }
                isRunning = true
            }
            controlButton(icon: isRunning ? (screen?.sessionPauseIcon ?? "") : (screen?.sessionPlayIcon ?? ""),
                          label: isRunning ? (screen?.sessionPauseLabel ?? "") : (screen?.sessionPlayLabel ?? "")) {
                lastTick = Date()
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

    // MARK: Ambient background music

    /// Creates the AVPlayer for the guide's ambient track and starts it if the
    /// session is already running. The track loops softly for the whole session.
    private func setupAmbientAudio() {
        guard audioPlayer == nil else { return }
        guard let audioURL = guide.sessionAudioURL else {
            print("[ImageryAudio] No audioURL for guide \(guide.title)")
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
            print("[ImageryAudio] Failed to configure AVAudioSession: \(error)")
        }

        let player = AVPlayer(url: audioURL)
        player.actionAtItemEnd = .none
        player.volume = 0.5
        player.actionAtItemEnd = .none

        // Loop the ambient track seamlessly.
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        // Log when the item is ready / fails so we can diagnose URL issues.
        player.currentItem?.publisher(for: \.status)
            .sink { status in
                switch status {
                case .readyToPlay:
                    print("[ImageryAudio] Ready to play: \(audioURL.lastPathComponent)")
                case .failed:
                    print("[ImageryAudio] Failed to load: \(audioURL.lastPathComponent) — \(player.currentItem?.error?.localizedDescription ?? "unknown")")
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
        print("[ImageryAudio] Playing \(guide.sessionAudioURL?.lastPathComponent ?? "audio")")
    }

    private func pauseAmbientAudio() {
        audioPlayer?.pause()
        print("[ImageryAudio] Paused \(guide.sessionAudioURL?.lastPathComponent ?? "audio")")
    }

    private func stopAmbientAudio() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
        audioPlayer = nil
        print("[ImageryAudio] Stopped \(guide.sessionAudioURL?.lastPathComponent ?? "audio")")
    }
}

#Preview {
    GuideSessionView(guide: .preview)
        .environment(ImageryGuideStore())
}
