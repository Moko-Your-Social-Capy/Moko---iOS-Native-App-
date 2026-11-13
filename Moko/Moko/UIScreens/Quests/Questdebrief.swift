//
//  QuestDebrief.swift
//  Moko
//
//  The debrief: a conversation with the on-device coach (Apple Foundation Models later,
//  dummy values for now). The coach asks about how the quest went, then three follow-up
//  questions. Each answer (spoken or typed) gets a confidence score, and the follow-ups
//  also grade one of four parameters: Listening, Curiosity, Warmth and Confidence.
//
//  Screens: the conversation (QuestDebriefScreen), the "Leave debrief early?" sheet, and the
//  "Debrief Complete" panel with the four scores. To plug in the real model, write a type
//  that conforms to DebriefCoaching and pass it as QuestDebriefScreen(coach:).
//

import SwiftUI
import SwiftData
import Observation

// MARK: - Where the user ends up
enum DebriefOutcome {
    case completed      // finished the debrief, tapped Continue
    case finishLater    // stepped away, saved to resume
    case leave          // left, streak kept
}

// MARK: - Style
enum DebriefStyle {
    static let screenBg = MocoScreenTheme.Colors.canvasTop  // #F6FAE8
    static let green = MocoScreenTheme.Colors.dataVioletDeep        // #365948
    static let deepGreen = MocoScreenTheme.Colors.dataVioletDeep    // #1B422F
    static let title = MocoScreenTheme.Colors.textTitle        // #5C4330
    static let subtext = MocoScreenTheme.Colors.textBody    // #6F6762
    static let cream = MocoScreenTheme.Colors.surfaceLavender
    static let border = MocoScreenTheme.Colors.dataGrid
    static let sand = MocoScreenTheme.Colors.surfaceLavender
    static let rust = MocoScreenTheme.Colors.error
    static let mint = MocoScreenTheme.Colors.surfaceLavender
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

    /// One soft background for every parameter, so the scores read as a set
    var tint: Color {
        DebriefStyle.mint.opacity(0.55)
    }

    /// One strong foreground for every parameter, matching the app's green
    var accent: Color {
        DebriefStyle.deepGreen
    }
}

// MARK: - Coach (plug the real model in here)
struct DebriefContext {
    var questTitle: String
    var category: QuestCategory
    var intensity: QuestIntensity
    /// User's first name, used to personalise the opening greeting. Empty string = no name available.
    var userName: String = ""
}

struct DebriefQuestion {
    var text: String
    var focus: DebriefParameter
}

struct DebriefGrade: Equatable {
    /// How confident the answer came across, 0...100 (shown on every answer)
    var confidence: Int
    /// Score for the parameter this answer was about, 0...100
    var score: Int
    var note: String
    var focus: DebriefParameter?
    var parameterScores: [DebriefParameter: Int] = [:]
}

protocol DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String
    /// number is 1...3
    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion
    /// focus is nil for the opening story
    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade
    func finalScores(from grades: [DebriefGrade], context: DebriefContext) -> [DebriefParameter: Int]
}

extension DebriefCoaching {
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

/// Fallback coach using dynamic linguistic evaluation of user responses.
struct DummyDebriefCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String {
        let namePrefix = context.userName.isEmpty ? "Hey!" : "Hey \(context.userName)!"
        return "\(namePrefix) How did it go — did you manage to do it?"
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

        // Confidence strictly reflects answer length — short answers can't score high
        let confidence: Int
        switch wordCount {
        case 0..<8:   confidence = Int.random(in: 40...50)   // too brief / incomplete
        case 8..<20:  confidence = Int.random(in: 50...62)   // brief with no concrete detail
        case 20..<40: confidence = Int.random(in: 63...75)   // decent description
        default:      confidence = Int.random(in: 76...90)   // rich first-person account
        }

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
struct DebriefMessage: Identifiable {
    enum Kind {
        case ai(String)
        case user(text: String, grade: DebriefGrade?)
        case divider(question: Int)
    }

    let id = UUID()
    var kind: Kind
}

struct DebriefResult {
    var scores: [DebriefParameter: Int]
    var xp: Int
    var streak: Int
}

// MARK: - Session (drives the whole conversation)
@MainActor
@Observable
final class DebriefSession {
    static let followUpCount = 3

