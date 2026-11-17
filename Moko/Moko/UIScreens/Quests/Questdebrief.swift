//
//  QuestDebrief.swift
//  Moko
//
//  The debrief: a chat with the on-device coach after a quest.
//  1. The coach asks how the quest went (the "opening story").
//  2. Then it asks 3 follow-up questions.
//  Every answer (spoken or typed) gets a confidence score, and each follow-up also
//  grades one of four parameters: Courage, Clarity, Presence and Warmth.
//
//  Who does what (good place to start debugging):
//  - `DebriefSession` (@Observable) holds the whole conversation and drives each step.
//  - `QuestDebriefScreen` draws it and saves the scores when it finishes.
//  - The coach is `AFMDebriefCoach` (Apple Foundation Models) when the phone supports it,
//    otherwise `DummyDebriefCoach` below, which scores answers with simple word rules.
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
    static let screenBg = MokoScreenTheme.Colors.canvasTop
    static let accent   = MokoScreenTheme.Colors.dataVioletDeep   // buttons, scores, icons
    static let title    = MokoScreenTheme.Colors.textTitle
    static let subtext  = MokoScreenTheme.Colors.textBody
    static let soft     = MokoScreenTheme.Colors.surfaceLavender  // tracks, chips, icon tiles
    static let border   = MokoScreenTheme.Colors.dataGrid
    static let danger   = MokoScreenTheme.Colors.error            // stop, discard, leave
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
    /// User's first name, used to personalise the opening greeting. Empty string = no name available.
    var userName: String = ""
}

/// A follow-up question and the parameter it is about.
struct DebriefQuestion {
    var text: String
    var focus: DebriefParameter
}

/// The coach's verdict on one answer.
struct DebriefGrade: Equatable {
    /// How confident the answer came across, 0...100 (shown on every answer).
    var confidence: Int
    /// Score for the parameter this answer was about, 0...100.
    var score: Int
    /// One kind sentence about the answer, shown when the bubble is expanded.
    var note: String
    /// The parameter this answer was about. nil for the opening story.
    var focus: DebriefParameter?
    /// Extra scores the coach gave for other parameters in the same answer.
    var parameterScores: [DebriefParameter: Int] = [:]
}

/// Anything that can run a debrief. `AFMDebriefCoach` and `DummyDebriefCoach` both follow it.
protocol DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String
    /// number is 1...3.
    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion
    /// focus is nil for the opening story.
    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade
    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int]
}

extension DebriefCoaching {
    /// Default end-of-debrief scores, used by every coach that doesn't write its own:
    /// 1. Keep the best score seen for each parameter.
    /// 2. Courage falls back to the average confidence if no answer scored it.
    /// 3. Anything still under 40 is lifted to a gentle 48–76, so no score feels harsh.
    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int] {
        var scores: [DebriefParameter: Int] = [:]
        for grade in grades {
            if let focus = grade.focus {
                scores[focus] = max(scores[focus] ?? 0, grade.score)
            }
            for (param, s) in grade.parameterScores {
                scores[param] = max(scores[param] ?? 0, s)
            }
        }
        let confidences = grades.map { $0.confidence }
        let avgConf = confidences.isEmpty ? 68 : confidences.reduce(0, +) / confidences.count
        if scores[.courage] == nil || scores[.courage] == 0 {
            scores[.courage] = avgConf
        }
        for param in DebriefParameter.allCases {
            let current = scores[param] ?? 0
            if current < 40 {
                scores[param] = max(48, min(avgConf, 76))
            }
        }
        return scores
    }
}

/// Fallback coach for phones without Apple Intelligence.
/// Questions come from the Mission Bank; grades come from answer length and a few key words.
struct DummyDebriefCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String {
        DebriefSession.openingGreeting(for: context)
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        let bankTemplates = MissionBank.templates(in: context.category)
        let template = bankTemplates.first ?? MissionBank.all[0]

