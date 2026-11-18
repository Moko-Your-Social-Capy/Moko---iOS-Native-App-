//
//  DebriefRegressionTests.swift
//  Moko
//
//  Debug checks for scoring, calibration and the adaptive debrief state machine.
//

import Foundation
import OSLog

@MainActor
struct DebriefRegressionTests {
    private static let logger = Logger(subsystem: "com.SRMIST.MokoApp", category: "DebriefTests")

    static func runAllTests() async {
        testFullRangeAndIndependentScores()
        testEvidenceWeightingAndMissingScores()
        testCalibrationSummary()
        testRequiredEvidenceRules()
        await testClarificationDoesNotAdvance()
        await testConciseStrongAnswerAdvances()
        await testThreeFollowUpsCoverEveryStat()
        await testAFMFailureDoesNotCreateDummyContent()
        logger.info("All Debrief regression tests passed.")
    }

    /// Zero and 100 remain valid measured scores; Courage and Clarity stay independent.
    private static func testFullRangeAndIndependentScores() {
        let grade = makeGrade(scores: [.courage: 0, .clarity: 100], evidence: [.courage: .clear, .clarity: .clear])
        let scores = DebriefScoring.finalScores(from: [grade])
        assert(scores[.courage] == 0, "A measured zero must not be lifted to a baseline")
        assert(scores[.clarity] == 100, "A measured 100 must not be capped")
        assert(scores[.presence] == nil, "Missing presence evidence must stay missing")
        assert(scores[.warmth] == nil, "Missing warmth evidence must stay missing")

        let relevant = makeGrade(scores: [.clarity: 100], evidence: [.clarity: .clear], confidence: 90)
        let lessRelevant = makeGrade(scores: [.clarity: 100], evidence: [.clarity: .clear], confidence: 10)
        assert(DebriefScoring.finalScores(from: [relevant]) == DebriefScoring.finalScores(from: [lessRelevant]),
               "Confidence must not scale an independent Clarity score")
        assert(relevant.confidence != lessRelevant.confidence,
               "Confidence remains a separate relevance measurement")
    }

    /// Clear 100 and partial 0 at equal relevance confidence produce 62.5, rounded once to 63.
    private static func testEvidenceWeightingAndMissingScores() {
        let strong = makeGrade(scores: [.courage: 100], evidence: [.courage: .clear])
        let weak = makeGrade(scores: [.courage: 0], evidence: [.courage: .partial], category: .weak)
        let scores = DebriefScoring.finalScores(from: [strong, weak])
        assert(scores[.courage] == 63, "Evidence weighting must use full precision before rounding")
        assert(DebriefScoring.finalScores(from: []).isEmpty, "No answers must not invent scores")
    }

    /// Calibration distributions distinguish a 72 from a 78 without saving answer text.
    private static func testCalibrationSummary() {
        let suiteName = "DebriefRegressionTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            assertionFailure("Could not create isolated calibration defaults")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        DebriefCalibrationStore.record(makeGrade(scores: [.courage: 72], evidence: [.courage: .clear]), questCategory: .work, defaults: defaults)
        DebriefCalibrationStore.record(makeGrade(scores: [.courage: 78], evidence: [.courage: .clear], category: .joke), questCategory: .work, defaults: defaults)
        let summary = DebriefCalibrationStore.summary(for: .courage, defaults: defaults)
        assert(summary?.count == 2, "Both accepted calibration samples should be stored")
        assert(summary?.mean == 75, "Calibration mean should distinguish the two raw scores")
        // Floating-point spread needs a small tolerance instead of exact decimal equality.
        assert(abs((summary?.standardDeviation ?? 0) - 3) < 0.0001, "Calibration spread should be 3, got \(summary?.standardDeviation ?? -1)")
        assert(summary?.minimum == 72 && summary?.maximum == 78, "Calibration range should preserve raw values")
        assert(DebriefCalibrationStore.samples(from: defaults).last?.inputCategory == DebriefInputCategory.joke.rawValue, "Odd but valid input needs its own category")
    }