    var context: DebriefContext
    private let coach: any DebriefCoaching

    var messages: [DebriefMessage] = []
    var isCoachTyping = false
    var isGrading = false
    var isRecording = false
    var isComplete = false
    /// True while the "Leave early?" sheet is open
    var isPaused = false

    var elapsed = 0
    var transcript = ""
    var levels: [Double] = Array(repeating: 0.08, count: 34)
    var orbLevel: Double = 0

    /// What the current question is about (nil for the opening story)
    var focus: DebriefParameter?
    /// 0 = the opening story, 1...3 = follow-ups
    var questionNumber = 0
    var result: DebriefResult?
    /// XP and streak to show when the debrief finishes
    var reward = QuestReward(xp: 0, streak: 0)

    /// The quest this debrief belongs to. When set, every change is also written to
    /// `DebriefDraftStore` so an interrupted debrief can be picked up later.
    var questID: UUID?

    private var answers: [String] = []
    private var grades: [DebriefGrade] = []
    private var started = false
    private var isRestored = false
    private var resumeStep: ResumeStep = .none

    /// What a restored debrief does before it accepts an answer again
    private enum ResumeStep: Equatable {
        case none
        /// Ask follow-up `number`; `divider` adds the "Question n of 3" header when the
        /// saved conversation stopped before it.
        case ask(number: Int, divider: Bool)
    }
    private var recordingTask: Task<Void, Never>?
    private var flowTask: Task<Void, Never>?

    init(context: DebriefContext, coach: any DebriefCoaching) {
        self.context = context
        self.coach = coach
    }

    var canAnswer: Bool {
        !messages.isEmpty && !isCoachTyping && !isGrading && !isComplete
    }

    /// How many of the four answers have been graded (drives the progress bar)
    var gradedCount: Int { grades.count }

    var timeText: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    // MARK: Start
    func start() async {
        guard !started else { return }
        started = true

        // A saved debrief continues mid-conversation: no greeting and no replay
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

    private static func openingGreeting(for context: DebriefContext) -> String {
        context.userName.isEmpty
            ? "Hey! How did it go — did you manage to do it?"
            : "Hey \(context.userName)! How did it go — did you manage to do it?"
    }

    // MARK: Voice (simulated)
    private static let spokenAnswers = [
        "I asked him about his new internship first, and he asked about my semester. It got quiet for a bit, but I kept going.",
        "Mostly listening, I think. When it went quiet I started planning what to say next, but then I caught myself and tried to tune back into what he was saying about his project.",
        "I asked how the team treats new hires, because I really wanted to know. He lit up and told me all about his first week.",
        "I told him I was really glad we caught up and that I missed our school days. He smiled and said the same."
    ]

    func startRecording() {
        guard canAnswer, !isRecording else { return }

        isRecording = true
        elapsed = 0
        transcript = ""

        let script = Self.spokenAnswers[min(questionNumber, Self.spokenAnswers.count - 1)]
        let words = script.split(separator: " ").map(String.init)

        recordingTask = Task { [weak self] in
            var tick = 0
            var spoken = 0
            var quietTicks = 0

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(90))
                guard let self, !Task.isCancelled else { return }
                if self.isPaused { continue }

                tick += 1
                let speaking = spoken < words.count
                self.pushLevel(speaking: speaking)

                if tick % 11 == 0 { self.elapsed += 1 }

                if speaking {
                    if tick % 4 == 0 {
                        spoken += 1
                        self.transcript = words[0..<spoken].joined(separator: " ")
                    }
                } else {
                    // Finished speaking: pause for a beat, then send automatically
                    quietTicks += 1
                    if quietTicks > 14 {
                        self.finishRecording()
                        return
                    }
                }
            }
        }
    }

    /// Stop and send what was heard
    func finishRecording() {
        guard isRecording else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        stopRecording()
        if !text.isEmpty {
            submit(text)
        }
    }

    /// Stop and throw the recording away
    func cancelRecording() {
        stopRecording()
    }

    private func stopRecording() {
        recordingTask?.cancel()
        recordingTask = nil
        isRecording = false
        orbLevel = 0
        elapsed = 0
        transcript = ""
        levels = Array(repeating: 0.08, count: levels.count)
    }