        switch number {
        case 1:
            let q = template.followUps[.presence] ?? "What is one thing you noticed about their reaction while talking?"
            return DebriefQuestion(text: q, focus: .presence)
        case 2:
            let q = template.followUps[.clarity] ?? "What exact words did you use to say what you meant?"
            return DebriefQuestion(text: q, focus: .clarity)
        default:
            let q = template.followUps[.warmth] ?? "Did you acknowledge how they were feeling or ask about them?"
            return DebriefQuestion(text: q, focus: .warmth)
        }
    }

    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split(separator: " ")
        let wordCount = words.count

        // Confidence strictly reflects answer length — short answers can't score high.
        let confidence: Int
        switch wordCount {
        case 0..<8:   confidence = Int.random(in: 40...50)   // too brief / incomplete
        case 8..<20:  confidence = Int.random(in: 50...62)   // brief with no concrete detail
        case 20..<40: confidence = Int.random(in: 63...75)   // decent description
        default:      confidence = Int.random(in: 76...90)   // rich first-person account
        }

        // Simple key-word checks. Each one nudges a score up a little.
        let lower = trimmed.lowercased()
        let hasActionVerb = ["said", "told", "asked", "went", "did", "decided", "started", "spoke"].contains { lower.contains($0) }
        let hasDirectness = ["clear", "direct", "exactly", "honestly", "straight"].contains { lower.contains($0) }
        let hasObservation = ["looked", "noticed", "saw", "smiled", "nodded", "listened", "reaction"].contains { lower.contains($0) }
        let hasWarmthWords = ["thank", "glad", "happy", "shared", "appreciated", "friend", "kind"].contains { lower.contains($0) }

        var score = max(55, min(92, 60 + (wordCount > 6 ? 12 : 4) + (hasActionVerb ? 8 : 0)))
        let note: String
        var paramScores: [DebriefParameter: Int] = [:]

        switch focus {
        case .presence:
            if hasObservation {
                score = min(95, score + 8)
                note = "You tuned in to the room and noticed real details about their reaction."
            } else {
                note = "You stayed grounded in the moment instead of retreating inward."
            }
            paramScores[.presence] = score

        case .clarity:
            if hasDirectness || wordCount <= 25 {
                score = min(95, score + 8)
                note = "You communicated your thoughts concisely without circling around the point."
            } else {
                note = "You articulated what happened clearly, making your experience easy to follow."
            }
            paramScores[.clarity] = score

        case .warmth:
            if hasWarmthWords {
                score = min(95, score + 8)
                note = "You brought genuine openness and care to the interaction."
            } else {
                note = "You acknowledged the other person thoughtfully, creating space for connection."
            }
            paramScores[.warmth] = score

        case .courage, .none:
            let courageScore = max(58, min(95, score + (hasActionVerb ? 6 : 0)))
            let clarityScore = max(55, min(92, score - (wordCount > 35 ? 4 : 0)))
            if hasActionVerb {
                note = "You stepped forward into the moment and took concrete action."
            } else {
                note = "You showed real willingness to lean into an uncomfortable situation."
            }
            paramScores[.courage] = courageScore
            paramScores[.clarity] = clarityScore
            score = courageScore
        }

        return DebriefGrade(
            confidence: confidence,
            score: score,
            note: note,
            focus: focus,
            parameterScores: paramScores
        )
    }
}

// MARK: - Conversation data

/// One row in the chat: a coach bubble, a user bubble, or a "Question n of 3" header.
struct DebriefMessage: Identifiable {
    enum Kind {
        case ai(String)
        case user(text: String, grade: DebriefGrade?)
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
    static let followUpCount = 3

    var context: DebriefContext
    private let coach: any DebriefCoaching

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
    /// 0 = the opening story, 1...3 = follow-ups.
    var questionNumber = 0
    var result: DebriefResult?
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
        /// Ask follow-up `number`; `divider` adds the "Question n of 3" header when the
        /// saved conversation stopped before it.
        case ask(number: Int, divider: Bool)
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
        !messages.isEmpty && !isCoachTyping && !isGrading && !isComplete
    }

    /// Recording time as "m:ss".
    var timeText: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    // MARK: Start

