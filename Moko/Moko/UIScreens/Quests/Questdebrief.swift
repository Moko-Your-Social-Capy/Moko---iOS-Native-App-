//
//  QuestDebrief.swift
//  Moko
//
//  The debrief: a chat with the on-device coach after a quest.
//  1. The coach asks how the quest went (the "opening story").
//  2. AFM asks three follow-ups, targeting missing stats before weaker evidence.
//  Accepted answers get separate evidence and scores for Courage, Clarity, Presence and Warmth.
//  Unclear answers get a fresh AFM clarification and stay on the same question.
//
//  Who does what (good place to start debugging):
//  - `DebriefSession` (@Observable) holds the whole conversation and drives each step.
//  - `QuestDebriefScreen` draws it and saves the scores when it finishes.
//  - `AFMDebriefCoach` always uses Apple Foundation Models; failures are shown with a retry.
//  - Voice answers use AVFoundation + Speech for live microphone recording and real-time transcription.
//  - Leaving with "Finish Later" saves a draft (`DebriefDraftStore`) so it can resume.
//

import SwiftUI
import SwiftData
import Observation
import AVFoundation
import Speech
import OSLog
import Lottie

// MARK: - Where the user ends up

enum DebriefOutcome {
    case completed      // finished the debrief, tapped Continue
    case finishLater    // stepped away, saved to resume
    case leave          // left, streak kept
}

// MARK: - Style

/// The debrief's colours, all taken from the shared Moko theme.
enum DebriefStyle {
    static var screenBg: Color { MokoScreenTheme.Colors.canvasTop }
    // Match the active theme's accent instead of a fixed purple.
    static var accent: Color { MokoScreenTheme.Colors.ctaAccent }
    static var title: Color { MokoScreenTheme.Colors.textTitle }
    static var subtext: Color { MokoScreenTheme.Colors.textBody }
    static var soft: Color { MokoScreenTheme.Colors.surfaceLavender }
    static var border: Color { MokoScreenTheme.Colors.dataGrid }
    static var danger: Color { MokoScreenTheme.Colors.error }
}

// MARK: - The four parameters

enum DebriefParameter: String, CaseIterable, Identifiable {
    case courage = "Courage"
    case clarity = "Clarity"
    case presence = "Presence"
    case warmth = "Warmth"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .courage:  return "bolt.fill"
        case .clarity:  return "eye.fill"
        case .presence: return "leaf.fill"
        case .warmth:   return "heart.fill"
        }
    }

    /// One soft background for every parameter, so the scores read as a set.
    var tint: Color {
        DebriefStyle.soft.opacity(0.55)
    }

    /// One strong foreground for every parameter, matching the app's accent.
    var accent: Color {
        DebriefStyle.accent
    }
}

// MARK: - Coach (plug the real model in here)

/// What the coach knows about the quest being debriefed.
struct DebriefContext {
    var questTitle: String
    var category: QuestCategory
    var intensity: QuestIntensity
    /// Any user-supplied notes, descriptions or situational details.
    var questNotes: String = ""
    /// User's first name, used to personalise the opening greeting. Empty string = no name available.
    var userName: String = ""
}

/// A follow-up question and the parameter it is about.
struct DebriefQuestion {
    var text: String
    var focus: DebriefParameter
}

/// How much usable evidence one answer contains for a parameter.
enum DebriefEvidenceLevel: String, Codable {
    case missing
    case partial
    case clear

    var weight: Double {
        switch self {
        case .missing: return 0
        case .partial: return 0.6
        case .clear: return 1
        }
    }
}

/// AFM labels unusual inputs separately from its accept/retry decision.
enum DebriefInputCategory: String, Codable {
    case substantive
    case weak
    case noEvidence
    case gibberish
    case offTopic
    case joke
    case oneWord
    case otherLanguage
    case emojiOnly
    case pastedText
    case transcriptionUnclear
}

/// AFM's coverage estimate is saved for calibration and never skips a follow-up.
enum DebriefCoverage: String, Codable {
    case needsMore
    case sufficient
}

/// The coach's verdict on one accepted answer.
struct DebriefGrade: Equatable {
    /// How closely the answer relates to the question and mission, not a social-skill score.
    var confidence: Int
    /// The selected target's score; Courage, Clarity and Confidence remain separate measures.
    var score: Int
    var note: String
    var focus: DebriefParameter?
    var parameterScores: [DebriefParameter: Int] = [:]
    var parameterEvidence: [DebriefParameter: DebriefEvidenceLevel] = [:]
    var category: DebriefInputCategory = .substantive
    var coverage: DebriefCoverage = .needsMore
}

/// An unclear answer stays on the same question and never produces a grade.
enum DebriefAssessment {
    case accepted(DebriefGrade)
    case retry(message: String, category: DebriefInputCategory)
}

/// The production coach always uses AFM. Errors reach the screen instead of triggering dummy content.
protocol DebriefCoaching {
    func greeting(for context: DebriefContext) async throws -> String
    func question(number: Int, context: DebriefContext, previousAnswers: [String],
                  previousQuestions: [String], grades: [DebriefGrade]) async throws -> DebriefQuestion
    func assess(answer: String, question: String, focus: DebriefParameter?, context: DebriefContext,
                previousAnswers: [String]) async throws -> DebriefAssessment
    func closing(for context: DebriefContext, answers: [String], grades: [DebriefGrade]) async throws -> String
    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int]
}

extension DebriefCoaching {
    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int] {
        DebriefScoring.finalScores(from: grades)
    }
}

// MARK: - Guided debrief fallback coach