    private func pushLevel(speaking: Bool) {
        let target = speaking ? Double.random(in: 0.25...1.0) : Double.random(in: 0.05...0.2)
        orbLevel = orbLevel * 0.5 + target * 0.5
        levels.removeFirst()
        levels.append(orbLevel)
    }

    // MARK: Answering
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

    private func finish() {
        let scores = coach.finalScores(from: grades, context: context)

        result = DebriefResult(scores: scores, xp: reward.xp, streak: reward.streak)
        focus = nil

        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            isComplete = true
        }
        persist()
    }

    func cancelAll() {
        recordingTask?.cancel()
        flowTask?.cancel()
    }

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
            // Every answer was in before the debrief was left: show the scores
            finish()
        } else if let last = messages.last {
            switch last.kind {
            case .divider:
                // The coach was still thinking about this follow-up
                resumeStep = .ask(number: questionNumber, divider: false)
            case .user:
                // The answer landed but its follow-up never started
                resumeStep = .ask(number: questionNumber + 1, divider: true)
            case .ai:
                resumeStep = .none
            }
        }
    }

    private func persist() {
        guard let questID else { return }
        DebriefDraftStore.save(snapshot(), for: questID)
    }

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

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    private let quest: Quest?
    @State private var session: DebriefSession
    @State private var draft = ""
    @State private var showLeave = false
    @FocusState private var isTyping: Bool

    init(context: DebriefContext,
         coach: (any DebriefCoaching)? = nil,
         onExit: @escaping (DebriefOutcome) -> Void) {
        let activeCoach = coach ?? (AFM.isAvailable ? AFMDebriefCoach() : DummyDebriefCoach())
        self.quest = nil
        _session = State(initialValue: DebriefSession(context: context, coach: activeCoach))
        self.onExit = onExit
    }

    init(quest: Quest,
         coach: (any DebriefCoaching)? = nil,
         onExit: @escaping (DebriefOutcome) -> Void) {
        let activeCoach = coach ?? (AFM.isAvailable ? AFMDebriefCoach() : DummyDebriefCoach())
        self.quest = quest

        let session = DebriefSession(
            context: DebriefContext(
                questTitle: quest.title,
                category: quest.category,
                intensity: quest.intensity
                // userName is injected via .task once profiles load
            ),
            coach: activeCoach
        )
        // Pick up an unfinished debrief where the user left it
        session.questID = quest.id
        if let draft = DebriefDraftStore.load(for: quest.id) {
            session.restore(from: draft)
        }

        _session = State(initialValue: session)
        self.onExit = onExit
    }

    private var unsentText: String? {
        if session.isRecording { return "Unsent audio (\(session.timeText)) will be discarded" }
        if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Your unsent answer will be discarded" }
        return nil
    }

    var body: some View {
        ZStack {
            MocoBackdrop()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        conversation
                        Color.clear.frame(height: 1).id("bottom")
                    }
                }
                .scrollDismissesKeyboard(.interactively)
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
        .task {
            // Inject first name so the coach can greet the user personally
            if let name = profiles.first?.username, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let firstName = name.split(separator: " ").first.map(String.init) ?? name
                session.context.userName = firstName
            }
            syncReward()
            await session.start()

            // A debrief that was already finished when it was saved still needs its scores stored
            if session.isComplete {
                recordDebrief()
            }
        }
        .onChange(of: session.isComplete) { _, isComplete in
            if isComplete {
                recordDebrief()
            }
        }
        .onChange(of: showLeave) { _, isShown in
            session.isPaused = isShown
        }
        .onDisappear {
            session.cancelAll()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: session.messages.count)
        .sensoryFeedback(.impact(weight: .medium), trigger: session.isRecording)
        .sensoryFeedback(.success, trigger: session.isComplete)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.35)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    /// Keeps the completion panel's XP and streak in sync with saved progress.
    private func syncReward() {
        guard let quest else { return }

        let profile = profiles.first
        session.reward = QuestReward(
            xp: quest.awardedXP,
            streak: QuestProgress.nextStreak(
                current: profile?.currentStreak ?? 0,
                lastActivity: profile?.lastActivityDate
            )
        )
    }

    /// Persists the debrief scores and any XP/streak that have not been awarded yet.
    private func recordDebrief() {
        guard let quest, let result = session.result else { return }

        let reward = QuestProgress.saveDebrief(result, for: quest, in: modelContext)
        session.reward = reward
        // The debrief is behind us: the saved draft has done its job
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

    // MARK: Header
    private var focusLabel: String {
        if session.isComplete { return "Complete" }
        return session.focus?.rawValue ?? "Your story"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debrief")
                .mocoText(MocoScreenTheme.Typeface.title1)
                .foregroundColor(DebriefStyle.title)

            (Text("\(session.context.questTitle) · ")
                .foregroundColor(DebriefStyle.subtext)
             + Text(focusLabel)
                .foregroundColor(DebriefStyle.green)
                .fontWeight(.semibold))
                .mocoText(MocoScreenTheme.Typeface.body)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: focusLabel)

            // Four segments: the story, then three follow-ups
            HStack(spacing: 6) {
                ForEach(0..<(DebriefSession.followUpCount + 1), id: \.self) { index in
                    Capsule()
                        .fill(index < session.gradedCount ? DebriefStyle.green : Color.black.opacity(0.08))
                        .frame(height: 5)
                }
            }
            .padding(.top, 8)
            .animation(.easeOut(duration: 0.5), value: session.gradedCount)
        }
        .padding(.horizontal, MocoScreenTheme.Space.page)
        .padding(.top, 20)
    }

    // MARK: Conversation
    private var conversation: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(session.messages) { message in
                messageView(message)
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
        .padding(.horizontal, MocoScreenTheme.Space.page)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isCoachTyping)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isRecording)
    }

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
        .padding(.horizontal, MocoScreenTheme.Space.page)
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

    private var composer: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $draft, axis: .vertical)
                .mocoText(MocoScreenTheme.Typeface.body)
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
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.deepGreen))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .accessibilityLabel("Leave debrief")
        }
        .padding(.leading, 16)
        .padding(.trailing, 7)
        .padding(.vertical, 7)
        .frame(minHeight: 58)
        .mocoCard()
    }

    /// Send (when there's text), cancel (while recording) or start the mic
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
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.green))
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
                    .foregroundColor(DebriefStyle.rust)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.rust.opacity(0.12)))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .accessibilityLabel("Discard recording")
        } else {
            Button {
                isTyping = false
                session.startRecording()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DebriefStyle.green)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DebriefStyle.mint.opacity(0.7)))
                    .contentShape(Circle())
            }
            .buttonStyle(DebriefPressStyle())
            .disabled(!session.canAnswer)
            .opacity(session.canAnswer ? 1 : 0.4)
            .accessibilityLabel("Answer by voice")
        }
    }
}

