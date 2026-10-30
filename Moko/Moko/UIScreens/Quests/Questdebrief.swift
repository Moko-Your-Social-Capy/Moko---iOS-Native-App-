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
import Observation

// MARK: - Where the user ends up
enum DebriefOutcome {
    case completed      // finished the debrief, tapped Continue
    case finishLater    // stepped away, saved to resume
    case leave          // left, streak kept
}

// MARK: - Style
enum DebriefStyle {
    static let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)  // #F2F2F7
    static let green = Color(red: 54/255, green: 89/255, blue: 72/255)        // #365948
    static let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    static let title = Color(red: 47/255, green: 42/255, blue: 40/255)        // #2F2A28
    static let subtext = Color(red: 111/255, green: 103/255, blue: 98/255)    // #6F6762
    static let cream = Color(red: 251/255, green: 247/255, blue: 238/255)
    static let border = Color(red: 234/255, green: 224/255, blue: 204/255)
    static let sand = Color(red: 233/255, green: 226/255, blue: 210/255)
    static let rust = Color(red: 176/255, green: 78/255, blue: 58/255)
    static let mint = Color(red: 203/255, green: 230/255, blue: 211/255)
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
}

protocol DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String
    /// number is 1...3
    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion
    /// focus is nil for the opening story
    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade
}

/// Placeholder coach with fixed questions and made-up scores.
struct DummyDebriefCoach: DebriefCoaching {
    func greeting(for context: DebriefContext) async -> String {
        try? await Task.sleep(for: .milliseconds(1000))
        return "Welcome back! How did \(context.questTitle) go? Tell me what happened, in your own words."
    }

    func question(number: Int, context: DebriefContext, previousAnswers: [String]) async -> DebriefQuestion {
        try? await Task.sleep(for: .milliseconds(1200))

        switch number {
        case 1:
            return DebriefQuestion(
                text: "You said it got quiet for a bit. In that moment, were you listening to them, or thinking about what to say next?",
                focus: .presence
            )
        case 2:
            return DebriefQuestion(
                text: "What’s one question you asked because you were genuinely curious? How did they respond?",
                focus: .clarity
            )
        default:
            return DebriefQuestion(
                text: "Was there a moment you made them feel welcome or appreciated? What did you say or do?",
                focus: .warmth
            )
        }
    }

    func grade(answer: String, focus: DebriefParameter?, context: DebriefContext) async -> DebriefGrade {
        try? await Task.sleep(for: .milliseconds(1000))

        let words = answer.split(separator: " ").count
        let confidence = min(96, 52 + words + Int.random(in: 0...6))
        let score = min(95, 58 + words + Int.random(in: 0...8))

        let note: String
        switch focus {
        case .presence:
            note = "Honest and self-aware. Noticing your mind drift and tuning back in is real presence."
        case .clarity:
            note = "Clear and specific. Following up on what they said keeps the conversation sharp."
        case .warmth:
            note = "Warm and genuine. Saying it out loud makes people feel valued."
        default:
            note = "You showed up and spoke honestly. That takes courage."
        }

        return DebriefGrade(confidence: confidence, score: score, note: note, focus: focus)
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

    let context: DebriefContext
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

    private var answers: [String] = []
    private var grades: [DebriefGrade] = []
    private var started = false
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

        isCoachTyping = true
        let text = await coach.greeting(for: context)
        isCoachTyping = false
        append(.ai(text))
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

                self.isCoachTyping = true
                let next = await self.coach.question(
                    number: self.questionNumber,
                    context: self.context,
                    previousAnswers: self.answers
                )
                guard !Task.isCancelled else { return }
                self.isCoachTyping = false
                self.focus = next.focus
                self.append(.ai(next.text))
            } else {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                self.finish()
            }
        }
    }

    private func apply(_ grade: DebriefGrade, to id: UUID?) {
        grades.append(grade)

        guard let id, let index = messages.firstIndex(where: { $0.id == id }) else { return }
        if case .user(let text, _) = messages[index].kind {
            withAnimation(.easeOut(duration: 0.4)) {
                messages[index].kind = .user(text: text, grade: grade)
            }
        }
    }

    private func finish() {
        var scores: [DebriefParameter: Int] = [:]

        // Each follow-up grades the parameter it asked about
        for grade in grades {
            if let focus = grade.focus {
                scores[focus] = grade.score
            }
        }

        // Courage is the average of how confident each answer came across
        let confidences = grades.map { $0.confidence }
        scores[.courage] = confidences.isEmpty ? 0 : confidences.reduce(0, +) / confidences.count

        result = DebriefResult(scores: scores, xp: 50, streak: 4)
        focus = nil

        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            isComplete = true
        }
    }

    func cancelAll() {
        recordingTask?.cancel()
        flowTask?.cancel()
    }

    private func append(_ kind: DebriefMessage.Kind) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            messages.append(DebriefMessage(kind: kind))
        }
    }
}

// MARK: - The screen
struct QuestDebriefScreen: View {
    var onExit: (DebriefOutcome) -> Void

    @State private var session: DebriefSession
    @State private var draft = ""
    @State private var showLeave = false
    @FocusState private var isTyping: Bool

    init(context: DebriefContext,
         coach: any DebriefCoaching = DummyDebriefCoach(),
         onExit: @escaping (DebriefOutcome) -> Void) {
        _session = State(initialValue: DebriefSession(context: context, coach: coach))
        self.onExit = onExit
    }

