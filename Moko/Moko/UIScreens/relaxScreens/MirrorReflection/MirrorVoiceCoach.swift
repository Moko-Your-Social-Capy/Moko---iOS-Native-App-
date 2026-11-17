//
//  MirrorVoiceCoach.swift
//  Moko
//
//  Listens to the user's voice during Mirror Reflection.
//
//  This file only measures how loud the microphone is. It does not record,
//  save or transcribe words. That keeps the practice private and lets it run
//  for the full two minutes without Speech framework limits.
//
//  The coach tells the screen three things:
//  1. Whether the microphone is ready, listening or unavailable.
//  2. Whether the user is speaking right now.
//  3. When the user has gone quiet, so Moko can gently nudge them.
//

import AVFoundation
import Foundation
import Observation
import OSLog

// MARK: - State

/// What the voice coach is doing. The screens show a small pill for this.
enum MirrorVoiceState: Equatable {
    case idle
    case preparing
    case ready
    case listening
    case unavailable(String)
}

// MARK: - Coach

@MainActor
@Observable
final class MirrorVoiceCoach {

    // MARK: What the screen reads

    /// The current microphone state.
    private(set) var state: MirrorVoiceState = .idle
    /// True while the microphone hears a voice.
    private(set) var isSpeaking = false
    /// 0...1 loudness. Moko and the listening bars breathe with this.
    private(set) var audioLevel: Double = 0
    /// When this is not nil, the screen shows "Continue saying."
    private(set) var nudge: String?
    /// Goes up each time a nudge appears, so the screen can play a soft haptic.
    private(set) var nudgeCount = 0

    /// True when voice is not available, so the screen can explain why.
    var isUnavailable: Bool {
        if case .unavailable = state { return true }
        return false
    }

    // MARK: Private

    // The audio engine is Apple's object that listens to the microphone.
    private var audioEngine: AVAudioEngine?
    // Watches the microphone level and decides when the user has gone quiet.
    private var monitorTask: Task<Void, Never>?
    // Hides the nudge after a few seconds so it stays subtle.
    private var nudgeHideTask: Task<Void, Never>?
    // The last time we heard the user's voice.
    private var lastVoiceAt = Date()
    // The last time we showed a nudge, so we do not nag too often.
    private var lastNudgeAt: Date?
    // One shared permission request, so two callers never ask twice.
    private var prepareTask: Task<Void, Never>?

    // How long the user can be quiet before Moko nudges them.
    private let silenceBeforeNudge: TimeInterval = 4.5
    // How long the nudge stays on screen.
    private let nudgeDuration: TimeInterval = 4
    // How long to wait before nudging again if the user stays quiet.
    private let nudgeCooldown: TimeInterval = 8
    // A voice is "speaking" for this long after the last loud moment.
    private let speakingMemory: TimeInterval = 0.8

    // MARK: - Permissions

    /// Asks for microphone access before the session starts.
    /// Safe to call more than once: the same request is shared.
    func prepare() async {
        switch state {
        case .ready, .listening, .unavailable:
            return
        case .preparing:
            if let prepareTask { await prepareTask.value }
            return
        case .idle:
            break
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await self.requestMicrophone()
            self.prepareTask = nil
        }
        prepareTask = task
        await task.value
    }

    private func requestMicrophone() async {
        state = .preparing

        let granted: Bool
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            granted = true
        case .undetermined:
            // First time: show Apple's "Allow microphone?" popup.
            granted = await AVAudioApplication.requestRecordPermission()
        case .denied:
            granted = false
        @unknown default:
            granted = await AVAudioApplication.requestRecordPermission()
        }