// MARK: - Shared button feel
struct DebriefPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Bubbles
/// The coach's message. The words type in.
struct DebriefCoachBubble: View {
    let text: String

    @State private var shownCount = 0
    @State private var hasTyped = false

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text(text).opacity(0) // reserves the final size so the bubble doesn't jump
                Text(String(text.prefix(shownCount)))
            }
            .mocoText(MocoScreenTheme.Typeface.body)
            .foregroundColor(DebriefStyle.title)
            .lineSpacing(3)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .mocoCard()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)

            Spacer(minLength: 44)
        }
        .task(id: text) {
            // The coach's personalised opening replaces the instant fallback.
            // Show the replacement in full instead of typing it out again.
            if hasTyped {
                shownCount = text.count
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

    @State private var expanded = false
    @State private var meter: Double = 0
    @State private var waiting = false

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text(text)
                    .mocoText(MocoScreenTheme.Typeface.body)
                    .foregroundColor(DebriefStyle.title)
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
            .mocoCard(fill: MocoScreenTheme.Colors.surfaceLavender)
        }
        .onAppear { syncMeter() }
        .onChange(of: grade) { _, _ in syncMeter() }
    }

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

    private var footer: some View {
        Button {
            guard grade != nil else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Text("Confidence")
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .foregroundColor(DebriefStyle.subtext)

                meterBar

                if let grade {
                    Text("\(grade.confidence)")
                        .mocoText(MocoScreenTheme.Typeface.slider)
                        .foregroundColor(DebriefStyle.green)
                        .monospacedDigit()
                } else {
                    MokoFlossLoadingView(size: 28)
                        .frame(width: 28, height: 28)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DebriefStyle.title)
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
                Capsule().fill(DebriefStyle.sand.opacity(0.9))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [DebriefStyle.mint, DebriefStyle.green],
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

    private func details(_ grade: DebriefGrade) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(grade.note)
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundColor(DebriefStyle.subtext)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let focus = grade.focus {
                    HStack(spacing: 6) {
                        Image(systemName: focus.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(focus.rawValue) \(grade.score)")
                            .mocoText(MocoScreenTheme.Typeface.caption)
                    }
                    .foregroundColor(focus.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Capsule().fill(focus.tint))
                } else {
                    Text("Your story")
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundColor(DebriefStyle.green)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(Capsule().fill(DebriefStyle.mint.opacity(0.7)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .padding(.top, 2)
    }
}

struct DebriefQuestionHeader: View {
    let number: Int
    let total: Int

    var body: some View {
        HStack {
            Text("Follow-up questions")
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundColor(MocoScreenTheme.Colors.textBody)

            Spacer()

            Text("Question \(number) of \(total)")
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundColor(DebriefStyle.title)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Capsule().fill(DebriefStyle.sand))
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }
}

/// Three bouncing dots while the coach is thinking
struct DebriefTypingIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        let wave = sin(t * 6 + Double(index) * 0.9)

                        Circle()
                            .fill(DebriefStyle.green.opacity(0.55 + 0.35 * (wave + 1) / 2))
                            .frame(width: 8, height: 8)
                            .offset(y: CGFloat(wave) * -3)
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 44)
            .mocoCard(radius: MocoScreenTheme.Radius.pill)

            Spacer()
        }
        .accessibilityLabel("Your coach is typing")
    }
}