    /// Relevant weak openings pass with any stat; unusable and off-target answers do not.
    private static func testRequiredEvidenceRules() {
        let reportedSpeech: [DebriefParameter: DebriefEvidenceLevel] = [
            .courage: .partial,
            .clarity: .partial,
            .presence: .missing,
            .warmth: .missing
        ]
        assert(DebriefScoring.hasRequiredEvidence(reportedSpeech, focus: nil),
               "Understandable reported speech must be a scorable opening")
        assert(!DebriefScoring.hasRequiredEvidence(reportedSpeech, focus: .presence),
                     "A Presence follow-up still needs Presence evidence")
        assert(DebriefScoring.hasRequiredEvidence(reportedSpeech, focus: .clarity),
               "Partial target evidence is enough to accept and score honestly")

        let warmthOnly: [DebriefParameter: DebriefEvidenceLevel] = [.warmth: .partial]
        assert(DebriefScoring.hasRequiredEvidence(warmthOnly, focus: nil),
               "An opening must not require Courage or Clarity specifically")

        let noEvidence = Dictionary(uniqueKeysWithValues: DebriefParameter.allCases.map { ($0, DebriefEvidenceLevel.missing) })
        assert(!DebriefScoring.hasRequiredEvidence(noEvidence, focus: nil),
               "Completely unusable openings must remain on clarification retry")
    }

    /// Gibberish receives coach text but does not score, count as an answer or advance.
    private static func testClarificationDoesNotAdvance() async {
        let coach = ScriptedDebriefCoach()
        coach.assessments = [
            .retry(message: "I could not understand that; what did you say to them?", category: .gibberish),
            .accepted(makeGrade(scores: [.courage: 64, .clarity: 81], evidence: [.courage: .partial, .clarity: .clear]))
        ]
        let session = DebriefSession(context: testContext, coach: coach)
        await session.start()
        session.submit("asdf")
        guard await waitUntil({ coach.assessmentCalls == 1 && !session.isCoachTyping }) else {
            assertionFailure("Clarification assessment did not finish")
            return
        }

        assert(session.questionNumber == 0, "Gibberish must not advance the follow-up number")
        assert(coach.questionCalls == 0, "Gibberish must not trigger a follow-up")
        assert(session.canAnswer, "The same question should accept another reply")
        if case .user(_, let grade, let pending)? = session.messages.first(where: {
            if case .user = $0.kind { return true }
            return false
        })?.kind {
            assert(grade == nil && !pending, "Rejected input must be visibly ungraded without a spinner")
        } else {
            assertionFailure("Rejected user bubble missing")
        }

        let validAnswer = "I told them I needed to leave, then asked how they felt about it."
        session.submit(validAnswer)
        guard await waitUntil({ coach.questionCalls == 1 && !session.isCoachTyping }) else {
            assertionFailure("Accepted answer did not advance")
            return
        }
        assert(session.questionNumber == 1, "A proper answer should advance exactly once")
        assert(coach.questionAnswers == [[validAnswer]], "Follow-ups must contain accepted answers only")
        session.cancelAll()
    }