/// A reliable fallback coach when Apple Intelligence is unavailable or times out on device.
/// Uses MissionBank templates, adaptive parameter selection, and content-based scoring.
@MainActor
final class GuidedDebriefCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async throws -> String {
        let namePrefix = context.userName.isEmpty ? "Hey there!" : "Hey \(context.userName)!"
        return "\(namePrefix) Glad you took on '\(context.questTitle)'. When the moment arrived, how did things play out for you?"
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String],
                  previousQuestions: [String], grades: [DebriefGrade]) async throws -> DebriefQuestion {
        let focus = DebriefScoring.nextFocus(from: grades)
        let templates = MissionBank.templates(in: context.category)
        let template = templates.first ?? MissionBank.all[0]

        let followUpText: String
        if let bankQ = template.followUps[focus.stat], !previousQuestions.contains(bankQ) {
            followUpText = bankQ
        } else {
            switch focus {
            case .courage:
                followUpText = "What felt like the boldest step or decision you made during this moment?"
            case .clarity:
                followUpText = "How did you express your thoughts or intentions directly to them?"
            case .presence:
                followUpText = "What did you observe in the room or about their reactions as you spoke?"
            case .warmth:
                followUpText = "What words or subtle cues did you share to keep things friendly and warm?"
            }
        }
        return DebriefQuestion(text: followUpText, focus: focus)
    }

    func assess(answer: String, question: String, focus: DebriefParameter?, context: DebriefContext,
                previousAnswers: [String]) async throws -> DebriefAssessment {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // Detect gibberish or unusable inputs
        let isKeyboardMash = lower.count >= 4 && Set(lower).count <= 3
        if trimmed.count < 3 || isKeyboardMash || lower == "asdf" || lower == "vrvrreff" {
            return .retry(
                message: "I couldn't quite catch that. What specifically happened or what did you say?",
                category: .gibberish
            )
        }

        let words = trimmed.split(separator: " ")
        let wordCount = words.count

        let hasActionVerb = ["said", "told", "asked", "went", "did", "decided", "started", "spoke", "called", "meet", "joined", "replied"].contains { lower.contains($0) }
        let hasObservation = ["looked", "noticed", "saw", "smiled", "nodded", "listened", "reaction", "pause", "paused", "tone"].contains { lower.contains($0) }
        let hasWarmthWords = ["thank", "glad", "happy", "shared", "appreciated", "friend", "kind", "warm", "welcome"].contains { lower.contains($0) }
        let hasDirectness = ["clear", "direct", "exactly", "honestly", "straight", "told them", "told her", "told him"].contains { lower.contains($0) }
        let hasAuthenticDetail = ["my name", "yeah", "yes", "no", "first time", "busy", "meeting", "tonight", "dinner"].contains { lower.contains($0) }

        // Content-based confidence: balanced, not inflated or size-dependent
        let confidence: Int
        if wordCount < 3 {
            confidence = 52
        } else if hasAuthenticDetail || hasActionVerb {
            confidence = min(92, 78 + min(12, wordCount * 2))
        } else {
            confidence = 72
        }

        var parameterScores: [DebriefParameter: Int] = [:]
        var parameterEvidence: [DebriefParameter: DebriefEvidenceLevel] = [:]

        // Courage
        if hasActionVerb || lower.contains("ditch") || lower.contains("decided") {
            let courageVal = lower.contains("ditch") ? 35 : (hasDirectness ? 88 : 78)
            parameterScores[.courage] = courageVal
            parameterEvidence[.courage] = .clear
        } else if wordCount > 4 {
            parameterScores[.courage] = 70
            parameterEvidence[.courage] = .partial
        }

        // Clarity
        if hasDirectness || (wordCount >= 4 && wordCount <= 30) {
            parameterScores[.clarity] = hasDirectness ? 86 : 76
            parameterEvidence[.clarity] = .clear
        } else {
            parameterScores[.clarity] = 68
            parameterEvidence[.clarity] = .partial
        }

        // Presence
        if hasObservation {
            parameterScores[.presence] = 85
            parameterEvidence[.presence] = .clear
        }

        // Warmth
        if hasWarmthWords {
            parameterScores[.warmth] = 88
            parameterEvidence[.warmth] = .clear
        }

        let targetScore = focus.flatMap { parameterScores[$0] } ?? parameterScores[.courage] ?? parameterScores[.clarity] ?? 75
        let note: String
        switch focus {
        case .courage:
            note = "You stepped up and shared what you actually did."
        case .clarity:
            note = "You stated your thoughts directly and clearly."
        case .presence:
            note = "You tuned into what was happening around you."
        case .warmth:
            note = "You brought genuine warmth to the conversation."
        case nil:
            note = "Clear and relevant account of your interaction."
        }

        let grade = DebriefGrade(
            confidence: confidence,
            score: targetScore,
            note: note,
            focus: focus,
            parameterScores: parameterScores,
            parameterEvidence: parameterEvidence,
            category: .substantive,
            coverage: wordCount > 8 ? .sufficient : .needsMore
        )
        return .accepted(grade)
    }

    func closing(for context: DebriefContext, answers: [String], grades: [DebriefGrade]) async throws -> String {
        "You reflected with real honesty and intention. Take this self-awareness with you into your next day!"
    }
}

// MARK: - Conversation data

/// One row in the chat: a coach bubble, a user bubble, or a follow-up header.
struct DebriefMessage: Identifiable {
    enum Kind {
        case ai(String)
        case user(text: String, grade: DebriefGrade?, isBeingGraded: Bool)
        case divider(question: Int)
    }

    let id = UUID()
    var kind: Kind
}

/// What the "Debrief Complete" panel shows.
struct DebriefResult {
    var scores: [DebriefParameter: Int]
    var xp: Int
    var streak: Int
}

// MARK: - Session (drives the whole conversation)

/// The "brain" of the debrief. The screen only reads these values and calls
/// `start()`, `submit(_:)` and the recording functions.
/// `@Observable` makes every view that reads a property redraw when it changes.
@MainActor
@Observable
final class DebriefSession {
    // Exactly three accepted follow-ups give every stat a chance to supply real evidence.
    static let maxFollowUpCount = 3

    var context: DebriefContext
    private var coach: any DebriefCoaching

    // The chat rows, oldest first.
    var messages: [DebriefMessage] = []
    // Shows the three bouncing dots while the coach writes a question.
    var isCoachTyping = false
    // True while the newest answer is being scored. Answers are blocked until it's done.
    var isGrading = false
    // True while the (simulated) microphone is "listening".
    var isRecording = false
    // True once all answers are in. Shows the "Debrief Complete" panel.
    var isComplete = false
    /// True while the "Leave early?" sheet is open. Pauses the recording.
    var isPaused = false

    // Recording display: seconds, the words heard so far, waveform bars and orb size (0...1).
    var elapsed = 0
    var transcript = ""
    var levels: [Double] = Array(repeating: 0.08, count: 34)
    var orbLevel: Double = 0

    /// What the current question is about (nil for the opening story).
    var focus: DebriefParameter?
    /// The exact AFM-written question the current answer must address.
    private(set) var currentQuestion = ""
    /// 0 = the opening story; 1...3 = the required adaptive follow-ups.
    var questionNumber = 0
    var result: DebriefResult?
    // The real AFM error is shown in an alert instead of being hidden by dummy coaching.
    private(set) var coachingError: String?
    private var failedStep: FailedStep?
    /// XP and streak to show when the debrief finishes.
    var reward = QuestReward(xp: 0, streak: 0)

