import SwiftUI
import SwiftData

// MARK: - Chat model

private enum ChatRole { case moko, user }
private enum ChatKind { case text, summary, crisis }
private enum ChatPhase { case chatting, summary, crisis }

private struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    var text: String
    var kind: ChatKind = .text
    /// Moko messages type themselves out when this is true.
    var animate: Bool = false
}

// MARK: - Debrief (chat style)

struct MokoDebriefView: View {
    let quest: Quest
    let onExit: (DebriefOutcome) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var sessions: [DebriefSession]
    @Query private var profiles: [Profile]
    @Query private var missionResults: [MissionResult]

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var answers: [String] = []
    @State private var lastQuestion = "What happened?"
    @State private var proposal = MokoScoreProposal.manual
    @State private var session: DebriefSession?
    @State private var phase: ChatPhase = .chatting
    @State private var isTyping = false
    @State private var isBusy = false
    @State private var didStart = false
    @State private var scoresUnavailable = false
    @State private var reportingSkill: MokoSkill?
    @State private var reportNote = ""
    @State private var confirmSkip = false
    @FocusState private var inputFocused: Bool

    private let generator: any MokoDebriefGenerating = MokoDebriefAFM()
    private let maxCharacters = 400
    private let totalAnswers = 3

    private var level: Int { max(0, profiles.first?.xp ?? 0) / 400 + 1 }
    private var sessionCount: Int { missionResults.count }
    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isBusy && phase == .chatting
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        questChip
                        ForEach(messages) { message in
                            row(message)
                        }
                        if isTyping {
                            HStack(alignment: .bottom, spacing: 8) {
                                MokoCostumeAvatar(level: level, photoData: nil, size: 30)
                                TypingBubble()
                                Spacer(minLength: 36)
                            }
                            .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in scrollToBottom(proxy) }
                .onChange(of: isTyping) { _, _ in scrollToBottom(proxy) }
                .onChange(of: inputFocused) { _, _ in scrollToBottom(proxy) }
            }
            .background(AppBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            .navigationTitle("Debrief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { confirmSkip = true }
                        .disabled(phase == .crisis)
                }
            }
            .confirmationDialog("Skip this debrief?", isPresented: $confirmSkip, titleVisibility: .visible) {
                Button("Skip debrief", role: .destructive) { skip() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("You'll still get completion XP, but no scores will be saved.")
            }
            .sheet(item: $reportingSkill) { skill in
                NavigationStack {
                    Form {
                        TextField("What looks wrong?", text: $reportNote, axis: .vertical)
                        Button("Send report") {
                            context.insert(ScoreReport(sessionId: ensureSession().id, skill: skill, note: reportNote))
                            try? context.save()
                            reportNote = ""
                            reportingSkill = nil
                        }
                    }
                    .navigationTitle("Report a score")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { reportingSkill = nil }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: messages.count)
            .task { await start() }
        }
    }

    // MARK: Rows

    private var questChip: some View {
        Text("\(quest.title) · \(quest.category.rawValue) · \(quest.date.formatted(date: .abbreviated, time: .omitted))")
            .font(.caption.weight(.medium))
            .foregroundStyle(MokoTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.7), in: Capsule())
            .padding(.bottom, 4)
    }

    @ViewBuilder
    private func row(_ message: ChatMessage) -> some View {
        switch message.kind {
        case .text:
            HStack(alignment: .bottom, spacing: 8) {
                if message.role == .moko {
                    MokoCostumeAvatar(level: level, photoData: nil, size: 30)
                    ChatBubble(text: message.text, role: .moko, animate: message.animate && !reduceMotion)
                    Spacer(minLength: 36)
                } else {
                    Spacer(minLength: 56)
                    ChatBubble(text: message.text, role: .user, animate: false)
                }
            }
            .transition(
                .scale(scale: 0.85, anchor: message.role == .user ? .bottomTrailing : .bottomLeading)
                    .combined(with: .opacity)
                    .combined(with: .move(edge: .bottom))
            )
        case .summary:
            ScoreSummaryCard(
                proposal: proposal,
                unavailable: scoresUnavailable,
                headline: sessionCount == 0 ? "Baseline set. Your starting point." : "Compared with your own recent sessions.",
                onReport: { reportingSkill = $0 }
            )
            .transition(.scale(scale: 0.94, anchor: .top).combined(with: .opacity))
        case .crisis:
            crisisCard
                .transition(.scale(scale: 0.94, anchor: .top).combined(with: .opacity))
        }
    }

    private var crisisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You deserve support right now").font(.title3.bold())
            Text("Moko cannot provide crisis support. If you may be in immediate danger, contact local emergency services or someone you trust. In India, Tele-MANAS is available at 14416.")
                .font(.subheadline)
            Button("Close") { onExit(.leave) }
                .buttonStyle(.borderedProminent)
                .tint(MokoTheme.forestGreen)
                .frame(minHeight: 44)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        switch phase {
        case .chatting: inputBar
        case .summary: summaryBar
        case .crisis: EmptyView()
        }
    }

    private var inputBar: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField(isBusy ? "Moko is typing…" : "Type your reply…", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .disabled(isBusy)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
                    .onChange(of: draft) { _, value in
                        if value.count > maxCharacters { draft = String(value.prefix(maxCharacters)) }
                    }

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(MokoTheme.forestGreen.opacity(canSend ? 1 : 0.3), in: Circle())
                        .scaleEffect(canSend ? 1 : 0.92)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
                }
                .disabled(!canSend)
                .accessibilityLabel("Send")
            }
            if draft.count > maxCharacters - 100 {
                Text("\(draft.count)/\(maxCharacters)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var summaryBar: some View {
        Button {
            if scoresUnavailable { skip() } else { save() }
        } label: {
            Text(scoresUnavailable ? "Finish" : "Save")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(MokoTheme.forestGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.28)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    // MARK: Conversation flow

    @MainActor
    private func start() async {
        guard !didStart else { return }
        didStart = true
        isBusy = true

        if let stored = sessions.first(where: { $0.questId == quest.id && $0.status == .inProgress }),
           !stored.turns.isEmpty {
            // Rebuild the chat from the saved turns, then carry on
            session = stored
            let turns = stored.turns.sorted { $0.index < $1.index }
            answers = turns.map(\.answer)
            for turn in turns {
                if !turn.question.isEmpty { messages.append(ChatMessage(role: .moko, text: turn.question)) }
                messages.append(ChatMessage(role: .user, text: turn.answer))
            }
            await say("Welcome back. Let's pick up where we left off.")
            if answers.count >= totalAnswers { await finishWithScores() } else { await askFollowUp() }
        } else {
            if let stored = sessions.first(where: { $0.questId == quest.id && $0.status == .inProgress }) {
                session = stored
            }
            await say("Hi! Let's look back at “\(quest.title)”.")
            await say("What happened? Tell me in your own words. A few sentences is plenty.")
            lastQuestion = "What happened?"
        }

        isBusy = false
        inputFocused = phase == .chatting
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isBusy, phase == .chatting else { return }
        draft = ""
        isBusy = true
        Task { await handleUserAnswer(text) }
    }

    @MainActor
    private func handleUserAnswer(_ text: String) async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages.append(ChatMessage(role: .user, text: text))
        }
        appendAnswer(text, question: lastQuestion)

        if MokoAFMPolicy.containsCrisisLanguage(answers.joined(separator: " ")) {
            await showCrisis()
            isBusy = false
            return
        }

        if answers.count >= totalAnswers {
            await finishWithScores()
        } else {
            await askFollowUp()
        }

        isBusy = false
        if phase == .chatting { inputFocused = true }
    }

    @MainActor
    private func askFollowUp() async {
        let s = ensureSession()
        startTyping()
        let all = answers.joined(separator: " ")
        let tokens = MokoDebriefTokenizer.tokenize(all)
        let response = await generator.followUp(
            tokens: tokens.words,
            questTitle: quest.title,
            category: quest.category.rawValue,
            rule: MokoDebriefRules.rule(for: tokens)
        )
        s.source = response.source
        await say(response.question)
        lastQuestion = response.question
    }

    @MainActor
    private func finishWithScores() async {
        let s = ensureSession()
        startTyping()
        let all = answers.joined(separator: " ")
        let tokens = MokoDebriefTokenizer.tokenize(all)
        let response = await generator.scores(
            tokens: tokens,
            answers: all,
            questTitle: quest.title,
            category: quest.category.rawValue,
            sevenDayAverage: sevenDayAverage
        )
        if let value = response.proposal {
            proposal = value
            s.source = response.source
        } else {
            scoresUnavailable = true
        }
        await say(scoresUnavailable
                  ? "I can't score this one on this device, but your reflection still counts."
                  : "Thank you for sharing that. Here's how it looked.")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            messages.append(ChatMessage(role: .moko, text: "", kind: .summary))
            phase = .summary
        }
        inputFocused = false
    }

    @MainActor
    private func showCrisis() async {
        await say("I'm really glad you told me. I want to make sure you have support.")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            messages.append(ChatMessage(role: .moko, text: "", kind: .crisis))
            phase = .crisis
        }
        inputFocused = false
    }

    // MARK: Typing helpers

    @MainActor
    private func startTyping() {
        guard !isTyping else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isTyping = true }
    }

    /// Shows the typing dots, then the message, then waits while it types itself out.
    @MainActor
    private func say(_ text: String) async {
        startTyping()
        let thinking = reduceMotion ? 250 : min(1400, 500 + text.count * 12)
        try? await Task.sleep(for: .milliseconds(thinking))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isTyping = false
            messages.append(ChatMessage(role: .moko, text: text, animate: true))
        }
        AccessibilityNotification.Announcement(text).post()
        if !reduceMotion {
            try? await Task.sleep(for: .milliseconds(text.count * 22 + 150))
        }
    }

    // MARK: Persistence (same behaviour as before)

    private var sevenDayAverage: [MokoSkill: Double] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        let rows = missionResults.filter { $0.date >= cutoff }
        guard !rows.isEmpty else { return [:] }
        let n = Double(rows.count)
        return [
            .courage: Double(rows.map(\.courage).reduce(0, +)) / n / 20,
            .clarity: Double(rows.map(\.clarity).reduce(0, +)) / n / 20,
            .presence: Double(rows.map(\.presence).reduce(0, +)) / n / 20,
            .warmth: Double(rows.map(\.warmth).reduce(0, +)) / n / 20
        ]
    }

    private func ensureSession() -> DebriefSession {
        if let session { return session }
        let new = DebriefSession(quest: quest)
        context.insert(new)
        session = new
        return new
    }

    private func appendAnswer(_ text: String, question: String) {
        let s = ensureSession()
        let turn = DebriefTurn(index: s.turns.count, question: question, answer: text, session: s)
        context.insert(turn)
        s.turns.append(turn)
        answers.append(text)
        s.tokens = MokoDebriefTokenizer.tokenize(answers.joined(separator: " ")).words
        try? context.save()
    }

    private func save() {
        let s = ensureSession()
        let values = proposal.values
        let alreadySaved = (try? context.fetch(FetchDescriptor<MissionResult>()).contains(where: { $0.sessionId == s.id })) == true
        guard !alreadySaved else { onExit(.completed); return }

        let xp = DebriefXP.completion + DebriefXP.finished + max(0, s.turns.count - 1) * DebriefXP.followUp
        for skill in MokoSkill.allCases {
            context.insert(SkillScore(
                sessionId: s.id,
                skill: skill,
                level: values[skill] ?? 1,
                evidence: proposal.evidence[skill] ?? "No clear evidence",
                nextStep: proposal.nextSteps[skill] ?? "Notice one concrete detail next time.",
                capReason: proposal.capReasons[skill] ?? nil,
                judgeRuns: proposal.judgeRuns
            ))
        }
        context.insert(MissionResult(session: s, xpEarned: xp, scores: values))
        context.insert(InsightsModel(
            courage: (values[.courage] ?? 1) * 20,
            clarity: (values[.clarity] ?? 1) * 20,
            presence: (values[.presence] ?? 1) * 20,
            warmth: (values[.warmth] ?? 1) * 20,
            date: .now
        ))
        if let profile = profiles.first {
            profile.xp += xp
            profile.updatedAt = .now
        }
        s.status = .saved
        s.completedAt = .now
        quest.isCompleted = true
        quest.completedAt = .now
        try? context.save()
        onExit(.completed)
    }

    private func skip() {
        let s = ensureSession()
        guard s.status != .skipped else { onExit(.completed); return }
        if let profile = profiles.first {
            profile.xp += DebriefXP.completion
            profile.updatedAt = .now
        }
        s.status = .skipped
        s.completedAt = .now
        quest.isCompleted = true
        quest.completedAt = .now
        try? context.save()
        onExit(.completed)
    }
}

