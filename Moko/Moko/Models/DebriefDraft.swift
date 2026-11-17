//
//  DebriefDraft.swift
//  Moko
//
//  A snapshot of an unfinished debrief. "Finish Later" leaves the conversation here, so
//  "Slide to Resume" reopens the coach exactly where the user stopped instead of replaying
//  the greeting and the first question from the top.
//

import Foundation

struct DebriefDraft: Codable {

    struct Message: Codable {
        enum Role: String, Codable {
            case coach
            case user
            case divider
        }

        var role: Role
        var text: String
        var grade: Grade?
        var question: Int

        init(role: Role, text: String = "", grade: Grade? = nil, question: Int = 0) {
            self.role = role
            self.text = text
            self.grade = grade
            self.question = question
        }
    }

    struct Grade: Codable {
        var confidence: Int
        var score: Int
        var note: String
        var focus: String?
        var parameterScores: [String: Int]
        var parameterEvidence: [String: String]?
        var category: String?
        var coverage: String?
    }

    /// The conversation exactly as it was, including a trailing "FOLLOW-UP QUESTIONS" divider
    /// when the coach had not asked that question yet — the follow-up is re-asked on resume.
    var messages: [Message]
    var answers: [String]
    var grades: [Grade]
    /// 0 = the opening story; 1...3 = the required adaptive follow-ups.
    var questionNumber: Int
    /// The parameter the next answer is graded on (nil for the opening story).
    var focus: String?
    /// The exact question to retry after resuming. Optional for older saved drafts.
    var currentQuestion: String?
    /// Optional so drafts saved by older app versions still decode.
    var isComplete: Bool?
}

// MARK: - Converting to and from the live types
extension DebriefDraft.Grade {
    init(_ grade: DebriefGrade) {
        self.confidence = grade.confidence
        self.score = grade.score
        self.note = grade.note
        self.focus = grade.focus?.rawValue
        self.parameterScores = Dictionary(
            uniqueKeysWithValues: grade.parameterScores.map { ($0.key.rawValue, $0.value) }
        )
        self.parameterEvidence = Dictionary(
            uniqueKeysWithValues: grade.parameterEvidence.map { ($0.key.rawValue, $0.value.rawValue) }
        )
        self.category = grade.category.rawValue
        self.coverage = grade.coverage.rawValue
    }

    var restored: DebriefGrade {
        let restoredScores = Dictionary(
            uniqueKeysWithValues: parameterScores.compactMap { key, value in
                DebriefParameter(rawValue: key).map { ($0, value) }
            }
        )
        let restoredEvidence: [DebriefParameter: DebriefEvidenceLevel]
        if let parameterEvidence {
            restoredEvidence = Dictionary(
                uniqueKeysWithValues: parameterEvidence.compactMap { key, value in
                    guard let parameter = DebriefParameter(rawValue: key),
                          let evidence = DebriefEvidenceLevel(rawValue: value) else { return nil }
                    return (parameter, evidence)
                }
            )
        } else {
            // Older drafts stored scores without evidence labels; preserve their measured values.
            restoredEvidence = Dictionary(uniqueKeysWithValues: restoredScores.keys.map { ($0, .clear) })
        }

        return DebriefGrade(
            confidence: confidence,
            score: score,
            note: note,
            focus: focus.flatMap(DebriefParameter.init(rawValue:)),
            parameterScores: restoredScores,
            parameterEvidence: restoredEvidence,
            category: category.flatMap(DebriefInputCategory.init(rawValue:)) ?? .substantive,
            coverage: coverage.flatMap(DebriefCoverage.init(rawValue:)) ?? .needsMore
        )
    }
}

// MARK: - Storage
/// One draft per quest, kept in UserDefaults so a resumed debrief survives app relaunches.
enum DebriefDraftStore {
    private static let prefix = "moko.debriefDraft."

    private static func key(for questID: UUID) -> String {
        prefix + questID.uuidString
    }

    static func save(_ draft: DebriefDraft, for questID: UUID) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: key(for: questID))
    }

    static func load(for questID: UUID) -> DebriefDraft? {
        guard let data = UserDefaults.standard.data(forKey: key(for: questID)) else { return nil }
        return try? JSONDecoder().decode(DebriefDraft.self, from: data)
    }

    static func clear(for questID: UUID) {
        UserDefaults.standard.removeObject(forKey: key(for: questID))
    }

    /// Wipes every draft — used when the signed-in account is deleted.
    static func clearAll() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