    /// The quest this debrief belongs to. When set, every change is also written to
    /// `DebriefDraftStore` so an interrupted debrief can be picked up later.
    var questID: UUID?

    // Everything said and scored so far (also saved in the draft).
    private var answers: [String] = []
    private var grades: [DebriefGrade] = []
    // Guards so `start()` runs once, and knows whether we're resuming a saved draft.
    private var started = false
    private var isRestored = false
    private var resumeStep: ResumeStep = .none

    /// What a restored debrief does before it accepts an answer again.
    private enum ResumeStep: Equatable {
        case none
        case ask(number: Int, divider: Bool)
        case closing
    }

    /// The exact AFM job to repeat after an availability or generation error.
    private enum FailedStep {
        case opening
        case assessment(text: String, question: String, focus: DebriefParameter?, messageID: UUID?)
        case question(number: Int)
        case closing
    }

    // Running background jobs. Kept so `cancelAll()` can stop them when the screen closes.
    private var recordingTask: Task<Void, Never>?
    private var flowTask: Task<Void, Never>?
    // Live audio recorder and speech transcriber (AVFoundation + Speech framework).
    private let transcriber = AudioTranscriber()

    init(context: DebriefContext, coach: any DebriefCoaching) {
        self.context = context
        self.coach = coach
    }

    /// True when the user may send an answer right now.
    var canAnswer: Bool {
        !messages.isEmpty && !currentQuestion.isEmpty && !isCoachTyping && !isGrading && !isComplete && failedStep == nil
    }

    /// Recording time as "m:ss".
    var timeText: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    // MARK: Start

    /// Shows the AFM opening, or resumes the exact unfinished step.
    func start() async {
        guard !started else { return }
        started = true

        if isRestored {
            switch resumeStep {
            case .none:
                break
            case .ask(let number, let divider):
                resumeStep = .none
                if divider {
                    questionNumber = number
                    append(.divider(question: number))
                }
                await askQuestion(number: number)
            case .closing:
                resumeStep = .none
                await closeDebrief()
            }
            return
        }

        await performOpening()
    }

    /// Generates the opening with AFM. No canned greeting is used on failure.
    private func performOpening() async {
        isCoachTyping = true
        failedStep = nil
        coachingError = nil
        do {
            let text = try await coach.greeting(for: context)
            guard !Task.isCancelled else { return }
            currentQuestion = text
            isCoachTyping = false
            append(.ai(text))
        } catch {
            handle(error, failed: .opening)
        }
    }

    /// Repeats only the AFM job that failed, without duplicating a chat row.
    func retry() async {
        guard let step = failedStep else { return }
        failedStep = nil
        coachingError = nil

        switch step {
        case .opening:
            await performOpening()
        case .assessment(let text, let question, let focus, let messageID):
            await assess(text, question: question, focus: focus, messageID: messageID)
        case .question(let number):
            await askQuestion(number: number)
        case .closing:
            await closeDebrief()
        }
    }

    /// Dismisses the coaching error without retrying.
    func dismissError() {
        coachingError = nil
    }

    /// Seamlessly switches to the guided fallback coach and retries the failed step.
    func continueWithGuidedCoach() async {
        self.coach = GuidedDebriefCoach()
        coachingError = nil
        await retry()
    }

    // MARK: Voice (AVFoundation + Speech)

    /// Starts live microphone recording and real-time speech transcription.
    func startRecording() async {
        guard canAnswer, !isRecording else { return }

        isRecording = true
        elapsed = 0
        transcript = ""
        // Reset waveform bars to a quiet resting state.
        levels = Array(repeating: 0.08, count: levels.count)

        // Wire up callbacks so the transcriber feeds our published properties.
        transcriber.onTranscriptUpdate = { [weak self] liveText in
            guard let self else { return }
            // Update the live transcript shown in the recording card.
            self.transcript = liveText
        }

        transcriber.onAudioLevelUpdate = { [weak self] liveLevel in
            guard let self else { return }
            // Push each RMS sample into the scrolling waveform.
            self.pushLiveLevel(liveLevel)
        }

        transcriber.onTimerTick = { [weak self] seconds in
            guard let self else { return }
            // Keep the elapsed-time counter in sync with real clock ticks.
            self.elapsed = seconds
        }

        do {
            // Start the AVAudioEngine tap and SFSpeechRecognizer task.
            try await transcriber.start()
        } catch {
            Logger.audio.error("AudioTranscriber start failed: \(error.localizedDescription, privacy: .public)")
            stopRecordingState()
        }
    }

