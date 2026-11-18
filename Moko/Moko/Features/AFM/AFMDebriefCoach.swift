//
//  AFMDebriefCoach.swift
//  Moko
//
//  The AFM-only debrief coach. Every coach message and assessment comes from
//  Apple Foundation Models; errors are thrown to the screen for an explicit retry.
//

import Foundation

// MARK: - Stat <-> DebriefParameter Bridge

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

// MARK: - AFM output bridges

extension Evidence {
    var debriefLevel: DebriefEvidenceLevel {
        switch self {
        case .missing: return .missing
        case .partial: return .partial
        case .clear: return .clear
        }
    }
}

extension DebriefInputKind {
    var debriefCategory: DebriefInputCategory {
        switch self {
        case .substantive: return .substantive
        case .weak: return .weak
        case .noEvidence: return .noEvidence
        case .gibberish: return .gibberish
        case .offTopic: return .offTopic
        case .joke: return .joke
        case .oneWord: return .oneWord
        case .otherLanguage: return .otherLanguage
        case .emojiOnly: return .emojiOnly
        case .pastedText: return .pastedText
        case .transcriptionUnclear: return .transcriptionUnclear
        }
    }
}

extension DebriefCoverageDecision {
    var debriefCoverage: DebriefCoverage {
        switch self {
        case .needsMore: return .needsMore
        case .sufficient: return .sufficient
        }
    }
}

// MARK: - Coach

@MainActor
final class AFMDebriefCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async throws -> String {
        let opening = try await AFM.generate(
            DebriefOpening.self,
            instructions: DebriefPrompts.openingInstructions,
            prompt: DebriefPrompts.openingPrompt(context.afmContext),
            temperature: 0.5,
            priority: .high,
            timeoutSeconds: 16.0
        )
        return try validated(opening.message, requiresQuestion: true)
    }

    func closing(for context: DebriefContext, answers: [String], grades: [DebriefGrade]) async throws -> String {
        let closing = try await AFM.generate(
            DebriefClosing.self,
            instructions: DebriefPrompts.closingInstructions,
            prompt: DebriefPrompts.closingPrompt(context.afmContext, answers: answers, observations: []),
            temperature: 0.5,
            priority: .high,
            timeoutSeconds: 16.0
        )
        return try validated(closing.message)
    }

    /// Swift picks an uncovered stat; AFM writes around the latest accepted answer.
    func question(number: Int, context: DebriefContext, previousAnswers: [String],
                  previousQuestions: [String], grades: [DebriefGrade]) async throws -> DebriefQuestion {
        let focus = DebriefScoring.nextFocus(from: grades)
        let adaptive = try await AFM.generate(
            AdaptiveFollowUpQuestion.self,
            instructions: DebriefPrompts.adaptiveQuestionInstructions,
            prompt: DebriefPrompts.adaptiveQuestionPrompt(
                context.afmContext,
                targetStat: focus.stat,
                previousQuestions: previousQuestions,
                answers: previousAnswers,
                evidenceSummary: DebriefScoring.evidenceSummary(from: grades)
            ),
            temperature: 0.4,
            priority: .high,
            timeoutSeconds: 16.0
        )
        let text = try validated(adaptive.question, requiresQuestion: true, maximum: 240)
        return DebriefQuestion(text: text, focus: focus)
    }

    /// Classification happens before scoring. Rejected input produces no grade or coverage.
    func assess(answer: String, question: String, focus: DebriefParameter?, context: DebriefContext,
                previousAnswers: [String]) async throws -> DebriefAssessment {
        let analysis = try await AFM.generate(
            DebriefTurnAnalysis.self,
            instructions: DebriefPrompts.analysisInstructions,
            prompt: DebriefPrompts.turnAnalysisPrompt(
                context.afmContext,
                question: question,
                answer: answer,
                earlierAcceptedAnswers: previousAnswers,
                targetStat: focus?.stat
            ),
            temperature: 0.2,
            priority: .high,
            timeoutSeconds: 16.0
        )

        let category = analysis.inputKind.debriefCategory
        let evidence: [DebriefParameter: DebriefEvidenceLevel] = [
            .courage: analysis.courageEvidence.debriefLevel,
            .clarity: analysis.clarityEvidence.debriefLevel,
            .presence: analysis.presenceEvidence.debriefLevel,
            .warmth: analysis.warmthEvidence.debriefLevel
        ]
        let hasRequiredEvidence = DebriefScoring.hasRequiredEvidence(evidence, focus: focus)

        if analysis.status == .needsClarification || !hasRequiredEvidence {
            let message = try await clarification(
                analysis.clarificationMessage,
                context: context,
                question: question,
                answer: answer,
                kind: analysis.inputKind
            )
            return .retry(message: message, category: category)
        }

        var scores: [DebriefParameter: Int] = [:]
        var measuredEvidence: [DebriefParameter: DebriefEvidenceLevel] = [:]
        let rawScores: [DebriefParameter: Int] = [
            .courage: analysis.courage,
            .clarity: analysis.clarity,
            .presence: analysis.presence,
            .warmth: analysis.warmth
        ]
        for parameter in DebriefParameter.allCases where evidence[parameter] != .missing {
            scores[parameter] = rawScores[parameter]
            measuredEvidence[parameter] = evidence[parameter]
        }

        var note = analysis.confidenceNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isEmpty { note = "Direct and relevant response." }
        var observation = analysis.whatUserDid.trimmingCharacters(in: .whitespacesAndNewlines)
        if observation.isEmpty { observation = "Shared clear details about the interaction." }
        guard !scores.isEmpty else {
            throw AFMError.generationFailed("AFM returned an incomplete accepted-answer assessment. Please try again.")
        }

        let targetScore = focus.flatMap { scores[$0] } ?? scores[.courage] ?? scores[.clarity] ?? 0
        let grade = DebriefGrade(
            confidence: analysis.confidence,
            score: targetScore,
            note: note,
            focus: focus,
            parameterScores: scores,
            parameterEvidence: measuredEvidence,
            category: category,
            coverage: analysis.coverage.debriefCoverage
        )
        DebriefCalibrationStore.record(grade, questCategory: context.category)
        return .accepted(grade)
    }

    /// Uses the analysis reply when present, otherwise asks AFM to write the missing reply.
    private func clarification(_ candidate: String, context: DebriefContext, question: String,
                               answer: String, kind: DebriefInputKind) async throws -> String {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        if (10...280).contains(trimmed.count) { return trimmed }

        let generated = try await AFM.generate(
            DebriefClarification.self,
            instructions: DebriefPrompts.clarificationInstructions,
            prompt: DebriefPrompts.clarificationPrompt(
                context.afmContext,
                question: question,
                answer: answer,
                kind: kind
            ),
            temperature: 0.5,
            priority: .high,
            timeoutSeconds: 16.0
        )
        return try validated(generated.message, maximum: 280)
    }

    /// Rejects malformed model copy while safely formatting valid responses.
    private func validated(_ rawText: String, requiresQuestion: Bool = false,
                           maximum: Int = 280) throws -> String {
        var text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (8...maximum).contains(text.count) else {
            throw AFMError.generationFailed("AFM returned an empty or malformed coach message. Please try again.")
        }
        if requiresQuestion {
            let questionMarks = text.filter({ $0 == "?" }).count
            if questionMarks == 0 {
                if text.hasSuffix(".") || text.hasSuffix("!") {
                    text.removeLast()
                }
                text.append("?")
            }
        }
        return text
    }
}
