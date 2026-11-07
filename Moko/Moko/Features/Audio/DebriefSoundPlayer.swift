//
//  DebriefSoundPlayer.swift
//  Moko
//
//  Plays a short success sound whenever a debrief is successfully completed,
//  for both custom quests and Quest Library quests.
//

import AVFoundation
import Foundation

/// Shared player for the debrief-completion sound bundled in Assets.xcassets.
final class DebriefSoundPlayer {
    static let shared = DebriefSoundPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    /// Play the bundled `google-pay-success.mp3` once. Safe to call from any thread.
    func playSuccess() {
        guard let url = Self.soundURL else { return }
        do {
            // Create a fresh player each time so rapid repeats don't cut each other off.
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player  // keep it alive until playback finishes
        } catch {
            print("[DebriefSoundPlayer] Failed to play success sound: \(error)")
        }
    }

    /// Location of `google-pay-success.mp3` inside the app bundle.
    private static var soundURL: URL? {
        // The mp3 lives in Assets.xcassets/google-pay-success.dataset/. Try the
        // direct resource name first, then fall back to the dataset folder path.
        if let url = Bundle.main.url(forResource: "google-pay-success", withExtension: "mp3") {
            return url
        }
        if let url = Bundle.main.url(
            forResource: "google-pay-success",
            withExtension: "mp3",
            subdirectory: "google-pay-success.dataset"
        ) {
            return url
        }
        return nil
    }
}