    /// Stops recording, grabs the transcript, and submits it into chat for confidence grading.
    func finishRecording() {
        guard isRecording else { return }
        let currentText = transcript
        stopRecordingState()

        Task { [weak self] in
            guard let self else { return }
            var text = await self.transcriber.stop()
            if text.isEmpty {
                text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if !text.isEmpty {
                self.submit(text)
            }
        }
    }

    /// Stops recording and throws everything away (user tapped the discard button).
    func cancelRecording() {
        transcriber.cancel()
        stopRecordingState()
    }

    /// Resets all recording-related state without touching the transcriber.
    private func stopRecordingState() {
        recordingTask?.cancel()
        recordingTask = nil
        isRecording = false
        orbLevel = 0
        elapsed = 0
        transcript = ""
        // Return bars to the flat resting position.
        levels = Array(repeating: 0.08, count: levels.count)
    }

    /// Smooths the new RMS loudness value into the scrolling waveform bars.
    private func pushLiveLevel(_ level: Double) {
        // Blend 60% new + 40% old so bars move smoothly instead of jumping.
        orbLevel = orbLevel * 0.4 + level * 0.6
        levels.removeFirst()
        levels.append(orbLevel)
    }

    // MARK: Answering

    /// Adds an answer for AFM assessment. Only accepted answers enter scoring and coverage history.
    func submit(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, canAnswer else { return }

        let question = currentQuestion
        let answeredFocus = focus
        append(.user(text: text, grade: nil, isBeingGraded: true))
        let messageID = messages.last?.id

        flowTask = Task { [weak self] in
            await self?.assess(text, question: question, focus: answeredFocus, messageID: messageID)
        }
    }

    /// Scores a useful answer or shows AFM's fresh clarification and waits on the same question.
    private func assess(_ text: String, question: String, focus: DebriefParameter?, messageID: UUID?) async {
        isGrading = true
        isCoachTyping = true
        failedStep = nil
        coachingError = nil
        markUser(messageID, isBeingGraded: true)

        do {
            let assessment = try await coach.assess(
                answer: text,
                question: question,
                focus: focus,
                context: context,
                previousAnswers: answers
            )
            guard !Task.isCancelled else { return }

            switch assessment {
            case .retry(let message, _):
                // Rejected text is deliberately absent from answers, grades and future AFM context.
                isGrading = false
                isCoachTyping = false
                markUser(messageID, isBeingGraded: false)
                append(.ai(message))

            case .accepted(let grade):
                answers.append(text)
                apply(grade, to: messageID)
                isGrading = false
                isCoachTyping = false

                if questionNumber >= Self.maxFollowUpCount {
                    await closeDebrief()
                } else {
                    questionNumber += 1
                    append(.divider(question: questionNumber))
                    await askQuestion(number: questionNumber)
                }
            }
        } catch {
            markUser(messageID, isBeingGraded: false)
            handle(error, failed: .assessment(text: text, question: question, focus: focus, messageID: messageID))
        }
    }

    /// Asks AFM for a follow-up grounded in accepted answers and current evidence gaps.
    private func askQuestion(number: Int) async {
        isCoachTyping = true
        failedStep = nil
        coachingError = nil
        let previousQuestions = messages.compactMap { message -> String? in
            if case .ai(let text) = message.kind { return text }
            return nil
        }

        do {
            let next = try await coach.question(
                number: number,
                context: context,
                previousAnswers: answers,
                previousQuestions: previousQuestions,
                grades: grades
            )
            guard !Task.isCancelled else { return }
            isCoachTyping = false
            focus = next.focus
            currentQuestion = next.text
            append(.ai(next.text))
        } catch {
            handle(error, failed: .question(number: number))
        }
    }

    /// Generates AFM's closing before revealing the evidence-weighted scores.
    private func closeDebrief() async {
        isCoachTyping = true
        failedStep = nil
        coachingError = nil
        do {
            let closingMessage = try await coach.closing(for: context, answers: answers, grades: grades)
            guard !Task.isCancelled else { return }
            isCoachTyping = false
            append(.ai(closingMessage))
            finish()
        } catch {
            handle(error, failed: .closing)
        }
    }

    /// Saves a grade and stops the matching bubble's grading spinner.
    private func apply(_ grade: DebriefGrade, to id: UUID?) {
        grades.append(grade)
        guard let id, let index = messages.firstIndex(where: { $0.id == id }) else {
            persist()
            return
        }
        if case .user(let text, _, _) = messages[index].kind {
            withAnimation(.easeOut(duration: 0.4)) {
                messages[index].kind = .user(text: text, grade: grade, isBeingGraded: false)
            }
        }
        persist()
    }

    /// Pending and rejected answers look different: rejected answers have no endless spinner.
    private func markUser(_ id: UUID?, isBeingGraded: Bool) {
        guard let id, let index = messages.firstIndex(where: { $0.id == id }),
              case .user(let text, let grade, _) = messages[index].kind else { return }
        messages[index].kind = .user(text: text, grade: grade, isBeingGraded: isBeingGraded)
    }

    /// Surfaces the real AFM problem and remembers exactly how to retry it.
    private func handle(_ error: Error, failed step: FailedStep) {
        if error is CancellationError { return }
        isGrading = false
        isCoachTyping = false
        failedStep = step
        coachingError = error.localizedDescription
        Logger.afm.error("Debrief AFM step failed: \(error.localizedDescription, privacy: .public)")
    }

    /// Works out the final scores and shows the "Debrief Complete" panel.
    private func finish() {
        let scores = coach.finalScores(from: grades, context: context)

        result = DebriefResult(scores: scores, xp: reward.xp, streak: reward.streak)
        focus = nil

        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            isComplete = true
        }
        persist()
    }

    /// Stops every background job. Called when the screen goes away.
    func cancelAll() {
        // Stop the live microphone + transcription engine first.
        transcriber.cancel()
        stopRecordingState()
        recordingTask?.cancel()
        flowTask?.cancel()
    }

    /// Adds a chat row with a little spring, and saves the draft.
    private func append(_ kind: DebriefMessage.Kind) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            messages.append(DebriefMessage(kind: kind))
        }
        persist()
    }

    // MARK: Leaving and coming back

    /// Writes the conversation out immediately — used when the user taps "Finish Later".
    func persistNow() {
        persist()
    }

    /// Rebuilds the conversation from a saved draft so the debrief continues mid-way
    /// instead of starting again at the greeting.
    func restore(from draft: DebriefDraft) {
        messages = draft.messages.map { stored in
            switch stored.role {
            case .coach:
                return DebriefMessage(kind: .ai(stored.text))
            case .user:
                return DebriefMessage(kind: .user(text: stored.text, grade: stored.grade?.restored, isBeingGraded: false))
            case .divider:
                return DebriefMessage(kind: .divider(question: stored.question))
            }
        }
        answers = draft.answers
        grades = draft.grades.map { $0.restored }
        questionNumber = draft.questionNumber
        focus = draft.focus.flatMap(DebriefParameter.init(rawValue:))
        currentQuestion = draft.currentQuestion ?? messages.compactMap({ message -> String? in
            if case .ai(let text) = message.kind { return text }
            return nil
        }).last ?? ""

        isRestored = true

        // Drafts from the old fixed-flow version used four answers as their completion marker.
        let completedLegacyDraft = draft.isComplete == nil && answers.count > 3
        if draft.isComplete == true || completedLegacyDraft {
            finish()
        } else if let last = messages.last {
            switch last.kind {
            case .divider:
                resumeStep = .ask(number: questionNumber, divider: false)
            case .user(_, let grade, _):
                guard grade != nil else {
                    // An interrupted or rejected answer can be replaced on the same question.
                    resumeStep = .none
                    return
                }
                if questionNumber >= Self.maxFollowUpCount {
                    resumeStep = .closing
                } else {
                    resumeStep = .ask(number: questionNumber + 1, divider: true)
                }
            case .ai:
                resumeStep = .none
            }
        }
    }

    /// Saves the current conversation for this quest (only when `questID` is set).
    private func persist() {
        guard let questID else { return }
        DebriefDraftStore.save(snapshot(), for: questID)
    }

    /// Turns the live conversation into plain, saveable values.
    private func snapshot() -> DebriefDraft {
        DebriefDraft(
            messages: messages.map { message in
                switch message.kind {
                case .ai(let text):
                    return DebriefDraft.Message(role: .coach, text: text)
                case .user(let text, let grade, _):
                    return DebriefDraft.Message(
                        role: .user,
                        text: text,
                        grade: grade.map { DebriefDraft.Grade($0) }
                    )
                case .divider(let question):
                    return DebriefDraft.Message(role: .divider, question: question)
                }
            },
            answers: answers,
            grades: grades.map { DebriefDraft.Grade($0) },
            questionNumber: questionNumber,
            focus: focus?.rawValue,
            currentQuestion: currentQuestion,
            isComplete: isComplete
        )
    }
}

