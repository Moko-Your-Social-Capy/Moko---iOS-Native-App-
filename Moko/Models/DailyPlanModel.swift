import Foundation
import SwiftData

@Model
final class DailyPlan {
    @Attribute(.unique) var id: UUID
    var date: Date // startOfDay
    var questId: String
    var reason: String // weakSkill | onboardingPath | mix
    var weakSkill: String?
    var onboardingTheme: String
    var difficultyTarget: Int // 1-5
    var copyJSON: String
    var generatedAt: Date
    var status: String // planned | active | done | swapped | missed

    init(
        date: Date,
        questId: String,
        reason: String,
        weakSkill: String? = nil,
        onboardingTheme: String,
        difficultyTarget: Int,
        copyJSON: String,
        status: String = "planned"
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.questId = questId
        self.reason = reason
        self.weakSkill = weakSkill
        self.onboardingTheme = onboardingTheme
        self.difficultyTarget = max(1, min(5, difficultyTarget))
        self.copyJSON = copyJSON
        self.generatedAt = Date()
        self.status = status
    }
}