// MARK: - Recording
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
                        Circle().fill(DebriefStyle.rust.opacity(0.14))
                        Circle().fill(DebriefStyle.rust).frame(width: 26, height: 26)
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
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .monospacedDigit()
                    .foregroundColor(DebriefStyle.subtext)
            }

            // Live transcript with a blinking caret
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let caretOn = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0

                (Text(transcript.isEmpty ? "Listening…" : transcript)
                    .foregroundColor(transcript.isEmpty ? DebriefStyle.subtext : DebriefStyle.title)
                 + Text(" ▏").foregroundColor(caretOn ? DebriefStyle.green : Color.clear))
                    .mocoText(MocoScreenTheme.Typeface.body)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .mocoCard(fill: MocoScreenTheme.Colors.surfaceLavender)
    }

    /// Newest sound on the right, older sound fading to sand on the left
    private var waveform: some View {
        HStack(spacing: 3) {
            ForEach(levels.indices, id: \.self) { index in
                let age = Double(index) / Double(max(levels.count - 1, 1))

                Capsule()
                    .fill(age > 0.6 ? DebriefStyle.green : MocoScreenTheme.Colors.dataViolet)
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

    @State private var spin = false

    var body: some View {
        ZStack {
            DebriefDottedRing(count: 30, radius: 60, color: DebriefStyle.green)
                .rotationEffect(.degrees(spin ? 360 : 0))

            DebriefDottedRing(count: 18, radius: 47, color: MocoScreenTheme.Colors.dataViolet)
                .rotationEffect(.degrees(spin ? -360 : 0))

            // Glow that follows the voice
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DebriefStyle.green.opacity(0.35), DebriefStyle.green.opacity(0)],
                        center: .center,
                        startRadius: 8,
                        endRadius: 62
                    )
                )
                .frame(width: 124, height: 124)
                .scaleEffect(1 + 0.22 * level)
                .animation(.easeOut(duration: 0.12), value: level)

            Circle()
                .fill(DebriefStyle.mint.opacity(0.8))
                .frame(width: 78, height: 78)
                .scaleEffect(1 + 0.12 * level)
                .animation(.easeOut(duration: 0.12), value: level)

            // Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MocoScreenTheme.Colors.dataViolet, DebriefStyle.deepGreen],
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
                .shadow(color: DebriefStyle.deepGreen.opacity(0.35), radius: 12, x: 0, y: 6)
                .scaleEffect(1 + 0.08 * level)
                .animation(.easeOut(duration: 0.12), value: level)
        }
        .frame(width: 132, height: 132)
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
        .accessibilityHidden(true)
    }
}

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
struct DebriefLeaveSheet: View {
    var unsentText: String?
    var onKeepGoing: () -> Void
    var onFinishLater: () -> Void
    var onLeave: () -> Void