// MARK: - The screen

struct QuestDebriefScreen: View {
    var onExit: (DebriefOutcome) -> Void

    // SwiftData's "save box". Used to store the scores, XP and streak.
    @Environment(\.modelContext) private var modelContext
    // The user's profile (name, streak). @Query keeps it up to date.
    @Query private var profiles: [Profile]

    // nil in the preview; set when debriefing a real quest.
    private let quest: Quest?
    // The conversation. @State keeps the same session alive while the screen is open.
    @State private var session: DebriefSession
    // Text typed in the answer box but not sent yet.
    @State private var draft = ""
    // Opens the "Leave debrief early?" sheet.
    @State private var showLeave = false
    // Shows an alert if microphone permission was denied.
    @State private var showMicSettingsAlert = false
    // True while the keyboard is up for the answer box.
    @FocusState private var isTyping: Bool

    /// The production debrief has one coach: AFM. Failures are retried explicitly.
    private static func defaultCoach() -> any DebriefCoaching {
        AFMDebriefCoach()
    }

    /// For previews: a debrief without a saved quest.
    init(context: DebriefContext,
         coach: (any DebriefCoaching)? = nil,
         onExit: @escaping (DebriefOutcome) -> Void) {
        self.quest = nil
        _session = State(initialValue: DebriefSession(context: context, coach: coach ?? Self.defaultCoach()))
        self.onExit = onExit
    }

    /// For a real quest. Resumes a saved draft if there is one.
    init(quest: Quest,
         coach: (any DebriefCoaching)? = nil,
         onExit: @escaping (DebriefOutcome) -> Void) {
        self.quest = quest

        let session = DebriefSession(
            context: DebriefContext(
                questTitle: quest.title,
                category: quest.category,
                intensity: quest.intensity,
                questNotes: quest.notes
                // userName is filled in by `.task` once profiles load
            ),
            coach: coach ?? Self.defaultCoach()
        )
        // Pick up an unfinished debrief where the user left it.
        session.questID = quest.id
        if let draft = DebriefDraftStore.load(for: quest.id) {
            session.restore(from: draft)
        }

        _session = State(initialValue: session)
        self.onExit = onExit
    }

    /// Warning shown in the leave sheet when something would be lost.
    private var unsentText: String? {
        if session.isRecording { return "Unsent audio (\(session.timeText)) will be discarded" }
        if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Your unsent answer will be discarded" }
        return nil
    }

    var body: some View {
        ZStack {
            MokoBackdrop()

            VStack(spacing: 0) {
                // Single-line top header with back button and centered quest title
                headerBar

                // ScrollViewReader lets us scroll to the invisible "bottom" marker from code.
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            conversation
                            Color.clear.frame(height: 1).id("bottom")
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    // Keep the newest message in view whenever the chat changes.
                    .onChange(of: session.messages.count) { _, _ in scrollToBottom(proxy) }
                    .onChange(of: session.isCoachTyping) { _, _ in scrollToBottom(proxy) }
                    .onChange(of: session.isRecording) { _, _ in scrollToBottom(proxy) }
                    .onChange(of: session.isComplete) { _, _ in scrollToBottom(proxy) }
                    .onChange(of: isTyping) { _, _ in scrollToBottom(proxy) }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomArea
        }
        .sheet(isPresented: $showLeave) {
            DebriefLeaveSheet(
                unsentText: unsentText,
                onKeepGoing: { showLeave = false },
                onFinishLater: { exit(.finishLater) },
                onLeave: { exit(.leave) }
            )
        }
        // `.task` runs when the screen appears and is cancelled when it goes away.
        .task {
            // Give the coach the user's first name so it can greet them personally.
            if let name = profiles.first?.username, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let firstName = name.split(separator: " ").first.map(String.init) ?? name
                session.context.userName = firstName
            }
            AFM.prewarm(instructions: DebriefPrompts.openingInstructions)
            syncReward()
            await session.start()

            // A debrief that was already finished when it was saved still needs its scores stored.
            if session.isComplete {
                recordDebrief()
            }
        }
        // Save the scores as soon as the last answer is graded.
        .onChange(of: session.isComplete) { _, isComplete in
            if isComplete {
                recordDebrief()
            }
        }
        // Pause the recording while the leave sheet is open.
        .onChange(of: showLeave) { _, isShown in
            session.isPaused = isShown
        }
        .onDisappear {
            session.cancelAll()
        }
        // Haptics: a tap for each new message, a thump when recording starts/stops, success at the end.
        .sensoryFeedback(.impact(weight: .light), trigger: session.messages.count)
        .sensoryFeedback(.impact(weight: .medium), trigger: session.isRecording)
        .sensoryFeedback(.success, trigger: session.isComplete)
        // AFM errors stay visible and retry the exact failed step instead of using dummy coaching.
        .alert("Coach Unavailable", isPresented: Binding(
            get: { session.coachingError != nil },
            set: { isPresented in
                if !isPresented {
                    session.dismissError()
                }
            }
        )) {
            Button("Try Again") {
                Task { await session.retry() }
            }
            Button("Continue with Guided Coach") {
                Task { await session.continueWithGuidedCoach() }
            }
            Button("Cancel", role: .cancel) {
                session.dismissError()
            }
        } message: {
            Text(session.coachingError ?? AFM.availabilityDescription)
        }
        .alert("Microphone & Speech Access Needed", isPresented: $showMicSettingsAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To answer by voice, please allow both Microphone and Speech Recognition access in Settings. You can also type your reflections.")
        }
    }

    // MARK: Header