// MARK: - Bubble (types itself out)

private struct ChatBubble: View {
    let text: String
    let role: ChatRole
    let animate: Bool

    @State private var shown: Int

    init(text: String, role: ChatRole, animate: Bool) {
        self.text = text
        self.role = role
        self.animate = animate
        _shown = State(initialValue: animate ? 0 : text.count)
    }

    private var isUser: Bool { role == .user }

    var body: some View {
        // The full text is laid out invisibly so the bubble never resizes while typing
        label(text)
            .opacity(0)
            .overlay(alignment: .topLeading) {
                label(String(text.prefix(shown)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: isUser ? 18 : 4,
                    bottomTrailingRadius: isUser ? 4 : 18,
                    topTrailingRadius: 18,
                    style: .continuous
                )
                .fill(isUser ? MokoTheme.forestGreen : Color.white)
            )
            .shadow(color: .black.opacity(isUser ? 0 : 0.04), radius: 4, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(isUser ? "You" : "Moko"): \(text)")
            .task {
                guard animate else { return }
                for index in 1...max(1, text.count) {
                    shown = index
                    try? await Task.sleep(for: .milliseconds(22))
                    if Task.isCancelled { shown = text.count; return }
                }
            }
    }

    private func label(_ string: String) -> some View {
        Text(string)
            .font(.body)
            .foregroundStyle(isUser ? Color.white : MokoTheme.titleBrown)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Typing indicator

private struct TypingBubble: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    let wave = reduceMotion ? 0.0 : sin(t * 5 - Double(index) * 0.8)
                    Circle()
                        .fill(MokoTheme.textSecondary)
                        .frame(width: 8, height: 8)
                        .offset(y: -3 * max(0, wave))
                        .opacity(0.45 + 0.55 * (wave + 1) / 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        .accessibilityLabel("Moko is typing")
    }
}

// MARK: - Summary card inside the chat

private struct ScoreSummaryCard: View {
    let proposal: MokoScoreProposal
    let unavailable: Bool
    let headline: String
    let onReport: (MokoSkill) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your summary")
                .font(.title3.bold())
                .foregroundStyle(MokoTheme.titleBrown)

            if unavailable {
                Text("Scores need Apple Intelligence on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(Array(MokoSkill.allCases.enumerated()), id: \.offset) { index, skill in
                    let level = proposal.values[skill] ?? 1
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(skill.title).font(.headline)
                            Spacer()
                            Text("Level \(level)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MokoTheme.forestGreen)
                        }
                        LevelPips(level: level, delay: Double(index) * 0.15)
                        Text("Why: “\(proposal.evidence[skill] ?? "No clear evidence")”")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("To reach the next level: \(proposal.nextSteps[skill] ?? "Notice one concrete detail next time.")")
                            .font(.caption)
                        Button("Report a wrong score") { onReport(skill) }
                            .font(.caption)
                            .frame(minHeight: 36)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct LevelPips: View {
    let level: Int
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filled = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { index in
                Capsule()
                    .fill(index <= filled ? MokoTheme.forestGreen : MokoTheme.forestGreen.opacity(0.15))
                    .frame(height: 8)
            }
        }
        .accessibilityHidden(true)
        .task {
            let target = max(1, min(5, level))
            if reduceMotion { filled = target; return }
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000) + 250))
            for index in 1...target {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { filled = index }
                try? await Task.sleep(for: .milliseconds(110))
            }
        }
    }
}
