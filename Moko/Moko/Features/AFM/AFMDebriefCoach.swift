// AFMDebriefCoach.swift
// Bridges Apple Foundation Models to the app's existing QuestDebriefScreen.
// Conforms to DebriefCoaching so it can be passed directly to QuestDebriefScreen(coach:).

import Foundation

// MARK: - Stat <-> DebriefParameter Bridge

extension Stat {
    init?(parameter: DebriefParameter) {
        switch parameter {
        case .courage: self = .courage
        case .clarity: self = .clarity
        case .presence: self = .presence
        case .warmth: self = .warmth
        }
    }

    var parameter: DebriefParameter {
        switch self {
        case .courage: return .courage
        case .clarity: return .clarity
        case .presence: return .presence
        case .warmth: return .warmth
        }
    }
}

extension DebriefParameter {
    init(stat: Stat) {
        switch stat {
        case .courage: self = .courage
        case .clarity: self = .clarity
        case .presence: self = .presence
        case .warmth: self = .warmth
        }
    }

    var stat: Stat {
        switch self {
        case .courage: return .courage
        case .clarity: return .clarity
        case .presence: return .presence
        case .warmth: return .warmth
        }
    }
}

@MainActor
final class AFMDebriefCoach: DebriefCoaching {
    private let fallbackCoach = DummyDebriefCoach()
    private var recordedObservations: [String] = []
    private var recordedScores: [Stat: [Int]] = [:]

    func greeting(for context: DebriefContext) async -> String {
        guard AFM.isAvailable else {
            return await fallbackCoach.greeting(for: context)
        }

        let afmContext = context.afmContext
        if let opening = try? await AFM.generate(
            DebriefOpening.self,
            instructions: DebriefPrompts.openingInstructions,
            prompt: DebriefPrompts.openingPrompt(afmContext),
            temperature: 0.5
        ) {
            let msg = opening.message.trimmingCharacters(in: .whitespacesAndNewlines)
            if msg.count >= 10 && msg.count <= 260 {
                return msg
            }
        }

        return "Hey\(context.userName.isEmpty ? "!" : " \(context.userName)!") How did it go — did you manage to do it?"
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        guard AFM.isAvailable else {
            return await fallbackCoach.question(number: number, context: context, previousAnswers: previousAnswers)
        }

        let afmContext = context.afmContext
        let stat: Stat
        switch number {
        case 1:
            stat = .presence
        case 2:
            stat = .clarity
        default:
            stat = .warmth
        }

        let base = afmContext.template.followUps[stat] ?? "What is one specific thing you did or noticed?"
        let rawUserSaid = previousAnswers.last ?? ""
        let userWordCount = rawUserSaid.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").count
        // If the user answer was a short fragment or under 6 words, don't pass it as context
        // to avoid awkward splicing like "When you asked him about, were you..."
        let userSaid = userWordCount >= 6 ? rawUserSaid : ""

        if let gen = try? await AFM.generate(
            FollowUpQuestionText.self,
            instructions: DebriefPrompts.questionInstructions,
            prompt: DebriefPrompts.questionPrompt(afmContext, stat: stat, base: base, userSaid: userSaid, differentFrom: nil),
            temperature: 0.4
        ) {
            let q = gen.question.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.count >= 10 && q.count <= 220 && q.filter({ $0 == "?" }).count == 1 {
                return DebriefQuestion(text: q, focus: stat.parameter)
            }
        }

        return DebriefQuestion(text: base, focus: stat.parameter)
    }

    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        guard AFM.isAvailable else {
            return await fallbackCoach.grade(answer: answer, focus: focus, context: context)
        }

        let afmContext = context.afmContext
        let words = answer.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let wordCount = words.count

        if let focus {
            // Follow-up answer analysis
            let targetStat = focus.stat
            let question = afmContext.template.followUps[targetStat] ?? ""
            if let a = try? await AFM.generate(
                FollowUpAnalysis.self,
                instructions: DebriefPrompts.analysisInstructions,
                prompt: DebriefPrompts.followUpAnalysisPrompt(afmContext, stat: targetStat, question: question, answer: answer, earlier: recordedObservations),
                temperature: 0.2
            ) {
                recordedObservations.append(a.whatUserDid)
                let note = sanitizeNote(a.confidenceNote, wordCount: wordCount)
                let boundedScore = max(45, min(a.score, 100))
                let calibratedConf = calibrateConfidence(rawConfidence: a.confidence, wordCount: wordCount)

                recordedScores[targetStat, default: []].append(boundedScore)

                return DebriefGrade(
                    confidence: calibratedConf,
                    score: boundedScore,
                    note: note,
                    focus: focus,
                    parameterScores: [focus: boundedScore]
                )
            }
        } else {
            // Main opening story analysis (grades courage & clarity together)
            if let a = try? await AFM.generate(
                MainAnswerAnalysis.self,
                instructions: DebriefPrompts.analysisInstructions,
                prompt: DebriefPrompts.mainAnswerPrompt(afmContext, answer: answer),
                temperature: 0.2
            ) {
                recordedObservations.append(a.whatUserDid)
                let note = sanitizeNote(a.confidenceNote, wordCount: wordCount, defaultNote: "You showed up and spoke honestly. That takes courage.")
                let boundedCourage = max(45, min(a.courage, 100))
                let boundedClarity = max(45, min(a.clarity, 100))
                let calibratedConf = calibrateConfidence(rawConfidence: a.confidence, wordCount: wordCount)

                recordedScores[.courage, default: []].append(boundedCourage)
                recordedScores[.clarity, default: []].append(boundedClarity)

                return DebriefGrade(
                    confidence: calibratedConf,
                    score: boundedCourage,
                    note: note,
                    focus: nil,
                    parameterScores: [.courage: boundedCourage, .clarity: boundedClarity]
                )
            }
        }

        return await fallbackCoach.grade(answer: answer, focus: focus, context: context)
    }

    private func calibrateConfidence(rawConfidence: Int, wordCount: Int) -> Int {
        if wordCount < 6 {
            // Incomplete or extremely brief answer (e.g. "I asked him about")
            return min(rawConfidence, max(42, 42 + wordCount))
        } else if wordCount < 12 {
            return min(rawConfidence, 58)
        } else if wordCount < 22 {
            return min(rawConfidence, 72)
        } else {
            return max(50, min(rawConfidence, 96))
        }
    }

    private func sanitizeNote(_ rawNote: String, wordCount: Int, defaultNote: String = "Honest and specific response.") -> String {
        let trimmed = rawNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if wordCount < 6 {
            return "A brief start — sharing a little more detail about what happened will help capture your progress."
        }
        return trimmed.isEmpty ? defaultNote : trimmed
    }

    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int] {
        var result: [DebriefParameter: Int] = [:]

        let confidences = grades.map { $0.confidence }
        let avgConf = confidences.isEmpty ? 70 : confidences.reduce(0, +) / confidences.count

        for stat in Stat.allCases {
            let param = stat.parameter
            if let list = recordedScores[stat], !list.isEmpty {
                let avg = list.reduce(0, +) / list.count
                result[param] = max(45, min(avg, 98))
            } else {
                // For stats not explicitly recorded, use calibrated baseline from session confidence (never 0!)
                result[param] = max(50, min(avgConf - 4, 88))
            }
        }

        return result
    }
}
