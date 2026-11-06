import SwiftUI
import SwiftData

struct MokoDebriefView: View {
    let quest: Quest
    let onExit: (DebriefOutcome) -> Void
    @Environment(\.modelContext) private var context
    @Query private var sessions: [DebriefSession]
    @Query private var profiles: [Profile]
    @Query private var missionResults: [MissionResult]
    @State private var step = 1
    @State private var answer = ""
    @State private var followUps: [String] = []
    @State private var answers: [String] = []
    @State private var proposal = MokoScoreProposal.manual
    @State private var session: DebriefSession?
    @State private var crisis = false
    @State private var isWorking = false
    @State private var scoresUnavailable = false
    @State private var reportingSkill: MokoSkill?
    @State private var reportNote = ""
    private let generator: any MokoDebriefGenerating = MokoDebriefAFM()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Debrief").font(.largeTitle.bold()).foregroundStyle(MokoTheme.titleBrown)
                    Text("\(quest.title) · \(quest.category.rawValue) · \(quest.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if crisis { crisisCard } else { content }
                }.padding(16)
            }
            .background(AppBackground())
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Skip") { skip() } }; ToolbarItem(placement: .topBarTrailing) { Button("Back") { back() }.disabled(step == 1) } }
            .sheet(item: $reportingSkill) { skill in
                NavigationStack { Form { TextField("What looks wrong?", text: $reportNote, axis: .vertical); Button("Send report") { context.insert(ScoreReport(sessionId: ensureSession().id, skill: skill, note: reportNote)); try? context.save(); reportingSkill = nil } }.navigationTitle("Report a score") }
            }
            .task { resume() }
        }
    }

    @ViewBuilder private var content: some View {
        if step == 1 { reflectionStep }
        else if step == 2 { followUpStep }
        else { scoreStep }
    }
    private var reflectionStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What happened?").font(.title2.bold())
            Text("Write it out or paste a voice transcript. Your reflection stays on this device unless sync is enabled.").foregroundStyle(.secondary)
            TextEditor(text: $answer).frame(minHeight: 160).padding(8).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: answer) { _, value in if value.count > 400 { answer = String(value.prefix(400)) } }
            Text("\(answer.count)/400").font(.caption).foregroundStyle(.secondary)
            Button("Continue") { beginFollowUps() }.buttonStyle(.borderedProminent).frame(minHeight: 44).disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
        }
    }
    private var followUpStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A little more context").font(.title2.bold())
            Text(followUps.first ?? "What stands out most from that moment?").font(.headline)
            TextEditor(text: $answer).frame(minHeight: 150).padding(8).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            Button(followUps.count >= 2 ? "See summary" : "Continue") { nextFollowUp() }.buttonStyle(.borderedProminent).frame(minHeight: 44).disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
        }
    }
    private var scoreStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your summary").font(.title2.bold())
            if scoresUnavailable { Text("Scores need Apple Intelligence on this device.").foregroundStyle(.secondary) }
            else { Text(sessionCount == 0 ? "Baseline set. Your starting point." : comparisonLabel).foregroundStyle(.secondary) }
            ForEach(MokoSkill.allCases) { skill in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(skill.title): Level \(proposal.values[skill] ?? 1)").font(.headline)
                    Text("Why: “\(proposal.evidence[skill] ?? "No clear evidence")”").font(.caption).foregroundStyle(.secondary)
                    Text("To reach the next level: \(proposal.nextSteps[skill] ?? "Notice one concrete detail next time.")").font(.caption)
                    Button("Report a wrong score") { reportingSkill = skill }.font(.caption).frame(minHeight: 44)
                }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            if !scoresUnavailable { Button("Save") { save() }.buttonStyle(.borderedProminent).frame(minHeight: 44) }
        }
    }
    private var crisisCard: some View { VStack(alignment: .leading, spacing: 12) { Text("You deserve support right now").font(.title2.bold()); Text("Moko cannot provide crisis support. If you may be in immediate danger, contact local emergency services or someone you trust. In India, Tele-MANAS is available at 14416."); Button("Close") { onExit(.leave) }.buttonStyle(.borderedProminent) }.padding(16).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)) }
    private var sessionCount: Int { missionResults.count }
    private var comparisonLabel: String { "Compared with your own recent sessions." }
    private func resume() { if let stored = sessions.first(where: { $0.questId == quest.id && $0.status == .inProgress }) { session = stored; answers = stored.turns.sorted { $0.index < $1.index }.map(\.answer); if !answers.isEmpty { step = min(3, answers.count + 1) } } }
    private func beginFollowUps() { appendAnswer(answer, question: "What happened?"); answer = ""; Task { await makeFollowUp() } }
    private func nextFollowUp() { appendAnswer(answer, question: followUps.first ?? ""); answer = ""; if answers.count >= 3 { Task { await makeScores() } } else { Task { await makeFollowUp() } } }
    private func appendAnswer(_ text: String, question: String) { let s = ensureSession(); let turn = DebriefTurn(index: s.turns.count, question: question, answer: text, session: s); context.insert(turn); s.turns.append(turn); answers.append(text); s.tokens = MokoDebriefTokenizer.tokenize(answers.joined(separator: " ")).words }
    private func makeFollowUp() async { let s = ensureSession(); let all = answers.joined(separator: " "); if MokoAFMPolicy.containsCrisisLanguage(all) { crisis = true; return }; isWorking = true; let tokens = MokoDebriefTokenizer.tokenize(all); let response = await generator.followUp(tokens: tokens.words, questTitle: quest.title, category: quest.category.rawValue, rule: MokoDebriefRules.rule(for: tokens)); s.source = response.source; followUps = [response.question]; step = 2; isWorking = false }
    private func makeScores() async { let s = ensureSession(); isWorking = true; let tokens = MokoDebriefTokenizer.tokenize(answers.joined(separator: " ")); let response = await generator.scores(tokens: tokens, answers: answers.joined(separator: " "), questTitle: quest.title, category: quest.category.rawValue, sevenDayAverage: sevenDayAverage); if let value = response.proposal { proposal = value; s.source = response.source } else { scoresUnavailable = true }; step = 3; isWorking = false }
    private var sevenDayAverage: [MokoSkill: Double] { let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast; let rows = missionResults.filter { $0.date >= cutoff }; guard !rows.isEmpty else { return [:] }; return [.courage: Double(rows.map(\.courage).reduce(0, +)) / Double(rows.count) / 20, .clarity: Double(rows.map(\.clarity).reduce(0, +)) / Double(rows.count) / 20, .presence: Double(rows.map(\.presence).reduce(0, +)) / Double(rows.count) / 20, .warmth: Double(rows.map(\.warmth).reduce(0, +)) / Double(rows.count) / 20] }
    private func ensureSession() -> DebriefSession { if let session { return session }; let new = DebriefSession(quest: quest); context.insert(new); session = new; return new }
    private func save() { let s = ensureSession(); let values = proposal.values; guard (try? context.fetch(FetchDescriptor<MissionResult>()).contains(where: { $0.sessionId == s.id })) != true else { onExit(.completed); return }; let xp = DebriefXP.completion + DebriefXP.finished + max(0, s.turns.count - 1) * DebriefXP.followUp; for skill in MokoSkill.allCases { context.insert(SkillScore(sessionId: s.id, skill: skill, level: values[skill] ?? 1, evidence: proposal.evidence[skill] ?? "No clear evidence", nextStep: proposal.nextSteps[skill] ?? "Notice one concrete detail next time.", capReason: proposal.capReasons[skill] ?? nil, judgeRuns: proposal.judgeRuns)) }; context.insert(MissionResult(session: s, xpEarned: xp, scores: values)); context.insert(InsightsModel(courage: (values[.courage] ?? 1) * 20, clarity: (values[.clarity] ?? 1) * 20, presence: (values[.presence] ?? 1) * 20, warmth: (values[.warmth] ?? 1) * 20, date: .now)); if let profile = profiles.first { profile.xp += xp; profile.updatedAt = .now }; s.status = .saved; s.completedAt = .now; quest.isCompleted = true; quest.completedAt = .now; try? context.save(); onExit(.completed) }
    private func skip() { let s = ensureSession(); guard s.status != .skipped else { onExit(.completed); return }; if let profile = profiles.first { profile.xp += DebriefXP.completion; profile.updatedAt = .now }; s.status = .skipped; s.completedAt = .now; quest.isCompleted = true; quest.completedAt = .now; try? context.save(); onExit(.completed) }
    private func back() { if step > 1 { step -= 1 } }
}