    @State private var contentHeight: CGFloat = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(DebriefStyle.rust)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DebriefStyle.cream))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Leave debrief early?")
                        .mocoText(MocoScreenTheme.Typeface.section)
                        .foregroundColor(DebriefStyle.title)

                    Text("Take a breath. No penalty for stepping away.")
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundColor(DebriefStyle.subtext)
                }
            }

            if let unsentText {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 232/255, green: 120/255, blue: 60/255))
                        .frame(width: 6, height: 6)

                    Text(unsentText)
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundColor(Color(red: 170/255, green: 90/255, blue: 40/255))
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
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            contentHeight = height
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground { MocoBackdrop() }
    }
}

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
        style == .primary ? DebriefStyle.deepGreen : Color.white
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
        case .plain:   return DebriefStyle.cream
        case .danger:  return DebriefStyle.rust.opacity(0.10)
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: return Color.white
        case .plain:   return DebriefStyle.green
        case .danger:  return DebriefStyle.rust
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(iconBackground))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .mocoText(MocoScreenTheme.Typeface.slider)
                        .foregroundColor(titleColor)

                    Text(subtitle)
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundColor(subtitleColor)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .mocoCard(fill: background)
        }
        .buttonStyle(DebriefPressStyle())
    }
}

// MARK: - Debrief Complete
struct DebriefCompletionPanel: View {
    let result: DebriefResult
    var onContinue: () -> Void

    @State private var animate = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(DebriefStyle.mint.opacity(0.7)).frame(width: 58, height: 58)
                    Circle().fill(DebriefStyle.deepGreen).frame(width: 46, height: 46)
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: animate)
                }
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Debrief Complete")
                            .mocoText(MocoScreenTheme.Typeface.cardTitle)
                            .foregroundColor(DebriefStyle.title)

                        Text("+\(result.xp) XP")
                            .mocoText(MocoScreenTheme.Typeface.caption)
                            .foregroundColor(DebriefStyle.green)
                            .padding(.horizontal, 9)
                            .frame(height: 24)
                            .background(Capsule().fill(DebriefStyle.mint.opacity(0.7)))
                    }

                    if result.streak > 0 {
                        Text("\(result.streak)-day streak")
                            .mocoText(MocoScreenTheme.Typeface.caption)
                            .foregroundColor(DebriefStyle.subtext)
                    }
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(DebriefStyle.border)
                .frame(height: 1)

            VStack(spacing: 12) {
                ForEach(Array(DebriefParameter.allCases.enumerated()), id: \.element) { index, parameter in
                    scoreRow(parameter, index: index)
                }
            }

            Button(action: onContinue) {
                Text("Continue")
                    .mocoText(MocoScreenTheme.Typeface.cardTitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Capsule().fill(DebriefStyle.deepGreen))
                    .shadow(color: DebriefStyle.deepGreen.opacity(0.25), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(DebriefPressStyle())
        }
        .padding(18)
        .mocoCard(fill: MocoScreenTheme.Colors.surfaceLavender)
        .animation(.spring(response: 0.55, dampingFraction: 0.7), value: animate)
        .onAppear {
            animate = true
        }
    }

    private func scoreRow(_ parameter: DebriefParameter, index: Int) -> some View {
        let value = result.scores[parameter] ?? 0

        return HStack(spacing: 10) {
            Image(systemName: parameter.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(parameter.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(parameter.tint))

            Text(parameter.rawValue)
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundColor(DebriefStyle.title)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DebriefStyle.sand.opacity(0.9))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [parameter.tint, parameter.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (animate ? Double(value) / 100 : 0))
                        .animation(.easeOut(duration: 0.9).delay(0.25 + Double(index) * 0.12), value: animate)
                }
            }
            .frame(height: 7)

            Text("\(value)")
                .mocoText(MocoScreenTheme.Typeface.slider)
                .monospacedDigit()
                .foregroundColor(DebriefStyle.green)
                .frame(width: 30, alignment: .trailing)
        }
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
        MocoBackdrop()

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
