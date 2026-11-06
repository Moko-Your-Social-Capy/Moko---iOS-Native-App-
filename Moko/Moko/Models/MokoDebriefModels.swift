import Foundation
import SwiftData

enum DebriefStatus: String, CaseIterable, Codable { case inProgress, saved, skipped }
enum DebriefSource: String, CaseIterable, Codable { case afm, fallback }
enum DebriefSyncState: String, CaseIterable, Codable { case pending, synced }
enum MokoSkill: String, CaseIterable, Codable, Identifiable {
    case courage, clarity, presence, warmth
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

@Model
final class DebriefSession {
    @Attribute(.unique) var id: UUID = UUID()
    var questId: UUID = UUID()
    var questTitle: String = ""
    var category: String = ""
    var createdAt: Date = Date()
    var completedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \DebriefTurn.session) var turns: [DebriefTurn] = []
    var tokens: [String] = []
    var sourceRaw: String = "fallback"
    var statusRaw: String = "inProgress"
    var syncStateRaw: String = "pending"

    var status: DebriefStatus { get { DebriefStatus(rawValue: statusRaw) ?? .inProgress } set { statusRaw = newValue.rawValue } }
    var source: DebriefSource { get { DebriefSource(rawValue: sourceRaw) ?? .fallback } set { sourceRaw = newValue.rawValue } }
    var syncState: DebriefSyncState { get { DebriefSyncState(rawValue: syncStateRaw) ?? .pending } set { syncStateRaw = newValue.rawValue } }

    init(quest: Quest) {
        questId = quest.id; questTitle = quest.title; category = quest.category.rawValue
    }
}

@Model
final class DebriefTurn {
    var index: Int = 0
    var question: String = ""
    var answer: String = ""
    var askedAt: Date = Date()
    var session: DebriefSession?
    init(index: Int = 0, question: String = "", answer: String = "", session: DebriefSession? = nil) {
        self.index = index; self.question = question; self.answer = answer; self.session = session
    }
}

@Model
final class SkillScore {
    @Attribute(.unique) var id: UUID = UUID()
    var sessionId: UUID = UUID()
    var skillRaw: String = MokoSkill.courage.rawValue
    var level: Int = 1
    var evidence: String = "No clear sign, rate yourself."
    var nextStep: String = "Notice one concrete detail next time."
    var capReason: String?
    var judgeRuns: Int = 0
    var syncStateRaw: String = "pending"
    var skill: MokoSkill { get { MokoSkill(rawValue: skillRaw) ?? .courage } set { skillRaw = newValue.rawValue } }
    init(sessionId: UUID, skill: MokoSkill, level: Int = 1, evidence: String = "No clear sign, rate yourself.", nextStep: String = "Notice one concrete detail next time.", capReason: String? = nil, judgeRuns: Int = 0) {
        self.sessionId = sessionId; skillRaw = skill.rawValue; self.level = level; self.evidence = evidence; self.nextStep = nextStep; self.capReason = capReason; self.judgeRuns = judgeRuns
    }
}

@Model
final class ScoreReport {
    @Attribute(.unique) var id: UUID = UUID()
    var sessionId: UUID = UUID()
    var skillRaw: String = "courage"
    var note: String = ""
    var createdAt: Date = Date()
    var syncStateRaw: String = "pending"
    init(sessionId: UUID, skill: MokoSkill, note: String = "") { self.sessionId = sessionId; skillRaw = skill.rawValue; self.note = note }
}

@Model
final class MissionResult {
    @Attribute(.unique) var id: UUID = UUID()
    @Attribute(.unique) var sessionId: UUID = UUID()
    var missionId: UUID = UUID()
    var date: Date = Date()
    var missionTitle: String = ""
    var category: String = ""
    var xpEarned: Int = 0
    var courage: Int = 0
    var clarity: Int = 0
    var presence: Int = 0
    var warmth: Int = 0
    var linkedQuestId: UUID = UUID()
    var syncStateRaw: String = "pending"
    init(session: DebriefSession, xpEarned: Int, scores: [MokoSkill: Int]) {
        sessionId = session.id; missionId = session.questId; linkedQuestId = session.questId
        missionTitle = session.questTitle; category = session.category; self.xpEarned = xpEarned
        courage = (scores[.courage] ?? 3) * 20; clarity = (scores[.clarity] ?? 3) * 20
        presence = (scores[.presence] ?? 3) * 20; warmth = (scores[.warmth] ?? 3) * 20
    }
}

enum DebriefXP { static let completion = 20; static let finished = 10; static let followUp = 5 }
