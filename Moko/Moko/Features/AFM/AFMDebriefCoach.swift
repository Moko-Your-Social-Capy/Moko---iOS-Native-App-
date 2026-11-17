//
//  AFMDebriefCoach.swift
//  Moko
//
//  The AI version of the debrief coach. It plugs into `QuestDebriefScreen(coach:)`
//  because it follows the same `DebriefCoaching` protocol as `DummyDebriefCoach`.
//
//  Every method tries AFM first. If AFM is unavailable, errors, or returns text
//  that fails a length check, the method falls back to the dummy coach or to the
//  Mission Bank's hand-written question, so the debrief always continues.
//

import Foundation

// MARK: - Stat <-> DebriefParameter Bridge

// `Stat` (AFM side) and `DebriefParameter` (screen side) have the same four cases.
// These two properties convert between them.

extension Stat {
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
    var stat: Stat {
        switch self {
        case .courage: return .courage
        case .clarity: return .clarity
        case .presence: return .presence
        case .warmth: return .warmth
        }
    }
}

// MARK: - Coach

@MainActor
final class AFMDebriefCoach: DebriefCoaching {
    /// Used whenever AFM can't help.
    private let fallbackCoach = DummyDebriefCoach()

    /// Short AFM notes about what the user did, fed back into later prompts.
    private var recordedObservations: [String] = []

    /// Every score AFM gave each stat during this debrief.
    private var recordedScores: [Stat: [Int]] = [:]

    /// The exact question shown for each stat, so `grade` judges the answer
    /// against what the user actually heard.
    private var askedQuestions: [Stat: String] = [:]

    /// Moko's first message.
    func greeting(for context: DebriefContext) async -> String {
        guard AFM.isAvailable else {
            return await fallbackCoach.greeting(for: context)
        }

        // `try?` turns an AFM error into nil, which skips straight to the fallback below.
        if let opening = try? await AFM.generate(
            DebriefOpening.self,
            instructions: DebriefPrompts.openingInstructions,
            prompt: DebriefPrompts.openingPrompt(context.afmContext),
            temperature: 0.5
        ) {
            let message = opening.message.trimmingCharacters(in: .whitespacesAndNewlines)
            if (10...260).contains(message.count) {
                return message
            }
        }

        return await fallbackCoach.greeting(for: context)
    }

    /// Moko's closing encouraging message after all follow-ups are answered.
    func closing(for context: DebriefContext, answers: [String], grades: [DebriefGrade]) async -> String {
        guard AFM.isAvailable else {
            return await fallbackCoach.closing(for: context, answers: answers, grades: grades)
        }

        let afmContext = context.afmContext
        if let closing = try? await AFM.generate(
            DebriefClosing.self,
            instructions: DebriefPrompts.closingInstructions,
            prompt: DebriefPrompts.closingPrompt(afmContext, answers: answers, observations: recordedObservations),
            temperature: 0.5
        ) {
            let message = closing.message.trimmingCharacters(in: .whitespacesAndNewlines)
            if (10...280).contains(message.count) {
                return message
            }
        }

        return await fallbackCoach.closing(for: context, answers: answers, grades: grades)
    }

    /// Follow-up question 1, 2 or 3. Each one targets a different stat:
    /// 1 → Presence, 2 → Clarity, 3 → Warmth. (Courage is read from the main answer.)
    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        guard AFM.isAvailable else {
            return await fallbackCoach.question(number: number, context: context, previousAnswers: previousAnswers)
        }

        let afmContext = context.afmContext
        let stat: Stat
        switch number {
        case 1: stat = .presence
        case 2: stat = .clarity
        default: stat = .warmth
        }

        // The Mission Bank's vetted question. AFM may only tailor it.
        let base = afmContext.template.followUps[stat] ?? "What is one specific thing you did or noticed?"

        // A very short answer (under 6 words) is left out of the prompt, otherwise AFM
        // splices fragments in awkwardly ("When you asked him about, were you...").
        let lastAnswer = previousAnswers.last ?? ""
        let lastAnswerWords = lastAnswer.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").count
        let userSaid = lastAnswerWords >= 6 ? lastAnswer : ""

        var text = base
        if let generated = try? await AFM.generate(
            FollowUpQuestionText.self,
            instructions: DebriefPrompts.questionInstructions,
            prompt: DebriefPrompts.questionPrompt(afmContext, stat: stat, base: base, userSaid: userSaid, differentFrom: nil),
            temperature: 0.4
        ) {
            // Keep AFM's version only if it is one question of a sensible length.
            let candidate = generated.question.trimmingCharacters(in: .whitespacesAndNewlines)
            if (10...220).contains(candidate.count) && candidate.filter({ $0 == "?" }).count == 1 {
                text = candidate
            }
        }