    init(quest: Quest,
         coach: any DebriefCoaching = DummyDebriefCoach(),
         onExit: @escaping (DebriefOutcome) -> Void) {
        self.init(
            context: DebriefContext(
                questTitle: quest.title,
                category: quest.category,
                intensity: quest.intensity
            ),
            coach: coach,
            onExit: onExit
        )
    }

    private var unsentText: String? {
        if session.isRecording { return "Unsent audio (\(session.timeText)) will be discarded" }
        if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Your unsent answer will be discarded" }
        return nil
    }

    var body: some View {
        ZStack {
            DebriefStyle.screenBg.ignoresSafeArea()

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
                onFinishLater: { onExit(.finishLater) },
                onLeave: { onExit(.leave) }
            )
        }
        .task {
            await session.start()
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

    // MARK: Header
    private var focusLabel: String {
        if session.isComplete { return "Complete" }
        return session.focus?.rawValue ?? "Your story"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debrief Time")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(DebriefStyle.title)

            (Text("\(session.context.questTitle) · ")
                .foregroundColor(DebriefStyle.subtext)
             + Text(focusLabel)
                .foregroundColor(DebriefStyle.green)
                .fontWeight(.semibold))
                .font(.system(size: 14))
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
        .padding(.horizontal, 24)
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
        .padding(.horizontal, 20)
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
                    onExit(.completed)
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
        .padding(.horizontal, 16)
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
                .font(.system(size: 16))
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
                    .frame(width: 42, height: 42)
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
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(DebriefStyle.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
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
                    .frame(width: 42, height: 42)
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
                    .frame(width: 42, height: 42)
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
                    .frame(width: 42, height: 42)
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

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text(text).opacity(0) // reserves the final size so the bubble doesn't jump
                Text(String(text.prefix(shownCount)))
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(DebriefStyle.title)
            .lineSpacing(3)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)

            Spacer(minLength: 44)
        }
        .task {
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
                    .font(.system(size: 15, weight: .medium))
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
            .background(DebriefStyle.cream)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DebriefStyle.subtext)

                meterBar

                if let grade {
                    Text("\(grade.confidence)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DebriefStyle.green)
                        .monospacedDigit()
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DebriefStyle.green)
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
                .font(.system(size: 13))
                .foregroundColor(DebriefStyle.subtext)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let focus = grade.focus {
                    HStack(spacing: 6) {
                        Image(systemName: focus.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(focus.rawValue) \(grade.score)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(focus.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Capsule().fill(focus.tint))
                } else {
                    Text("Your story")
                        .font(.system(size: 12, weight: .semibold))
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
            Text("FOLLOW-UP QUESTIONS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.1)
                .foregroundColor(DebriefStyle.rust)

            Spacer()

            Text("Question \(number) of \(total)")
                .font(.system(size: 12, weight: .semibold))
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
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().stroke(DebriefStyle.border, lineWidth: 1))

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
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
                }
                .buttonStyle(DebriefPressStyle())
                .accessibilityLabel("Stop and send")

                waveform

                Text(elapsed)
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(DebriefStyle.subtext)
            }

            // Live transcript with a blinking caret
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let caretOn = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0

                (Text(transcript.isEmpty ? "Listening…" : transcript)
                    .foregroundColor(transcript.isEmpty ? DebriefStyle.subtext : DebriefStyle.title)
                 + Text(" ▏").foregroundColor(caretOn ? DebriefStyle.green : Color.clear))
                    .font(.system(size: 15, weight: .medium))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(DebriefStyle.cream)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    /// Newest sound on the right, older sound fading to sand on the left
    private var waveform: some View {
        HStack(spacing: 3) {
            ForEach(levels.indices, id: \.self) { index in
                let age = Double(index) / Double(max(levels.count - 1, 1))

                Capsule()
                    .fill(age > 0.6 ? DebriefStyle.green : Color(red: 196/255, green: 176/255, blue: 140/255))
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

            DebriefDottedRing(count: 18, radius: 47, color: Color(red: 120/255, green: 165/255, blue: 140/255))
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
                        colors: [Color(red: 96/255, green: 162/255, blue: 140/255), DebriefStyle.deepGreen],
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
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DebriefStyle.cream))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Leave debrief early?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DebriefStyle.title)

                    Text("Take a breath. No penalty for stepping away.")
                        .font(.system(size: 13))
                        .foregroundColor(DebriefStyle.subtext)
                }
            }

            if let unsentText {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 232/255, green: 120/255, blue: 60/255))
                        .frame(width: 6, height: 6)

                    Text(unsentText)
                        .font(.system(size: 12, weight: .medium))
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
                    subtitle: "Resume your debrief",
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
        .presentationBackground(Color.white)
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(titleColor)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(subtitleColor)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(style == .primary ? Color.clear : DebriefStyle.border, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DebriefStyle.title)

                        Text("+\(result.xp) XP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DebriefStyle.green)
                            .padding(.horizontal, 9)
                            .frame(height: 24)
                            .background(Capsule().fill(DebriefStyle.mint.opacity(0.7)))
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Capsule().fill(DebriefStyle.deepGreen))
                    .shadow(color: DebriefStyle.deepGreen.opacity(0.25), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(DebriefPressStyle())
        }
        .padding(18)
        .background(DebriefStyle.cream)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
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
                .font(.system(size: 13, weight: .semibold))
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
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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
        DebriefStyle.screenBg.ignoresSafeArea()

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
