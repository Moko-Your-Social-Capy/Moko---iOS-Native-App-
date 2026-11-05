import ActivityKit
import Foundation

nonisolated enum MokoBreathingPhase: String, Codable, Hashable, CaseIterable {
    case inhale
    case holdIn
    case exhale
    case holdOut

    var title: String {
        switch self {
        case .inhale: "Breathe in"
        case .holdIn, .holdOut: "Hold"
        case .exhale: "Breathe out"
        }
    }
}

nonisolated struct MokoCalmActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var phase: MokoBreathingPhase
        var progressFraction: Double
        var remaining: TimeInterval
        var phaseEndsAt: Date
        var sessionEndsAt: Date
        var isPaused: Bool
        var isComplete: Bool
    }

    var sessionID: UUID
}

nonisolated struct MokoQuestActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var progressStep: Int
        var isComplete: Bool
    }

    var questID: UUID
    var title: String
    var expiresAt: Date
}

nonisolated struct MokoStreakActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var reminderEndsAt: Date
    }

    var dayStart: Date
    var expiresAt: Date
}