        askedQuestions[stat] = text
        return DebriefQuestion(text: text, focus: stat.parameter)
    }

    /// Scores one answer. `focus == nil` means the main story (Courage + Clarity);
    /// otherwise it is the follow-up for that one stat.
    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        guard AFM.isAvailable else {
            return await fallbackCoach.grade(answer: answer, focus: focus, context: context)
        }

        let afmContext = context.afmContext
        let wordCount = answer.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").count

        if let focus {
            // Follow-up answer: one stat.
            let targetStat = focus.stat
            let question = askedQuestions[targetStat] ?? afmContext.template.followUps[targetStat] ?? ""
            if let analysis = try? await AFM.generate(
                FollowUpAnalysis.self,
                instructions: DebriefPrompts.analysisInstructions,
                prompt: DebriefPrompts.followUpAnalysisPrompt(afmContext, stat: targetStat, question: question,
                                                              answer: answer, earlier: recordedObservations),
                temperature: 0.2
            ) {
                recordedObservations.append(analysis.whatUserDid)
                let score = Self.bounded(analysis.score)
                recordedScores[targetStat, default: []].append(score)

                return DebriefGrade(
                    confidence: calibrateConfidence(rawConfidence: analysis.confidence, wordCount: wordCount),
                    score: score,
                    note: sanitizeNote(analysis.confidenceNote, wordCount: wordCount),
                    focus: focus,
                    parameterScores: [focus: score]
                )
            }
        } else {
            // Main story: Courage and Clarity together.
            if let analysis = try? await AFM.generate(
                MainAnswerAnalysis.self,
                instructions: DebriefPrompts.analysisInstructions,
                prompt: DebriefPrompts.mainAnswerPrompt(afmContext, answer: answer),
                temperature: 0.2
            ) {
                recordedObservations.append(analysis.whatUserDid)
                let courage = Self.bounded(analysis.courage)
                let clarity = Self.bounded(analysis.clarity)
                recordedScores[.courage, default: []].append(courage)
                recordedScores[.clarity, default: []].append(clarity)

                return DebriefGrade(
                    confidence: calibrateConfidence(rawConfidence: analysis.confidence, wordCount: wordCount),
                    score: courage,
                    note: sanitizeNote(analysis.confidenceNote, wordCount: wordCount,
                                       defaultNote: "You showed up and spoke honestly. That takes courage."),
                    focus: nil,
                    parameterScores: [.courage: courage, .clarity: clarity]
                )
            }
        }

        return await fallbackCoach.grade(answer: answer, focus: focus, context: context)
    }

    /// The final 0–100 score per stat, shown on the results screen.
    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int] {
        let confidences = grades.map(\.confidence)
        let averageConfidence = confidences.isEmpty ? 70 : confidences.reduce(0, +) / confidences.count

        var result: [DebriefParameter: Int] = [:]
        for stat in Stat.allCases {
            if let scores = recordedScores[stat], !scores.isEmpty {
                // Average of what AFM gave this stat, kept in 45...98.
                let average = scores.reduce(0, +) / scores.count
                result[stat.parameter] = max(45, min(average, 98))
            } else {
                // No evidence for this stat: a calm baseline from the session's confidence (never 0).
                result[stat.parameter] = max(50, min(averageConfidence - 4, 88))
            }
        }
        return result
    }

    // MARK: - Helpers

    /// Keeps an AFM score in 45...100 so one rough answer never looks harsh.
    private static func bounded(_ score: Int) -> Int {
        max(45, min(score, 100))
    }

    /// Short answers can't earn high confidence, however AFM rated them.
    private func calibrateConfidence(rawConfidence: Int, wordCount: Int) -> Int {
        switch wordCount {
        case ..<6:
            // Very short or unfinished, e.g. "I asked him about".
            return min(rawConfidence, max(42, 42 + wordCount))
        case ..<12:
            return min(rawConfidence, 58)
        case ..<22:
            return min(rawConfidence, 72)
        default:
            return max(50, min(rawConfidence, 96))
        }
    }

    /// The note under the confidence bar. Very short answers get a gentle nudge instead.
    private func sanitizeNote(_ rawNote: String, wordCount: Int, defaultNote: String = "Honest and specific response.") -> String {
        if wordCount < 6 {
            return "A brief start — sharing a little more detail about what happened will help capture your progress."
        }
        let trimmed = rawNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultNote : trimmed
    }
}
