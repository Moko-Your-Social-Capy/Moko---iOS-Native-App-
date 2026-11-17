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

    /// History of all asked questions in chronological order to prevent repetition.
    private var allAskedQuestions: [String] = []

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
                allAskedQuestions.append(message)
                return message
            }
        }

        let fallbackGreeting = await fallbackCoach.greeting(for: context)
        allAskedQuestions.append(fallbackGreeting)
        return fallbackGreeting
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

    /// Adaptive, non-repetitive follow-up question (1, 2, or 3).
    /// Dynamically determines which social dimension to explore based on what the user
    /// has already said, avoiding repetition and ignoring meta commentary.
    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        guard AFM.isAvailable else {
            return await fallbackCoach.question(number: number, context: context, previousAnswers: previousAnswers)
        }

        let afmContext = context.afmContext
        let coveredStatsList = recordedScores.keys.map { $0.title }

        // Determine candidate stat if fallback is needed
        let fallbackStat: Stat = {
            let candidates: [Stat] = [.presence, .warmth, .clarity]
            return candidates.min(by: { (recordedScores[$0]?.count ?? 0) < (recordedScores[$1]?.count ?? 0) }) ?? .presence
        }()

        if let adaptive = try? await AFM.generate(
            AdaptiveFollowUpQuestion.self,
            instructions: DebriefPrompts.adaptiveQuestionInstructions,
            prompt: DebriefPrompts.adaptiveQuestionPrompt(
                afmContext,
                previousQuestions: allAskedQuestions,
                answers: previousAnswers,
                coveredStats: coveredStatsList
            ),
            temperature: 0.4
        ) {
            let candidateText = adaptive.question.trimmingCharacters(in: .whitespacesAndNewlines)
            if (10...240).contains(candidateText.count) && candidateText.filter({ $0 == "?" }).count == 1 {
                // Parse the chosen stat dynamically
                let chosenStat: Stat
                let lowerStat = adaptive.focusStat.lowercased()
                if lowerStat.contains("warm") {
                    chosenStat = .warmth
                } else if lowerStat.contains("pres") {
                    chosenStat = .presence
                } else if lowerStat.contains("clar") {
                    chosenStat = .clarity
                } else if lowerStat.contains("cour") {
                    chosenStat = .courage
                } else {
                    chosenStat = fallbackStat
                }

                askedQuestions[chosenStat] = candidateText
                allAskedQuestions.append(candidateText)
                return DebriefQuestion(text: candidateText, focus: chosenStat.parameter)
            }
        }

        // Fallback: use template question for uncovered stat
        let base = afmContext.template.followUps[fallbackStat] ?? "What is one specific thing you did or noticed?"
        askedQuestions[fallbackStat] = base
        allAskedQuestions.append(base)
        return DebriefQuestion(text: base, focus: fallbackStat.parameter)
    }

    /// Scores one answer. `focus == nil` means the main story (Courage + Clarity);
    /// otherwise it is the follow-up for that one stat, with secondary stat detection if demonstrated.
    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        guard AFM.isAvailable else {
            return await fallbackCoach.grade(answer: answer, focus: focus, context: context)
        }

        let afmContext = context.afmContext
        let wordCount = answer.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").count

        if let focus {
            // Follow-up answer: target stat + potential secondary stat.
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
                var paramScores: [DebriefParameter: Int] = [focus: score]

                // Secondary stat detection
                let secLower = analysis.secondaryStat.lowercased()
                let secondaryStat: Stat? = {
                    if secLower.contains("warm") { return .warmth }
                    if secLower.contains("pres") { return .presence }
                    if secLower.contains("clar") { return .clarity }
                    if secLower.contains("cour") { return .courage }
                    return nil
                }()
                if let secondaryStat, secondaryStat != targetStat, analysis.secondaryScore >= 45 {
                    let secScore = Self.bounded(analysis.secondaryScore)
                    recordedScores[secondaryStat, default: []].append(secScore)
                    paramScores[secondaryStat.parameter] = secScore
                }

                return DebriefGrade(
                    confidence: calibrateConfidence(rawConfidence: analysis.confidence, wordCount: wordCount),
                    score: score,
                    note: sanitizeNote(analysis.confidenceNote, wordCount: wordCount),
                    focus: focus,
                    parameterScores: paramScores
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
        let averageConfidence = confidences.isEmpty ? 75 : confidences.reduce(0, +) / confidences.count

        var result: [DebriefParameter: Int] = [:]
        for stat in Stat.allCases {
            if let scores = recordedScores[stat], !scores.isEmpty {
                // Average of what AFM gave this stat, kept in balanced 55...98.
                let average = scores.reduce(0, +) / scores.count
                result[stat.parameter] = max(55, min(average, 98))
            } else {
                // No explicit evidence for this stat: a balanced baseline from the session's confidence.
                result[stat.parameter] = max(55, min(averageConfidence - 2, 90))
            }
        }
        return result
    }

    // MARK: - Helpers

    /// Keeps an AFM score in 45...100 so one rough answer never looks harsh.
    private static func bounded(_ score: Int) -> Int {
        max(45, min(score, 100))
    }

    /// Confidence is content-based and authenticity-based.
    /// Concise, genuine answers receive full credit; only near-empty filler is dampened.
    private func calibrateConfidence(rawConfidence: Int, wordCount: Int) -> Int {
        if wordCount < 3 {
            // 1-2 words with no meaningful substance
            return max(42, min(rawConfidence, 58))
        }
        // Genuine responses get balanced, realistic confidence scores
        return max(58, min(rawConfidence, 98))
    }

    /// The note under the confidence bar.
    private func sanitizeNote(_ rawNote: String, wordCount: Int, defaultNote: String = "Honest and specific response.") -> String {
        if wordCount < 3 {
            return "A brief start — sharing a little more detail about what happened will help capture your progress."
        }
        let trimmed = rawNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultNote : trimmed
    }
}