    /// A concise direct answer can be substantive with strong stats without automatic maximum Confidence.
    private static func testConciseStrongAnswerAdvances() async {
        let coach = ScriptedDebriefCoach()
        coach.assessments = [
            .accepted(makeGrade(
                scores: [.courage: 95, .clarity: 100],
                evidence: [.courage: .clear, .clarity: .clear],
                category: .substantive,
                confidence: 82
            ))
        ]
        let session = DebriefSession(context: testContext, coach: coach)
        await session.start()

        let answer = "I told her I would meet tonight."
        session.submit(answer)
        guard await waitUntil({ coach.questionCalls == 1 && session.canAnswer }) else {
            assertionFailure("A concise strong opening did not advance")
            return
        }

        let grade = session.messages.compactMap { message -> DebriefGrade? in
            if case .user(_, let grade, _) = message.kind { return grade }
            return nil
        }.first
        assert(grade?.category == .substantive, "Brevity must not make an answer weak")
        assert(grade?.confidence == 82, "A concise answer should not default to Confidence 100")
        assert(grade?.parameterScores[.courage] == 95, "Courage is scored independently")
        assert(grade?.parameterScores[.clarity] == 100, "A short answer can have strong Clarity")
        assert(coach.questionAnswers == [[answer]], "The concise accepted answer enters follow-up context")
        session.cancelAll()
    }

    /// Even sufficient opening coverage leads to three follow-ups and four measured stats.
    private static func testThreeFollowUpsCoverEveryStat() async {
        let coach = ScriptedDebriefCoach()
        coach.assessments = [
            .accepted(makeGrade(
                scores: [.courage: 70, .clarity: 80],
                evidence: [.courage: .partial, .clarity: .partial],
                category: .weak,
                coverage: .sufficient
            )),
            .accepted(makeGrade(scores: [.presence: 65], evidence: [.presence: .clear])),
            .accepted(makeGrade(scores: [.warmth: 75], evidence: [.warmth: .clear])),
            .retry(message: "I did not catch a clear answer; what action did you take?", category: .gibberish),
            .accepted(makeGrade(
                scores: [.courage: 5],
                evidence: [.courage: .clear],
                category: .substantive,
                confidence: 84
            ))
        ]
        let session = DebriefSession(context: testContext, coach: coach)
        await session.start()

        session.submit("Well I told her that. I will call her and meet her sooner")
        guard await waitUntil({ coach.questionCalls == 1 && session.canAnswer }) else {
            assertionFailure("The opening did not lead to follow-up one")
            return
        }
        assert(!session.isComplete, "Sufficient opening coverage must not skip follow-ups")
        assert(coach.questionFocuses == [.presence], "The first missing stat should be Presence")

        session.submit("I noticed my friend pause before answering.")
        guard await waitUntil({ coach.questionCalls == 2 && session.canAnswer }) else {
            assertionFailure("Follow-up one did not lead to follow-up two")
            return
        }
        assert(coach.questionFocuses == [.presence, .warmth], "The remaining missing stat should come next")

        session.submit("I asked what they wanted and listened to their answer.")
        guard await waitUntil({ coach.questionCalls == 3 && session.canAnswer }) else {
            assertionFailure("Follow-up two did not lead to follow-up three")
            return
        }
        assert(coach.questionFocuses == [.presence, .warmth, .courage], "The weakest measured evidence should be revisited")

        session.submit("Vrvrreff")
        guard await waitUntil({ coach.assessmentCalls == 4 && session.canAnswer }) else {
            assertionFailure("The third-question gibberish retry did not finish")
            return
        }
        assert(!session.isComplete && session.questionNumber == 3, "Gibberish must not complete the debrief")
        assert(coach.questionCalls == 3, "A rejected retry must not add another follow-up")

        let negativeAnswer = "Well I have done nothing yet but I am planning to ditch her and do nothing"
        session.submit(negativeAnswer)
        guard await waitUntil({ session.isComplete }) else {
            assertionFailure("The third accepted follow-up did not finish the debrief")
            return
        }
        assert(session.questionNumber == 3, "The session should finish after exactly three follow-ups")
        assert(coach.questionCalls == 3, "No follow-up may be skipped or added")
        assert(coach.questionAnswers.map(\.count) == [1, 2, 3], "Each question needs the accepted conversation so far")
        assert(coach.closingCalls == 1, "Completion should use the coach's AFM closing path")
        assert(coach.closingAnswers.count == 4 && coach.closingAnswers.last == negativeAnswer,
               "The valid negative answer must reach the accepted closing context")
        assert(!coach.closingAnswers.contains("Vrvrreff"), "Rejected gibberish must stay out of the closing context")
        assert(session.result?.scores.count == 4, "All four stats need real evidence before completion")
        assert(DebriefParameter.allCases.allSatisfy { session.result?.scores[$0] != nil }, "No stat should be left unanswered")
        assert((session.result?.scores[.courage] ?? 100) < 70, "Clear avoidance should lower rather than erase Courage evidence")
        let finalGrade = session.messages.compactMap { message -> DebriefGrade? in
            if case .user(_, let grade, _) = message.kind { return grade }
            return nil
        }.last
        assert(finalGrade?.confidence == 84, "The calibrated AFM Confidence score must not be inflated by Swift")
        session.cancelAll()
    }