    /// Single-line top header bar displaying the quest title.
    private var headerBar: some View {
        HStack {
            Spacer(minLength: 16)

            Text(session.context.questTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.35)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    /// Keeps the completion panel's XP and streak in sync with saved progress.
    /// Streak comes from StreakService (ActivityRecord rows) — the single source
    /// of truth — so the preview matches what every other screen shows.
    private func syncReward() {
        guard let quest else { return }

        let existing = (try? modelContext.fetch(FetchDescriptor<ActivityRecord>())) ?? []
        let stats = StreakService.shared.stats(from: existing, at: quest.date)
        session.reward = QuestReward(
            xp: quest.awardedXP,
            streak: stats.currentStreak
        )
    }

    /// Persists the debrief scores and any XP/streak that have not been awarded yet.
    private func recordDebrief() {
        guard let quest, let result = session.result else { return }

        let reward = QuestProgress.saveDebrief(result, for: quest, in: modelContext)
        session.reward = reward
        // The debrief is behind us: the saved draft has done its job.
        DebriefDraftStore.clear(for: quest.id)

        if var updated = session.result {
            updated.xp = reward.xp
            updated.streak = reward.streak
            session.result = updated
        }

        // Insights are refreshed only from measured values, never invented 55-point baselines.
        if let courage = result.scores[.courage], let clarity = result.scores[.clarity],
           let presence = result.scores[.presence], let warmth = result.scores[.warmth] {
            let scores = InsightsScores(
                clarity: Double(clarity),
                courage: Double(courage),
                presence: Double(presence),
                warmth: Double(warmth)
            )
            Task { @MainActor in
                await DynamicParameterAnalysisStore.shared.refreshAnalysisIfNeeded(scores: scores, recentObservations: [quest.title])
            }
        }
    }

    /// Leaves the debrief, keeping the conversation for "Finish Later" and dropping it when
    /// the debrief is completed or its progress is given up.
    private func exit(_ outcome: DebriefOutcome) {
        if let quest {
            switch outcome {
            case .finishLater:
                session.persistNow()
            case .completed, .leave:
                DebriefDraftStore.clear(for: quest.id)
            }
        }
        onExit(outcome)
    }

    // MARK: Conversation

    private var conversation: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(session.messages) { message in
                messageView(message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Show loading while coach is thinking
            if session.isCoachTyping {
                HStack(spacing: 10) {
                    MokoInlineLoader(size: 28)
                    Text("Your coach is thinking...")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                }
                .transition(.opacity)
            }
            
            // Show one white completion card when the debrief is complete.
            if session.isComplete, let result = session.result {
                ScoreReveal(
                    scores: Dictionary(uniqueKeysWithValues: result.scores.compactMap { parameter, score -> (StatParameter, Int)? in
                        guard let stat = StatParameter(rawValue: parameter.rawValue.lowercased()) else { return nil }
                        return (stat, score)
                    }),
                    // The old green panel used a fixed +8; keep the same comparison line.
                    comparison: 8,
                    xp: result.xp,
                    streak: result.streak,
                    onContinue: { exit(.completed) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }


            if session.isRecording {
                DebriefRecordingCard(
                    levels: session.levels,
                    elapsed: session.timeText,
                    transcript: session.transcript,
                    onStop: { session.finishRecording() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, MokoScreenTheme.Space.page)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isCoachTyping)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isRecording)
    }

    /// Picks the right bubble for one chat row.
    @ViewBuilder
    private func messageView(_ message: DebriefMessage) -> some View {
        switch message.kind {
        case .ai(let text):
            DebriefCoachBubble(text: text)
        case .user(let text, let grade, let isBeingGraded):
            DebriefUserBubble(text: text, grade: grade, isBeingGraded: isBeingGraded)
        case .divider(let number):
            DebriefQuestionHeader(number: number)
        }
    }

    // MARK: Bottom area

    /// The answer box (plus the orb while recording). Hidden once the white results card shows.
    @ViewBuilder
    private var bottomArea: some View {
        if !session.isComplete {
            VStack(spacing: 10) {
                if session.isRecording {
                    DebriefOrb(level: session.orbLevel)
                        .frame(height: 128)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

                composer
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [DebriefStyle.screenBg.opacity(0), DebriefStyle.screenBg],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: session.isRecording)
        }
    }

    private var placeholder: String {
        if session.isRecording { return "Listening…" }
        return session.canAnswer ? "Speak, or type instead" : "Your coach is thinking…"
    }

    /// Text field + mic/send button + close button.
    private var composer: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $draft, axis: .vertical)
                .mokoText(MokoScreenTheme.Typeface.body)
                .lineLimit(1...4)
                .focused($isTyping)
                .disabled(!session.canAnswer || session.isRecording)
                .padding(.leading, 6)

            inputButton

            Button {
                isTyping = false
                showLeave = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.accent))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .accessibilityLabel("Leave debrief")
        }
        .padding(.leading, 16)
        .padding(.trailing, 7)
        .padding(.vertical, 7)
        .frame(minHeight: 58)
        .mokoCard()
    }

    /// Send (when there's text), discard (while recording) or start the mic.
    @ViewBuilder
    private var inputButton: some View {
        let hasText = !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasText {
            Button {
                let text = draft
                draft = ""
                isTyping = false
                session.submit(text)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.accent))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .accessibilityLabel("Send answer")
            .transition(.scale.combined(with: .opacity))
        } else if session.isRecording {
            Button {
                session.cancelRecording()
            } label: {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DebriefStyle.danger)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.danger.opacity(0.12)))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .accessibilityLabel("Discard recording")
        } else {
            Button {
                handleMicTap()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DebriefStyle.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.soft.opacity(0.7)))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .disabled(!session.canAnswer)
            .opacity(session.canAnswer ? 1 : 0.4)
            .accessibilityLabel("Answer by voice")
        }
    }

    /// Handles mic button tap: requests microphone and speech recognition permissions on
    /// first use, or alerts the user to go to Settings if either was denied.
    private func handleMicTap() {
        isTyping = false
        Task {
            // --- Step 1: microphone permission ---
            let micPermission = AVAudioSession.sharedInstance().recordPermission
            let micGranted: Bool
            switch micPermission {
            case .granted:
                micGranted = true
            case .undetermined:
                // First time: show the iOS system microphone dialog.
                micGranted = await AVAudioApplication.requestRecordPermission()
            case .denied:
                micGranted = false
            @unknown default:
                micGranted = await AVAudioApplication.requestRecordPermission()
            }

            guard micGranted else {
                showMicSettingsAlert = true
                return
            }

            // --- Step 2: speech recognition permission ---
            let speechStatus = SFSpeechRecognizer.authorizationStatus()
            let speechGranted: Bool
            switch speechStatus {
            case .authorized:
                speechGranted = true
            case .notDetermined:
                // First time: show the iOS speech recognition dialog.
                speechGranted = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { status in
                        continuation.resume(returning: status == .authorized)
                    }
                }
            case .denied, .restricted:
                speechGranted = false
            @unknown default:
                speechGranted = false
            }

            guard speechGranted else {
                showMicSettingsAlert = true
                return
            }

            // Both permissions granted — start live recording + transcription.
            await session.startRecording()
        }
    }
}