    /// Shows the first question (or picks up a saved draft). Safe to call more than once.
    func start() async {
        guard !started else { return }
        started = true

        // A saved debrief continues mid-conversation: no greeting and no replay.
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
            }
            return
        }

        // Show the opening question straight away so the composer is usable
        // immediately. The coach's personalised greeting is generated in the
        // background and swapped in only if the user has not answered yet.
        append(.ai(Self.openingGreeting(for: context)))

        let text = await coach.greeting(for: context)
        // `case .ai = first.kind` checks the first row is still the coach's greeting.
        guard !Task.isCancelled,
              answers.isEmpty,
              let first = messages.first,
              case .ai = first.kind
        else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            messages[0].kind = .ai(text)
        }
        persist()
    }

    /// The instant greeting, also used by `DummyDebriefCoach`.
    static func openingGreeting(for context: DebriefContext) -> String {
        context.userName.isEmpty
            ? "Hey! How did it go — did you manage to do it?"
            : "Hey \(context.userName)! How did it go — did you manage to do it?"
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

    /// Adds the user's answer, scores it, then asks the next question (or finishes).
    func submit(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, canAnswer else { return }

        let answeredFocus = focus
        append(.user(text: text, grade: nil))
        let messageID = messages.last?.id
        answers.append(text)
        isGrading = true

        flowTask = Task { [weak self] in
            guard let self else { return }

            let grade = await self.coach.grade(answer: text, focus: answeredFocus, context: self.context)
            guard !Task.isCancelled else { return }
            self.apply(grade, to: messageID)
            self.isGrading = false

            if self.questionNumber < DebriefSession.followUpCount {
                self.questionNumber += 1
                self.append(.divider(question: self.questionNumber))
                await self.askQuestion(number: self.questionNumber)
            } else {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                self.finish()
            }
        }
    }

    /// Asks the coach for the follow-up `number` and remembers what it is about.
    private func askQuestion(number: Int) async {
        isCoachTyping = true
        let next = await coach.question(
            number: number,
            context: context,
            previousAnswers: answers
        )
        guard !Task.isCancelled else { return }
        isCoachTyping = false
        focus = next.focus
        append(.ai(next.text))
    }

    /// Saves the grade and shows it on the answer bubble with the matching `id`.
    private func apply(_ grade: DebriefGrade, to id: UUID?) {
        grades.append(grade)
        persist()

        guard let id, let index = messages.firstIndex(where: { $0.id == id }) else { return }
        if case .user(let text, _) = messages[index].kind {
            withAnimation(.easeOut(duration: 0.4)) {
                messages[index].kind = .user(text: text, grade: grade)
            }
        }
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
                return DebriefMessage(kind: .user(text: stored.text, grade: stored.grade?.restored))
            case .divider:
                return DebriefMessage(kind: .divider(question: stored.question))
            }
        }
        answers = draft.answers
        grades = draft.grades.map { $0.restored }
        questionNumber = draft.questionNumber
        focus = draft.focus.flatMap(DebriefParameter.init(rawValue:))

        isRestored = true

        if answers.count > DebriefSession.followUpCount {
            // Every answer was in before the debrief was left: show the scores.
            finish()
        } else if let last = messages.last {
            switch last.kind {
            case .divider:
                // The coach was still thinking about this follow-up.
                resumeStep = .ask(number: questionNumber, divider: false)
            case .user:
                // The answer landed but its follow-up never started.
                resumeStep = .ask(number: questionNumber + 1, divider: true)
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
                case .user(let text, let grade):
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
            focus: focus?.rawValue
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

    /// The real coach when Apple Intelligence is available, otherwise the simple fallback.
    private static func defaultCoach() -> any DebriefCoaching {
        AFM.isAvailable ? AFMDebriefCoach() : DummyDebriefCoach()
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
                intensity: quest.intensity
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
                MokoLoadingView(
                    message: "Your coach is thinking..."
                    
                )
                .transition(.opacity)
            }
            
            // Show animated score reveal when debrief is complete
            if session.isComplete, let result = session.result {
                ScoreReveal(scores: [
                    .courage: result.scores[.courage] ?? 0,
                    .clarity: result.scores[.clarity] ?? 0,
                    .presence: result.scores[.presence] ?? 0,
                    .warmth: result.scores[.warmth] ?? 0
                ])
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }


            if session.isCoachTyping {
                DebriefTypingIndicator()
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
        case .user(let text, let grade):
            DebriefUserBubble(text: text, grade: grade)
        case .divider(let number):
            DebriefQuestionHeader(number: number, total: DebriefSession.followUpCount)
        }
    }

    // MARK: Bottom area

    /// The answer box (plus the orb while recording), or the results panel at the end.
    private var bottomArea: some View {
        VStack(spacing: 10) {
            if session.isComplete, let result = session.result {
                DebriefCompletionPanel(result: result) {
                    exit(.completed)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                if session.isRecording {
                    DebriefOrb(level: session.orbLevel)
                        .frame(height: 128)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

                composer
            }
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
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: session.isComplete)
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
    }

    /// Fills the bar to the grade's confidence, or marks it as waiting.
    private func syncMeter() {
        if let grade {
            waiting = false
            withAnimation(.easeOut(duration: 1.0)) {
                meter = Double(grade.confidence) / 100
            }
        } else {
            waiting = true
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
                } else {
                    MokoLoadingView()
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
        .accessibilityLabel(grade.map { "Confidence \($0.confidence). Tap for details." } ?? "Grading")
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

/// "Follow-up questions … Question 2 of 3" row between questions.
struct DebriefQuestionHeader: View {
    let number: Int
    let total: Int

    var body: some View {
        HStack {
            Text("Follow-up questions")
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)

            Spacer()

            Text("Question \(number) of \(total)")
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

/// Loading spinner while the coach is thinking.
struct DebriefTypingIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            MokoLoadingView()
                .frame(height: 44)

            Spacer()
        }
        .accessibilityLabel("Your coach is typing")
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

// MARK: - Debrief Complete

/// The results panel: check mark, XP, streak and the four score bars.
struct DebriefCompletionPanel: View {
    let result: DebriefResult
    var onContinue: () -> Void

    // Flipped on appear: pops the check mark in and fills the score bars one by one.
    @State private var animate = false
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(DebriefStyle.soft.opacity(0.7)).frame(width: 58, height: 58)
                    Circle().fill(DebriefStyle.accent).frame(width: 46, height: 46)
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: animate)
                }
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)
                .overlay(
                    MokoLottieView(animation: .confetti, loopMode: .playOnce)
                        .frame(width: 80, height: 80)
                        .opacity(showConfetti ? 1 : 0)
                        .allowsHitTesting(false)
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Debrief Complete")
                            .mokoText(MokoScreenTheme.Typeface.cardTitle)
                            .foregroundStyle(DebriefStyle.title)

                        Text("+\(result.xp) XP")
                            .mokoText(MokoScreenTheme.Typeface.caption)
                            .foregroundStyle(DebriefStyle.accent)
                            .padding(.horizontal, 9)
                            .frame(height: 24)
                            .background(Capsule().fill(DebriefStyle.soft.opacity(0.7)))
                    }

                    if result.streak > 0 {
                        Text("\(result.streak)-day streak")
                            .mokoText(MokoScreenTheme.Typeface.caption)
                            .foregroundStyle(DebriefStyle.subtext)
                    }
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(DebriefStyle.border)
                .frame(height: 1)

            // Yesterday's comparison header
            HStack {
                Text("Compared to yesterday")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(DebriefStyle.subtext)
                Spacer()
                // Simulated yesterday's total (would come from actual data)
                Text("+8")
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .foregroundStyle(Color.green)
                Text("points")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(DebriefStyle.subtext)
            }
            .padding(.horizontal, 4)

            // Sliding cards for 4 parameters (right-side layout)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DebriefParameter.allCases, id: \.self) { parameter in
                        scoreCard(parameter)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 140)

            Button(action: onContinue) {
                Text("Continue")
                    .mokoText(MokoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Capsule().fill(DebriefStyle.accent))
                    .shadow(color: DebriefStyle.accent.opacity(0.25), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(DebriefPressStyle())
        }
        .padding(18)
        .mokoCard(fill: MokoScreenTheme.Colors.surfaceLavender)
        .animation(.spring(response: 0.55, dampingFraction: 0.7), value: animate)
        .onAppear {
            animate = true
            // Trigger confetti animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    /// Score card for sliding cards layout
    private func scoreCard(_ parameter: DebriefParameter) -> some View {
        let value = result.scores[parameter] ?? 0
        // Simulated yesterday's value (would come from actual data)
        let yesterdayValue = max(0, value - Int.random(in: 5...15))
        let change = value - yesterdayValue
        let changeColor = change >= 0 ? Color.green : Color.red
        
        return VStack(spacing: 8) {
            // Parameter icon and name
            HStack {
                Image(systemName: parameter.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(parameter.accent)
                
                Text(parameter.rawValue)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(DebriefStyle.title)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // Today's score (big number)
            Text("\(value)")
                .mokoText(MokoScreenTheme.Typeface.numeral)
                .foregroundStyle(DebriefStyle.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Yesterday comparison
            HStack {
                Text("Yesterday: \(yesterdayValue)")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(DebriefStyle.subtext)
                
                Spacer()
                
                Text(change >= 0 ? "+\(change)" : "\(change)")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(changeColor)
            }
            
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DebriefStyle.soft.opacity(0.4))
                    
                    Capsule()
                        .fill(parameter.accent)
                        .frame(width: geo.size.width * (animate ? Double(value) / 100 : 0))
                        .animation(.easeOut(duration: 0.6), value: animate)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(MokoScreenTheme.Colors.surfaceWhite)
                .shadow(color: DebriefStyle.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        )
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

        DebriefCompletionPanel(
            result: DebriefResult(
                scores: [.courage: 82, .clarity: 70, .presence: 78, .warmth: 86],
                xp: 50,
                streak: 4
            ),
            onContinue: {}
        )
        .padding(16)
    }
}
