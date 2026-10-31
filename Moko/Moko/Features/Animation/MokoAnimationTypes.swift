
import Foundation
import Lottie

/// All available MOKO mascot animations.
enum MokoAnimationType: String, CaseIterable, Identifiable {

    case hello = "MokoHello"
    case meditation = "MokoMeditation"
    case complete = "MokoComplete"
    case listening = "MokoListening"
    case idle = "MokoIdle"

    var id: String {
        rawValue
    }

    var lottieName: String {
        rawValue
    }

    /// Determines the playback behavior of each animation.
    var loopMode: LottieLoopMode {
        switch self {
        case .hello, .complete:
            return .playOnce

        case .meditation, .listening, .idle:
            return .loop
        }
    }

    static var all: [MokoAnimationType] {
        allCases
    }
}