// MARK: - Shared button feel

/// Shrinks a button slightly while it is pressed.
struct DebriefPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Bubbles

/// The coach's message. The letters type in one by one (all at once with Reduce Motion).
struct DebriefCoachBubble: View {
    let text: String

    // The phone setting "Reduce Motion". If it is on, the text appears instantly.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // How many letters are visible so far.
    @State private var shownCount = 0
    // True after the first text has been typed, so a replacement greeting appears instantly.
    @State private var hasTyped = false

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text(text).opacity(0) // reserves the final size so the bubble doesn't jump
                Text(String(text.prefix(shownCount)))
            }
            .mokoText(MokoScreenTheme.Typeface.body)
            .foregroundStyle(DebriefStyle.title)
            .lineSpacing(3)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .mokoCard()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)

            Spacer(minLength: 44)
        }
        // Restarts whenever `text` changes. Adds one letter every 14 ms.
        .task(id: text) {
            // The coach's personalised opening replaces the instant fallback.
            // Show the replacement in full instead of typing it out again.
            if hasTyped || reduceMotion {
                shownCount = text.count
                hasTyped = true
                return
            }
            hasTyped = true
            shownCount = 0
            while shownCount < text.count {
                try? await Task.sleep(for: .milliseconds(14))
                if Task.isCancelled { return }
                shownCount += 1
            }
        }
    }
}

/// The user's answer, with a confidence meter that fills in once it's graded.
struct DebriefUserBubble: View {
    let text: String
    let grade: DebriefGrade?
    let isBeingGraded: Bool

    // True when the user has tapped to see the coach's note.
    @State private var expanded = false
    // How full the confidence bar is, 0...1. Animated up when the grade arrives.
    @State private var meter: Double = 0
    // True until the grade arrives. Dims the bar.
    @State private var waiting = false

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text(text)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(DebriefStyle.title)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)

                Rectangle()
                    .fill(DebriefStyle.border)
                    .frame(height: 1)

                footer

                if expanded, let grade {
                    details(grade)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .mokoCard(fill: MokoScreenTheme.Colors.surfaceLavender)
        }
        // `initial: true` also runs this once when the bubble first appears.
        .onChange(of: grade, initial: true) { _, _ in syncMeter() }
        .onChange(of: isBeingGraded) { _, _ in syncMeter() }
    }

    /// Fills the bar to the grade's confidence, or marks it as waiting.
    private func syncMeter() {
        if let grade {
            waiting = false
            withAnimation(.easeOut(duration: 1.0)) {
                meter = Double(grade.confidence) / 100
            }
        } else {
            waiting = isBeingGraded
            meter = 0
        }
    }

    /// "Confidence" + bar + number. Tapping it shows or hides the details.
    private var footer: some View {
        Button {
            guard grade != nil else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Text("Confidence")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(DebriefStyle.subtext)

                meterBar

                if let grade {
                    Text("\(grade.confidence)")
                        .mokoText(MokoScreenTheme.Typeface.slider)
                        .foregroundStyle(DebriefStyle.accent)
                        .monospacedDigit()
                } else if isBeingGraded {
                    MokoInlineLoader(size: 18)
                } else {
                    Text("Not scored")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(DebriefStyle.subtext)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DebriefStyle.title)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
                    .opacity(grade == nil ? 0.3 : 1)
            }
            .padding(.horizontal, 18)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(grade.map { "Confidence \($0.confidence). Tap for details." } ?? (isBeingGraded ? "Grading" : "Not scored; clarification requested"))
    }

    private var meterBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DebriefStyle.soft.opacity(0.9))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [DebriefStyle.soft, DebriefStyle.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geo.size.width * meter))
                    .opacity(waiting ? 0.35 : 1)
            }
        }
        .frame(height: 6)
    }

    /// The coach's note and the parameter chip, shown when expanded.
    private func details(_ grade: DebriefGrade) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(grade.note)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(DebriefStyle.subtext)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let focus = grade.focus {
                    HStack(spacing: 6) {
                        Image(systemName: focus.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(focus.rawValue) \(grade.score)")
                            .mokoText(MokoScreenTheme.Typeface.caption)
                    }
                    .foregroundStyle(focus.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Capsule().fill(focus.tint))
                } else {
                    Text("Your story")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(DebriefStyle.accent)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(Capsule().fill(DebriefStyle.soft.opacity(0.7)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .padding(.top, 2)
    }
}

/// A follow-up number within the required three-question sequence.
struct DebriefQuestionHeader: View {
    let number: Int

    var body: some View {
        HStack {
            Text("Follow-up questions")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)

            Spacer()

            Text("Question \(number) of \(DebriefSession.maxFollowUpCount)")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(DebriefStyle.title)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Capsule().fill(DebriefStyle.soft))
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Recording

/// The card in the chat while recording: stop button, waveform, timer and live words.
struct DebriefRecordingCard: View {
    let levels: [Double]
    let elapsed: String
    let transcript: String
    var onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button(action: onStop) {
                    ZStack {
                        Circle().fill(DebriefStyle.danger.opacity(0.14))
                        Circle().fill(DebriefStyle.danger).frame(width: 26, height: 26)
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                }
                .buttonStyle(DebriefPressStyle())
                .accessibilityLabel("Stop and send")

                waveform

                Text(elapsed)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .monospacedDigit()
                    .foregroundStyle(DebriefStyle.subtext)
            }

            // Live transcript with a caret that blinks twice a second.
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let caretOn = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                let words = Text(transcript.isEmpty ? "Listening…" : transcript)
                    .foregroundStyle(transcript.isEmpty ? DebriefStyle.subtext : DebriefStyle.title)
                let caret = Text(" ▏").foregroundStyle(caretOn ? DebriefStyle.accent : Color.clear)

                // Putting one Text inside another keeps both colours in a single line of text.
                Text("\(words)\(caret)")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .mokoCard(fill: MokoScreenTheme.Colors.surfaceLavender)
    }

    /// Newest sound on the right, older sound fading out on the left.
    private var waveform: some View {
        HStack(spacing: 3) {
            ForEach(levels.indices, id: \.self) { index in
                let age = Double(index) / Double(max(levels.count - 1, 1))

                Capsule()
                    .fill(age > 0.6 ? DebriefStyle.accent : MokoScreenTheme.Colors.dataViolet)
                    .opacity(0.35 + 0.65 * age)
                    .frame(width: 3, height: 5 + CGFloat(levels[index]) * 26)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .animation(.easeOut(duration: 0.1), value: levels)
    }
}

/// The animation shown while listening: a glowing orb that swells with your voice,
/// ringed by slowly turning dots.
struct DebriefOrb: View {
    var level: Double

    // The phone setting "Reduce Motion". If it is on, the rings don't spin.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Flipped once on appear. `repeatForever` then keeps the rings turning on their own.
    @State private var spin = false

    var body: some View {
        ZStack {
            DebriefDottedRing(count: 30, radius: 60, color: DebriefStyle.accent)
                .rotationEffect(.degrees(spin ? 360 : 0))

            DebriefDottedRing(count: 18, radius: 47, color: MokoScreenTheme.Colors.dataViolet)
                .rotationEffect(.degrees(spin ? -360 : 0))

            // Glow that follows the voice
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DebriefStyle.accent.opacity(0.35), DebriefStyle.accent.opacity(0)],
                        center: .center,
                        startRadius: 8,
                        endRadius: 62
                    )
                )
                .frame(width: 124, height: 124)
                .scaleEffect(1 + 0.22 * level)
                .animation(.easeOut(duration: 0.12), value: level)

            Circle()
                .fill(DebriefStyle.soft.opacity(0.8))
                .frame(width: 78, height: 78)
                .scaleEffect(1 + 0.12 * level)
                .animation(.easeOut(duration: 0.12), value: level)

            // Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MokoScreenTheme.Colors.dataViolet, DebriefStyle.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2).padding(7))
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 10, height: 10)
                        .blur(radius: 1)
                        .offset(x: -11, y: -12)
                )
                .shadow(color: DebriefStyle.accent.opacity(0.35), radius: 12, x: 0, y: 6)
                .scaleEffect(1 + 0.08 * level)
                .animation(.easeOut(duration: 0.12), value: level)
        }
        .frame(width: 132, height: 132)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
        .accessibilityHidden(true)
    }
}

