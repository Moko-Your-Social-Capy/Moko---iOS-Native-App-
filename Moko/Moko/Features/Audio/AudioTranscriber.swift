//
//  AudioTranscriber.swift
//  Moko
//
//  Live microphone recording (AVAudioEngine) with simultaneous real-time
//  speech transcription (SFSpeechRecognizer) for quest debriefing.
//

import Foundation
import AVFoundation
import Speech
import OSLog
import QuartzCore

// MARK: - Errors

enum AudioTranscriberError: LocalizedError {
    case engineFailed(String)
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .engineFailed(let message):
            return "Audio engine error: \(message)"
        case .recognizerUnavailable:
            return "Speech recognition is currently unavailable."
        }
    }
}

// MARK: - Transcriber

@MainActor
final class AudioTranscriber {

    // MARK: Callbacks (called on the main actor)

    /// Called each time Speech produces a new partial or final transcript.
    var onTranscriptUpdate: ((String) -> Void)?
    /// Called with the current RMS loudness (0.08…1.0) throttled to ~12 Hz.
    var onAudioLevelUpdate: ((Double) -> Void)?
    /// Called once per second with the elapsed recording time in seconds.
    var onTimerTick: ((Int) -> Void)?

    // MARK: State

    private(set) var isRecording = false
    /// The most recent transcript from Speech.
    private(set) var latestTranscript = ""

    // MARK: Private

    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timerTask: Task<Void, Never>?
    private var stopContinuation: CheckedContinuation<String, Never>?

    // MARK: Init

    init(locale: Locale = .current) {
        // SpeechRecognizer: Apple's on-device or server speech transcription
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: Start

    /// Opens the microphone and begins streaming audio to the Speech recogniser.
    func start() async throws {
        guard !isRecording else { return }

        // 1. Refresh recognizer if needed.
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }

        // 2. Audio session setup: playAndRecord allows both input and output.
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.duckOthers, .defaultToSpeaker, .allowBluetooth]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // 3. Audio engine setup.
        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0 else {
            throw AudioTranscriberError.engineFailed("Microphone has invalid sample rate (0 Hz).")
        }

        // 4. Speech recognition request.
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }
        recognitionRequest = request

        // 5. Shared state for audio level throttling (avoids overloading MainActor).
        let lastLevelTime = OSAllocatedUnfairLock(initialState: Double(0))

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] buffer, _ in
            // Append incoming audio buffer to speech recognition
            request.append(buffer)

            // Compute real-time audio power (RMS) to drive the visual waveform
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }

            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            let level = min(1.0, max(0.08, Double(rms) * 7.5))

            // Throttle UI waveform updates to ~12 updates/sec to prevent MainActor overload
            let now = CACurrentMediaTime()
            let shouldUpdate = lastLevelTime.withLock { last in
                if now - last > 0.08 {
                    last = now
                    return true
                }
                return false
            }

            if shouldUpdate {
                Task { @MainActor [weak self] in
                    self?.onAudioLevelUpdate?(level)
                }
            }
        }

        // 6. Start the recognition task.
        isRecording = true
        latestTranscript = ""
        stopContinuation = nil

        if let recognizer = speechRecognizer, recognizer.isAvailable {
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if let result {
                        let text = result.bestTranscription.formattedString
                        self.latestTranscript = text
                        self.onTranscriptUpdate?(text)

                        if result.isFinal {
                            self.resumeStop(with: text)
                        }
                    }

                    if let error {
                        Logger.audio.info("Speech recognition task event: \(error.localizedDescription)")
                        self.resumeStop(with: self.latestTranscript)
                    }
                }
            }
        } else {
            Logger.audio.info("SFSpeechRecognizer is unavailable or running on Simulator.")
        }

        // 7. Start the audio hardware engine.
        engine.prepare()
        try engine.start()

        // 8. Track recording elapsed time.
        var elapsed = 0
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled, self.isRecording else { break }
                elapsed += 1
                self.onTimerTick?(elapsed)

                #if targetEnvironment(simulator)
                // In Simulator, generate subtle waveform animation so the visualizer is alive
                if self.latestTranscript.isEmpty {
                    let simulatedLevel = Double.random(in: 0.15...0.45)
                    self.onAudioLevelUpdate?(simulatedLevel)
                }
                #endif
            }
        }
    }

    // MARK: Stop

    /// Signals end of audio and returns the full recognized transcript.
    func stop() async -> String {
        guard isRecording else {
            return latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        timerTask?.cancel()
        timerTask = nil
        isRecording = false

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()

        // Wait briefly (up to 0.8s) for Speech to finish final tokens.
        let final: String
        if recognitionTask != nil {
            final = await withCheckedContinuation { [weak self] cont in
                guard let self else { cont.resume(returning: ""); return }
                self.stopContinuation = cont

                Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(800))
                    self?.resumeStop(with: self?.latestTranscript ?? "")
                }
            }
        } else {
            final = latestTranscript
        }

        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        var resultText = final.trimmingCharacters(in: .whitespacesAndNewlines)

        #if targetEnvironment(simulator)
        if resultText.isEmpty {
            // SFSpeechRecognizer is physically unsupported on Simulator runtimes by Apple.
            // Provide a realistic spoken answer so debrief grading, confidence scoring,
            // and follow-ups can be tested on Simulator.
            resultText = "I completed the quest and had a good conversation. I felt a bit nervous at first, but I stayed present and really listened."
        }
        #endif

        return resultText
    }

    // MARK: Cancel

    /// Stops the engine and discards all audio and transcript immediately.
    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        isRecording = false

        resumeStop(with: "")

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        latestTranscript = ""
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Private helpers

    private func resumeStop(with text: String) {
        guard let cont = stopContinuation else { return }
        stopContinuation = nil
        cont.resume(returning: text)
    }
}