    /// An AFM availability error is exposed rather than replaced by a static greeting.
    private static func testAFMFailureDoesNotCreateDummyContent() async {
        let coach = ScriptedDebriefCoach()
        coach.greetingError = AFMError.unavailable(reason: "Test unavailable")
        let session = DebriefSession(context: testContext, coach: coach)
        await session.start()
        assert(session.coachingError == "Test unavailable", "The real AFM error should reach the screen")
        assert(session.messages.isEmpty, "AFM failure must not create dummy coaching")
        assert(!session.canAnswer, "A failed opening cannot accept an answer")
        session.cancelAll()
    }

    private static var testContext: DebriefContext {
        DebriefContext(questTitle: "Speak up", category: .work, intensity: .medium)
    }

    private static func makeGrade(scores: [DebriefParameter: Int],
                                  evidence: [DebriefParameter: DebriefEvidenceLevel],
                                  category: DebriefInputCategory = .substantive,
                                  confidence: Int = 80,
                                  coverage: DebriefCoverage = .needsMore) -> DebriefGrade {
        DebriefGrade(
            confidence: confidence,
            score: scores[.courage] ?? scores.values.first ?? 0,
            note: "Specific test evidence.",
            focus: nil,
            parameterScores: scores,
            parameterEvidence: evidence,
            category: category,
            coverage: coverage
        )
    }

    private static func waitUntil(_ condition: @escaping @MainActor () -> Bool) async -> Bool {
        for _ in 0..<100 {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }
}

/// A test double only. Production constructs AFMDebriefCoach directly and has no dummy fallback.
@MainActor
private final class ScriptedDebriefCoach: DebriefCoaching {
    var assessments: [DebriefAssessment] = []
    var greetingError: Error?
    private(set) var assessmentCalls = 0
    private(set) var questionCalls = 0
    private(set) var closingCalls = 0
    private(set) var closingAnswers: [String] = []
    private(set) var questionAnswers: [[String]] = []
    private(set) var questionFocuses: [DebriefParameter] = []

    func greeting(for context: DebriefContext) async throws -> String {
        if let greetingError { throw greetingError }
        return "How did the conversation go?"
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String],
                  previousQuestions: [String], grades: [DebriefGrade]) async throws -> DebriefQuestion {
        questionCalls += 1
        questionAnswers.append(previousAnswers)
        let focus = DebriefScoring.nextFocus(from: grades)
        questionFocuses.append(focus)
        return DebriefQuestion(text: "You mentioned speaking up; what did you notice next?", focus: focus)
    }

    func assess(answer: String, question: String, focus: DebriefParameter?, context: DebriefContext,
                previousAnswers: [String]) async throws -> DebriefAssessment {
        assessmentCalls += 1
        guard !assessments.isEmpty else { throw AFMError.generationFailed("Missing scripted assessment") }
        return assessments.removeFirst()
    }

    func closing(for context: DebriefContext, answers: [String], grades: [DebriefGrade]) async throws -> String {
        closingCalls += 1
        closingAnswers = answers
        return "You communicated with care and courage."
    }
}