/// `count` dots spaced evenly round a circle of `radius`. Every 3rd dot is bigger.
struct DebriefDottedRing: View {
    let count: Int
    let radius: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let angle = Double(index) / Double(count) * 2 * Double.pi
                let size: CGFloat = index % 3 == 0 ? 5 : 3

                Circle()
                    .fill(color.opacity(0.3 + 0.7 * Double(index % 4) / 3))
                    .frame(width: size, height: size)
                    .offset(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius)
            }
        }
    }
}

// MARK: - Leave early?

/// The sheet behind the close button: Keep Going, Finish Later or Leave Progress.
struct DebriefLeaveSheet: View {
    var unsentText: String?
    var onKeepGoing: () -> Void
    var onFinishLater: () -> Void
    var onLeave: () -> Void

    // The measured height of the content. The sheet is sized to fit it exactly.
    @State private var contentHeight: CGFloat = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DebriefStyle.danger)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DebriefStyle.soft))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Leave debrief early?")
                        .mokoText(MokoScreenTheme.Typeface.section)
                        .foregroundStyle(DebriefStyle.title)

                    Text("Take a breath. No penalty for stepping away.")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(DebriefStyle.subtext)
                }
            }

            // Orange warning pill: something unsent would be lost.
            if let unsentText {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 232/255, green: 120/255, blue: 60/255))
                        .frame(width: 6, height: 6)

                    Text(unsentText)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(Color(red: 170/255, green: 90/255, blue: 40/255))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Capsule().fill(Color(red: 253/255, green: 241/255, blue: 228/255)))
                .overlay(Capsule().stroke(Color(red: 248/255, green: 222/255, blue: 196/255), lineWidth: 1))
            }

            VStack(spacing: 10) {
                DebriefLeaveOption(
                    symbol: "arrowshape.turn.up.right.fill",
                    title: "Keep Going",
                    subtitle: "Resume debrief",
                    style: .primary,
                    action: onKeepGoing
                )

                DebriefLeaveOption(
                    symbol: "flag.checkered",
                    title: "Finish Later",
                    subtitle: "Saved to daily quests",
                    style: .plain,
                    action: onFinishLater
                )

                DebriefLeaveOption(
                    symbol: "rectangle.portrait.and.arrow.right",
                    title: "Leave Progress",
                    subtitle: "Streak kept",
                    style: .danger,
                    action: onLeave
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        // Reads the content's real height and stores it, so the sheet below can match it.
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            contentHeight = height
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground { MokoBackdrop() }
    }
}

/// One big option row in the leave sheet.
struct DebriefLeaveOption: View {
    enum Style {
        case primary, plain, danger
    }

    let symbol: String
    let title: String
    let subtitle: String
    let style: Style
    var action: () -> Void

    private var background: Color {
        style == .primary ? DebriefStyle.accent : Color.white
    }

    private var titleColor: Color {
        style == .primary ? Color.white : DebriefStyle.title
    }

    private var subtitleColor: Color {
        style == .primary ? Color.white.opacity(0.75) : DebriefStyle.subtext
    }

    private var iconBackground: Color {
        switch style {
        case .primary: return Color.white.opacity(0.14)
        case .plain:   return DebriefStyle.soft
        case .danger:  return DebriefStyle.danger.opacity(0.10)
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: return Color.white
        case .plain:   return DebriefStyle.accent
        case .danger:  return DebriefStyle.danger
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(iconBackground))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .mokoText(MokoScreenTheme.Typeface.slider)
                        .foregroundStyle(titleColor)

                    Text(subtitle)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(subtitleColor)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .mokoCard(fill: background)
        }
        .buttonStyle(DebriefPressStyle())
    }
}

// MARK: - Previews
#Preview("Debrief") {
    QuestDebriefScreen(
        context: DebriefContext(questTitle: "Coffee with Arjun", category: .dating, intensity: .medium)
    ) { _ in }
    .modelContainer(for: [Profile.self, Quest.self, InsightsModel.self], inMemory: true)
}

#Preview("Leave sheet") {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            DebriefLeaveSheet(
                unsentText: "Unsent audio (0:07) will be discarded",
                onKeepGoing: {}, onFinishLater: {}, onLeave: {}
            )
        }
}

#Preview("Complete") {
    ZStack(alignment: .bottom) {
        MokoBackdrop()

        ScoreReveal(
            scores: [
                .courage: 82,
                .clarity: 70,
                .presence: 78,
                .warmth: 86
            ],
            comparison: 8,
            xp: 50,
            streak: 4,
            onContinue: {}
        )
        .padding(16)
    }
}
