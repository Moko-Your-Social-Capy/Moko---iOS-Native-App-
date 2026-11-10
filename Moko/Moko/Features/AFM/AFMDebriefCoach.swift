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

        return "Welcome back! How did \(context.questTitle) go? Tell me what happened, in your own words."
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
            stat = .warmth
        default:
            stat = .courage
        }

        let base = afmContext.template.followUps[stat] ?? "What is one specific thing you did or noticed?"
        let userSaid = previousAnswers.last ?? ""

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
                let note = a.confidenceNote.trimmingCharacters(in: .whitespacesAndNewlines)
                return DebriefGrade(
                    confidence: min(max(a.confidence, 0), 100),
                    score: min(max(a.score, 0), 100),
                    note: note.isEmpty ? "Honest and specific response." : note,
                    focus: focus
                )
            }
        } else {
            // Main opening story analysis
            if let a = try? await AFM.generate(
                MainAnswerAnalysis.self,
                instructions: DebriefPrompts.analysisInstructions,
                prompt: DebriefPrompts.mainAnswerPrompt(afmContext, answer: answer),
                temperature: 0.2
            ) {
                recordedObservations.append(a.whatUserDid)
                let note = a.confidenceNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let combinedScore = max(a.courage, a.clarity)
                return DebriefGrade(
                    confidence: min(max(a.confidence, 0), 100),
                    score: min(max(combinedScore, 0), 100),
                    note: note.isEmpty ? "You showed up and spoke honestly. That takes courage." : note,
                    focus: nil
                )
            }
        }

        return await fallbackCoach.grade(answer: answer, focus: focus, context: context)
    }
}