        state = granted ? .ready : .unavailable("Microphone access is off")
    }

    // MARK: - Listening

    /// Starts the microphone. The screen calls this when the timer starts.
    func startListening() async {
        guard state != .listening else { return }
        await prepare()
        // The user may have paused or left while the permission popup was open.
        guard !Task.isCancelled, state == .ready else { return }

        do {
            try startAudioEngine()
            // The screen may have moved on while the engine was starting.
            guard !Task.isCancelled else {
                stopAudioEngine()
                return
            }
            state = .listening
            lastVoiceAt = Date()
            lastNudgeAt = nil
            nudge = nil
            isSpeaking = false
            startMonitor()
        } catch {
            // Leave a breadcrumb if the microphone cannot start on a device.
            Logger.audio.error("Mirror voice could not start: \(error.localizedDescription, privacy: .public)")
            stopAudioEngine()
            state = .unavailable("Voice is unavailable")
        }
    }

    /// Stops the microphone and hides the nudge. Safe to call when already stopped.
    func stopListening() {
        guard state == .listening else { return }
        monitorTask?.cancel()
        monitorTask = nil
        nudgeHideTask?.cancel()
        nudgeHideTask = nil
        nudge = nil
        isSpeaking = false
        audioLevel = 0
        stopAudioEngine()
        state = .ready
    }

    /// Stops everything when the screen goes away.
    func stop() {
        stopListening()
        prepareTask?.cancel()
        prepareTask = nil
        if state == .ready { state = .idle }
    }

    /// Call when the affirmation changes, so the user gets a fresh moment
    /// to start reading before Moko nudges again.
    func affirmationChanged() {
        guard state == .listening else { return }
        lastVoiceAt = Date()
        lastNudgeAt = nil
        nudgeHideTask?.cancel()
        nudgeHideTask = nil
        nudge = nil
    }

    // MARK: - Audio engine

    private func startAudioEngine() throws {
        #if targetEnvironment(simulator)
        // CoreAudio can abort inside the Simulator when the Mac has no audio
        // input route for it. Skip the real engine there, so the timer and the
        // nudge can still be tested. A real iPhone uses the code below.
        Logger.audio.info("Mirror voice: Simulator fallback, microphone engine skipped.")
        audioEngine = nil
        return
        #else
        let session = AVAudioSession.sharedInstance()
        // .playAndRecord lets us listen without stopping other audio.
        // .mixWithOthers keeps any background music playing softly.
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothHFP]
        )
        try session.setActive(true)

        let engine = AVAudioEngine()
        audioEngine = engine

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            throw MirrorVoiceError.noMicrophone
        }

        input.removeTap(onBus: 0)
        // The tap receives small pieces of microphone audio about ten times a second.
        input.installTap(onBus: 0, bufferSize: 4_096, format: format) { [weak self] buffer, _ in
            let level = Self.loudness(from: buffer)
            // Hop back to the main actor before touching screen state.
            Task { @MainActor [weak self] in
                self?.handleLevel(level)
            }
        }

        engine.prepare()
        try engine.start()
        #endif
    }

    private func stopAudioEngine() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Turns one audio buffer into a 0.08...1.0 loudness value.
    private nonisolated static func loudness(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData?[0] else { return 0.08 }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0.08 }

        var sum: Float = 0
        for index in 0..<frames {
            let sample = channel[index]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frames))
        return min(1, max(0.08, Double(rms) * 7.5))
    }

    private func handleLevel(_ level: Double) {
        guard state == .listening else { return }
        audioLevel = level
        // Anything clearly above room noise counts as the user speaking.
        if level > 0.16 {
            noteVoice()
        }
    }

    // MARK: - Silence and nudges

    private func startMonitor() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, !Task.isCancelled else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard state == .listening else { return }
        let now = Date()
        let speaking = now.timeIntervalSince(lastVoiceAt) < speakingMemory

        if speaking != isSpeaking {
            isSpeaking = speaking
        }

        guard !speaking else { return }
        guard now.timeIntervalSince(lastVoiceAt) >= silenceBeforeNudge else { return }

        if let lastNudgeAt, now.timeIntervalSince(lastNudgeAt) < nudgeCooldown {
            return
        }

        showNudge()
    }

    private func noteVoice() {
        lastVoiceAt = Date()
        lastNudgeAt = nil
        if !isSpeaking { isSpeaking = true }

        if nudge != nil {
            nudgeHideTask?.cancel()
            nudgeHideTask = nil
            nudge = nil
        }
    }

    private func showNudge() {
        nudge = "Continue saying."
        lastNudgeAt = Date()
        nudgeCount += 1

        let duration = nudgeDuration
        nudgeHideTask?.cancel()
        nudgeHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, !Task.isCancelled else { return }
            // Only hide it if the user is still quiet.
            if Date().timeIntervalSince(self.lastVoiceAt) > 2 {
                self.nudge = nil
            }
        }
    }
}

// MARK: - Errors

enum MirrorVoiceError: LocalizedError {
    case noMicrophone

    var errorDescription: String? {
        switch self {
        case .noMicrophone:
            return "No microphone is available."
        }
    }
}
