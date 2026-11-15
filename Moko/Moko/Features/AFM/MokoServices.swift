//
//  MokoServices.swift
//  Moko
//
//  Glue between the app and AFM (Apple Foundation Models, the on-device AI):
//    1) Onboarding: plain-Swift scoring + AFM-written insight text
//    2) Quest cards (custom + daily): AFM writes title/scene/who/goal,
//       the app decides difficulty and the category image
//    3) Mission planner: a custom quest → one practice mission per day until its date
//    4) Voice debrief: a fixed-length question flow (NOT an open chatbot)
//
//  Rule used everywhere: every AFM call has a plain-text fallback, so the app
//  still works on devices without Apple Intelligence (AFM returns nil there).
//

import Foundation
import Observation

// MARK: 1) ONBOARDING

/// One onboarding answer, ready for scoring.
struct OnboardingScoredAnswer: Codable, Equatable, Sendable {
    let questionID: Int   // 1...8
    let yes: Bool         // every question is phrased so that "yes" = the harder behavior
}

/// The four social stats, each 0–100.
struct StatScores: Codable, Equatable, Sendable {
    var courage = 0, clarity = 0, presence = 0, warmth = 0

    /// Lets code read or write a stat by name, e.g. `scores[.warmth] = 70`.
    subscript(_ stat: Stat) -> Int {
        get {
            switch stat {
            case .courage: return courage
            case .clarity: return clarity
            case .presence: return presence
            case .warmth: return warmth
            }
        }
        set {
            switch stat {
            case .courage: courage = newValue
            case .clarity: clarity = newValue
            case .presence: presence = newValue
            case .warmth: warmth = newValue
            }
        }
    }

    var overall: Int { Int((Double(courage + clarity + presence + warmth) / 4).rounded()) }

    /// Blend a finished debrief into the running profile (simple moving average).
    func updated(with session: [Stat: Int], weight: Double = 0.3) -> StatScores {
        var out = self
        for (stat, value) in session {
            out[stat] = Int((Double(self[stat]) * (1 - weight) + Double(value) * weight).rounded())
        }
        return out
    }

    /// Same as above, for scores keyed by debrief parameter instead of stat.
    func updated(with sessionParameters: [DebriefParameter: Int], weight: Double = 0.3) -> StatScores {
        var dict: [Stat: Int] = [:]
        for (param, val) in sessionParameters {
            dict[param.stat] = val
        }
        return updated(with: dict, weight: weight)
    }

    init(courage: Int = 0, clarity: Int = 0, presence: Int = 0, warmth: Int = 0) {
        self.courage = courage
        self.clarity = clarity
        self.presence = presence
        self.warmth = warmth
    }

    /// Reads the scores out of a saved SwiftData `InsightsModel`.
    init(model: InsightsModel) {
        self.courage = model.courage
        self.clarity = model.clarity
        self.presence = model.presence
        self.warmth = model.warmth
    }

    /// Makes a new `InsightsModel` you can insert into SwiftData.
    func makeInsightsModel(date: Date = .now) -> InsightsModel {
        InsightsModel(courage: courage, clarity: clarity, presence: presence, warmth: warmth, date: date)
    }
}

/// Which "band" a score falls into: 70+ strength, 50–69 steady, below 50 growth.
enum Band {
    case strength, steady, growth
    init(score: Int) { self = score >= 70 ? .strength : (score >= 50 ? .steady : .growth) }
    var label: String {
        switch self {
        case .strength: return "strength"
        case .steady: return "steady"
        case .growth: return "growth"
        }
    }
}

/// Turns the 8 yes/no onboarding answers into starting stat scores. No AI involved.
enum OnboardingScoring {
    /// Which stat a question affects, and how much (1.0 = main stat, 0.4 = side stat).
    struct Tag { let stat: Stat; let weight: Double }

    /// From "Moko — Onboarding Item Tagging". Primary = 1.0, secondary = 0.4.
    /// Q8 is only a tentative Presence item in the doc, so it counts 0.6 there until validated/reworded.
    static let tags: [Int: [Tag]] = [
        1: [.init(stat: .warmth, weight: 1),   .init(stat: .courage, weight: 0.4)],
        2: [.init(stat: .warmth, weight: 1),   .init(stat: .courage, weight: 0.4)],
        3: [.init(stat: .courage, weight: 1),  .init(stat: .clarity, weight: 0.4)],
        4: [.init(stat: .courage, weight: 1)],
        5: [.init(stat: .clarity, weight: 1),  .init(stat: .courage, weight: 0.4)],
        6: [.init(stat: .clarity, weight: 1),  .init(stat: .courage, weight: 0.4)],
        7: [.init(stat: .presence, weight: 1), .init(stat: .clarity, weight: 0.4)],
        8: [.init(stat: .presence, weight: 0.6), .init(stat: .courage, weight: 0.4), .init(stat: .clarity, weight: 0.4)],
    ]

    /// Short third-person phrasing of what a "yes" means (used only inside the AFM prompt).
    static let behaviors: [Int: String] = [
        1: "has something unsaid with a close friend or family member",
        2: "tends to keep bothering feelings to themselves even around trusted people",
        3: "tends to wait for others to speak first in groups",
        4: "has skipped a club, event or group chat over worries about fitting in",
        5: "has held back something honest in their friend group to avoid awkwardness",
        6: "finds it hard to say no to family",
        7: "replays conversations afterward, worrying they said the wrong thing",
        8: "tends to stay quiet during tension at home instead of saying how they feel",
    ]

    /// Baseline range: a self-report should never land on a hard 0 or 100.
    static let minScore = 25.0, maxScore = 90.0

    /// For each stat: add up the weight of every question tagged with it (`possible`),
    /// and the weight of the ones answered "yes" (`lost`). More "yes" → lower score,
    /// always inside `minScore...maxScore`.
    static func scores(from answers: [OnboardingScoredAnswer]) -> StatScores {
        let yes = Set(answers.filter { $0.yes }.map { $0.questionID })
        var result = StatScores()
        for stat in Stat.allCases {
            var possible = 0.0, lost = 0.0
            for (q, ts) in tags {
                for t in ts where t.stat == stat {
                    possible += t.weight
                    if yes.contains(q) { lost += t.weight }
                }
            }
            let ratio = possible > 0 ? lost / possible : 0
            result[stat] = Int((maxScore - ratio * (maxScore - minScore)).rounded())
        }
        return result
    }

    /// Convenience overload accepting the app's existing `[Int: OnboardingAnswer]` map.
    static func scores(from answers: [Int: OnboardingAnswer]) -> StatScores {
        let list = answers.map { OnboardingScoredAnswer(questionID: $0.key, yes: $0.value == .yes) }
        return scores(from: list)
    }
}

/// What onboarding hands to the Insights screen: scores plus one short text per stat.
struct OnboardingResult: Sendable {
    let scores: StatScores
    let insights: [Stat: String]   // 1–2 line analysis per stat, shown under each score in Insights
}

@MainActor
enum OnboardingInsightService {
    /// Scores the answers, then asks AFM for a 1–2 line insight per stat.
    /// Any missing, too-short or too-long AFM text is swapped for `OnboardingFallback`.
    static func analyze(_ answers: [OnboardingScoredAnswer]) async -> OnboardingResult {
        let scores = OnboardingScoring.scores(from: answers)
        // `try?` turns an AFM error into nil, so we simply fall back below.
        let generated = try? await AFM.generate(
            OnboardingInsights.self,
            instructions: OnboardingPrompts.instructions,
            prompt: OnboardingPrompts.prompt(scores: scores, answers: answers),
            temperature: 0.5
        )

        var insights: [Stat: String] = [:]
        for stat in Stat.allCases {
            let raw: String?
            switch stat {
            case .courage:  raw = generated?.courage
            case .clarity:  raw = generated?.clarity
            case .presence: raw = generated?.presence
            case .warmth:   raw = generated?.warmth
            }
            let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            insights[stat] = (text.count >= 20 && text.count <= 300)
                ? text
                : OnboardingFallback.text(stat, Band(score: scores[stat]))
        }
        return OnboardingResult(scores: scores, insights: insights)
    }

    /// Convenience overload accepting the app's existing `[Int: OnboardingAnswer]` map.
    static func analyze(_ answers: [Int: OnboardingAnswer]) async -> OnboardingResult {
        let list = answers.map { OnboardingScoredAnswer(questionID: $0.key, yes: $0.value == .yes) }
        return await analyze(list)
    }
}

/// Hand-written insight text, used when AFM is unavailable or returns something unusable.
enum OnboardingFallback {
    static func text(_ stat: Stat, _ band: Band) -> String {
        let positive = band != .growth
        switch (stat, positive) {
        case (.courage, true):   return "You tend to step toward social moments rather than away from them. That willingness is a real strength."
        case (.courage, false):  return "Stepping in can feel big, and that's very common. Try joining one small thing this week to build momentum."
        case (.clarity, true):   return "You usually say what you mean, and that makes it easy for people to understand you. Keep trusting your voice."
        case (.clarity, false):  return "Saying the honest thing can feel awkward, and that's very common. Try one short, kind sentence the next time it matters."
        case (.presence, true):  return "You stay with the conversation instead of getting lost in your head, which people feel and appreciate."
        case (.presence, false): return "It's natural to replay conversations. Next time, try noticing one detail about the other person while they talk."
        case (.warmth, true):    return "You share openly and let people in. That openness builds real closeness."
        case (.warmth, false):   return "Sharing what's on your mind can feel vulnerable. Try telling one trusted person one small thing this week."
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: 2 & 3) QUEST CARDS + DAILY MISSION PLANNER
// ═══════════════════════════════════════════════════════════════

/// What the user typed when creating a custom quest.
struct CustomQuestInput: Sendable {
    var title: String
    var notes: String
    var category: QuestCategory   // drives the card image (app-side, not AFM)
    var difficulty: Difficulty    // chosen by the user (not AFM)
    var date: Date                // the day of the real event

    init(title: String, notes: String, category: QuestCategory, difficulty: Difficulty, date: Date) {
        self.title = title
        self.notes = notes
        self.category = category
        self.difficulty = difficulty
        self.date = date
    }

    init(quest: Quest) {
        self.title = quest.title
        self.notes = quest.notes
        self.category = quest.category
        self.difficulty = Difficulty(intensity: quest.intensity)
        self.date = quest.date
    }
}

/// The text shown on a mission card.
struct QuestCard: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var templateID: String        // links the card to its Mission Bank entry → follow-up questions at debrief time
    var category: QuestCategory
    var difficulty: Difficulty
    var title: String
    var scene: String
    var who: String
    var goal: String
    var isInvented = false        // true when AFM wrote a brand-new situation (vs. rewording a bank one)
}

/// One day in a custom quest's practice plan (before AFM has written its card).
struct PlannedMission: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let template: MissionTemplate
    let dayNumber: Int
    let totalDays: Int
    let isRehearsal: Bool         // the last day before the event uses the closest template itself
}

enum MissionPlanner {
    /// Deterministic, instant. One mission per day from today up to (not including) the quest date.
    /// Ramps easy → the user's chosen difficulty inside the same category; the final day is a rehearsal
    /// of the closest bank situation. AFM only rewrites each planned day into a card, lazily.
    static func plan(for quest: CustomQuestInput,
                     matched: MissionTemplate,
                     userAge: Int? = nil,
                     today: Date = .now,
                     calendar: Calendar = .current) -> [PlannedMission] {
        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: quest.date)
        let span = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        guard span > 0 else { return [] }

        // Practice situations: same category, not harder than the user's choice, easiest first.
        var pool = MissionBank.templates(in: matched.category, age: userAge)
            .filter { $0.difficulty.rank <= quest.difficulty.rank && $0.id != matched.id }
            .sorted { $0.tierLow < $1.tierLow }
        if pool.isEmpty { pool = [matched] }

        return (0..<span).map { i -> PlannedMission in
            let isLast = i == span - 1
            let template: MissionTemplate
            if isLast {
                template = matched
            } else {
                // 0.0 on day one → 1.0 on the day before the rehearsal, so the pick walks easy → hard.
                let position = span > 2 ? Double(i) / Double(span - 2) : 0
                template = pool[Int((position * Double(pool.count - 1)).rounded())]
            }
            return PlannedMission(date: calendar.date(byAdding: .day, value: i, to: start) ?? start,
                                  template: template,
                                  dayNumber: i + 1,
                                  totalDays: span,
                                  isRehearsal: isLast)
        }
    }
}

/// Builds `QuestCard`s. Each card starts from Mission Bank text, then AFM tries to reword it.
@MainActor
enum QuestCardService {

    // Custom quest → matched bank template + card
    static func customCard(_ quest: CustomQuestInput) async -> (card: QuestCard, template: MissionTemplate) {
        let template = await closestTemplate(title: quest.title, notes: quest.notes, category: quest.category)
        let seed = CardSeed(userTitle: quest.title, userNotes: quest.notes,
                            template: template, difficulty: quest.difficulty)
        return (await makeCard(seed), template)
    }

    // One planned day → card (call lazily when that day is opened).
    // Ramp days try to INVENT a fresh, checked situation anchored on the bank template (MokoMissionInvention.swift);
    // if that fails any check, we fall back to rewording the bank situation. The rehearsal day is never invented.
    static func dailyCard(for day: PlannedMission,
                          practiceFor quest: CustomQuestInput?,
                          recentTitles: [String] = []) async -> QuestCard {
        if !day.isRehearsal,
           let invented = await MissionInventor.invent(anchor: day.template,
                                                       difficulty: day.template.difficulty,
                                                       dayNumber: day.dayNumber,
                                                       totalDays: day.totalDays,
                                                       practiceFor: quest?.title,
                                                       seed: quest?.title ?? "daily",
                                                       recentTitles: recentTitles) {
            return invented
        }
        let seed = CardSeed(userTitle: nil, userNotes: nil,
                            template: day.template, difficulty: day.template.difficulty,
                            practiceFor: quest?.title, dayNumber: day.dayNumber, totalDays: day.totalDays)
        return await makeCard(seed)
    }

    // Quest library items need no AFM for the card: the bank text is already final.
    static func libraryCard(_ t: MissionTemplate) -> QuestCard {
        QuestCard(templateID: t.id, category: t.category, difficulty: t.difficulty,
                  title: t.title, scene: t.scene, who: t.who, goal: t.goal)
    }

    // MARK: internals

    private static func closestTemplate(title: String, notes: String, category: QuestCategory) async -> MissionTemplate {
        let options = MissionBank.templates(in: category)
        guard !options.isEmpty else { return MissionBank.all[0] }

        // Plain-Swift backup pick: the option sharing the most words (3+ letters) with
        // the user's title and notes. Used only if AFM can't choose.
        var bestIndex = 0
        var bestMatchScore = 0
        let searchTokens = (title + " " + notes).lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
        for (i, opt) in options.enumerated() {
            let optText = (opt.title + " " + opt.scene + " " + opt.goal + " " + opt.who).lowercased()
            let score = searchTokens.filter { $0.count > 2 && optText.contains($0) }.count
            if score > bestMatchScore {
                bestMatchScore = score
                bestIndex = i
            }
        }

        let choice = try? await AFM.generate(
            TemplateChoice.self,
            instructions: QuestPrompts.matchInstructions,
            prompt: QuestPrompts.matchPrompt(title: title, notes: notes, options: options),
            temperature: 0.1
        )
        if let choice {
            // AFM counts from 1; clamp so a bad number can never crash the array lookup.
            let index = min(max(choice.number - 1, 0), options.count - 1)
            return options[index]
        }
        return options[bestIndex]
    }

    /// Builds the card from bank text first (the fallback), then lets AFM overwrite
    /// each field only if its version passes the length checks.
    private static func makeCard(_ seed: CardSeed) async -> QuestCard {
        let t = seed.template
        // The user's own title if they typed one, otherwise the bank title.
        let fallbackTitle: String
        if let userTitle = seed.userTitle, !userTitle.isEmpty {
            fallbackTitle = userTitle
        } else {
            fallbackTitle = t.title
        }

        var fallbackScene = t.scene
        var fallbackWho = t.who
        let fallbackGoal = t.goal

        let trimmedNotes = seed.userNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedNotes.isEmpty {
            fallbackScene = "\(trimmedNotes). \(t.scene)"
        }
        if let userTitle = seed.userTitle, !userTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fallbackWho = "\(userTitle) context: \(t.who)"
        }

        var card = QuestCard(templateID: t.id, category: t.category, difficulty: seed.difficulty,
                             title: fallbackTitle, scene: fallbackScene, who: fallbackWho, goal: fallbackGoal)

        guard let g = try? await AFM.generate(
            QuestCardText.self,
            instructions: QuestPrompts.cardInstructions,
            prompt: QuestPrompts.cardPrompt(seed),
            temperature: 0.6
        ) else { return card }

        // Returns the trimmed text, or nil if it is empty or longer than `max` characters.
        func ok(_ s: String, max: Int) -> String? {
            let v = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return (!v.isEmpty && v.count <= max) ? v : nil
        }
        if let v = ok(g.cardTitle, max: 40), v.split(separator: " ").count <= 6 { card.title = v }
        if let v = ok(g.scene, max: 220) { card.scene = v }
        if let v = ok(g.who, max: 60)    { card.who = v }
        if let v = ok(g.goal, max: 220)  { card.goal = v }
        return card
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: 4) VOICE DEBRIEF
// ═══════════════════════════════════════════════════════════════
// Flow (fixed, so it can't turn into a rumination chatbot):
//   greeting + main question → user answer (confidence + note; courage & clarity read from it)
//   → follow-up 1 (Presence) → follow-up 2 (Warmth) → follow-up 3 (stat with the weakest evidence so far)
//   → closing → finished (input is rejected from here on)

/// Everything the debrief prompts need to know about the mission being talked about.
struct AFMDebriefContext: Sendable {
    let title: String
    let scene: String
    let who: String
    let goal: String
    let template: MissionTemplate   // supplies the vetted follow-up questions
    /// User's first name for personalised greetings. Empty = no name available.
    let userName: String

    init(card: QuestCard, userName: String = "") {
        title = card.title
        scene = card.scene
        who = card.who
        goal = card.goal
        template = MissionBank.template(id: card.templateID) ?? MissionBank.all[0]
        self.userName = userName
    }

    init(quest: Quest, userName: String = "") {
        title = quest.title
        let matched = MissionBank.templates(in: quest.category).first ?? MissionBank.all[0]
        scene = matched.scene
        who = matched.who
        goal = quest.notes.isEmpty ? matched.goal : quest.notes
        template = matched
        self.userName = userName
    }

    init(title: String, scene: String = "", who: String = "", goal: String = "", template: MissionTemplate? = nil, userName: String = "") {
        self.title = title
        self.scene = scene
        self.who = who
        self.goal = goal
        self.template = template ?? MissionBank.all[0]
        self.userName = userName
    }
}

extension DebriefContext {
    /// Converts the debrief screen's context into the one the AFM prompts use.
    var afmContext: AFMDebriefContext {
        let template = MissionBank.templates(in: category).first ?? MissionBank.all[0]
        return AFMDebriefContext(title: questTitle, scene: template.scene, who: template.who, goal: template.goal, template: template, userName: userName)
    }
}

/// One chat bubble in the debrief (from Moko or from the user).
struct DebriefTurn: Identifiable, Equatable, Sendable {
    enum Role: Sendable { case moko, user }
    let id = UUID()
    let role: Role
    var text: String
    var stat: Stat? = nil               // which stat a follow-up targets
    var confidence: Int? = nil          // shown as the "Confidence 72" bar on user bubbles
    var confidenceNote: String? = nil   // the brief analysis behind the chevron

    static func moko(_ text: String, stat: Stat? = nil) -> DebriefTurn {
        DebriefTurn(role: .moko, text: text, stat: stat)
    }
}

/// Runs the voice debrief one step at a time. Views read `turns`, `phase` and
/// `isThinking`; `@Observable` redraws them whenever these change.
@MainActor
@Observable
final class DebriefEngine {
    /// Where the conversation is: not started → waiting for the main answer →
    /// waiting for follow-up N → done.
    enum Phase: Equatable { case idle, awaitingMain, awaitingFollowUp(Int), finished }

    static let followUpCount = 3
    static let maxAnswerLength = 1_200

    private(set) var phase: Phase = .idle
    private(set) var turns: [DebriefTurn] = []
    private(set) var isThinking = false
    /// Final per-stat scores, filled in when the debrief closes. A stat with no usable
    /// evidence gets a calm baseline from the average confidence (see `computeFinalScores`).
    private(set) var finalScores: [Stat: Int] = [:]

    /// One AFM score for a stat, plus how strong the evidence behind it was.
    private struct Reading { let score: Int; let evidence: Evidence }

    // `@ObservationIgnored`: internal bookkeeping that no view shows, so changing
    // it should not redraw anything.
    @ObservationIgnored private let context: AFMDebriefContext
    @ObservationIgnored private var readings: [Stat: [Reading]] = [:]
    @ObservationIgnored private var followUpStats: [Stat] = []
    @ObservationIgnored private var observations: [String] = []

    init(context: AFMDebriefContext) { self.context = context }

    convenience init(card: QuestCard) {
        self.init(context: AFMDebriefContext(card: card))
    }

    /// True only while Moko is waiting for an answer (and not busy thinking).
    var acceptsInput: Bool {
        guard !isThinking else { return false }
        switch phase {
        case .awaitingMain, .awaitingFollowUp: return true
        case .idle, .finished: return false
        }
    }

    /// "Question 1 of 3" pill.
    var followUpLabel: String? {
        if case .awaitingFollowUp(let i) = phase { return "Question \(i + 1) of \(Self.followUpCount)" }
        return nil
    }

    // MARK: Public API

    /// Adds Moko's greeting and main question. Safe to call twice; the second call does nothing.
    func start() async {
        guard phase == .idle else { return }
        isThinking = true
        // `defer` runs when the function ends, so the "thinking" dots always stop.
        defer { isThinking = false }

        let generated = try? await AFM.generate(
            DebriefOpening.self,
            instructions: DebriefPrompts.openingInstructions,
            prompt: DebriefPrompts.openingPrompt(context),
            temperature: 0.5
        )
        let fallback = "Welcome back! How did \(context.title) go? Tell me what happened, in your own words."
        turns.append(.moko(Self.usableMessage(generated?.message, maxLength: 260) ?? fallback))
        phase = .awaitingMain
    }

    /// Voice-to-text result or typed text. Ignored unless the engine is waiting for an answer.
    func submit(_ raw: String) async {
        let text = raw.sanitizedForPrompt(limit: Self.maxAnswerLength)
        guard acceptsInput, !text.isEmpty else { return }
        switch phase {
        case .awaitingMain:            await handleMain(text)
        case .awaitingFollowUp(let i): await handleFollowUp(text, index: i)
        case .idle, .finished:         return
        }
    }

    // MARK: Turn handlers

    /// Main answer: AFM reads Courage and Clarity from it, then follow-up 1 is asked.
    private func handleMain(_ text: String) async {
        let idx = appendUser(text)
        isThinking = true
        defer { isThinking = false }

        if let a = try? await AFM.generate(
            MainAnswerAnalysis.self,
            instructions: DebriefPrompts.analysisInstructions,
            prompt: DebriefPrompts.mainAnswerPrompt(context, answer: text),
            temperature: 0.2
        ) {
            record(.courage, a.courage, a.courageEvidence)
            record(.clarity, a.clarity, a.clarityEvidence)
            observations.append(a.whatUserDid)
            turns[idx].confidence = a.confidence
            turns[idx].confidenceNote = a.confidenceNote
        }
        await askFollowUp(0)
    }

    /// Follow-up answer: AFM scores the stat that question targeted, then the next
    /// question (or the closing message) is added.
    private func handleFollowUp(_ text: String, index i: Int) async {
        let idx = appendUser(text)
        isThinking = true
        defer { isThinking = false }

        let stat = followUpStats[i]
        let question = turns.last(where: { $0.role == .moko })?.text ?? ""
        if let a = try? await AFM.generate(
            FollowUpAnalysis.self,
            instructions: DebriefPrompts.analysisInstructions,
            prompt: DebriefPrompts.followUpAnalysisPrompt(context, stat: stat, question: question,
                                                          answer: text, earlier: observations),
            temperature: 0.2
        ) {
            record(stat, a.score, a.evidence)
            observations.append(a.whatUserDid)
            turns[idx].confidence = a.confidence
            turns[idx].confidenceNote = a.confidenceNote
        }

        if i + 1 < Self.followUpCount { await askFollowUp(i + 1) } else { await close() }
    }

    /// Picks the stat for follow-up `i`, starts from the bank's vetted question,
    /// and lets AFM tailor it. A tailored question that fails `validQuestion` is discarded.
    private func askFollowUp(_ i: Int) async {
        let stat: Stat
        switch i {
        case 0:  stat = .presence
        case 1:  stat = .warmth
        default: stat = weakestEvidenceStat()   // "whatever wasn't understood well yet"
        }
        followUpStats.append(stat)

        let base = context.template.followUps[stat] ?? "What's one specific thing you did or noticed?"
        // If Q3 lands on Presence/Warmth, ask it from a different angle than the earlier question.
        let previous = (i == 2 && (stat == .presence || stat == .warmth))
            ? turns.first(where: { $0.role == .moko && $0.stat == stat })?.text
            : nil
        let userSaid = turns.last(where: { $0.role == .user })?.text ?? ""

        let generated = try? await AFM.generate(
            FollowUpQuestionText.self,
            instructions: DebriefPrompts.questionInstructions,
            prompt: DebriefPrompts.questionPrompt(context, stat: stat, base: base,
                                                  userSaid: userSaid, differentFrom: previous),
            temperature: 0.4
        )
        let question = Self.validQuestion(generated?.question) ?? base
        turns.append(.moko(question, stat: stat))
        phase = .awaitingFollowUp(i)
    }

    /// Works out the final scores and adds Moko's goodbye message.
    private func close() async {
        finalScores = computeFinalScores()
        let strongest = finalScores.max { $0.value < $1.value }?.key
        let generated = try? await AFM.generate(
            DebriefClosing.self,
            instructions: DebriefPrompts.closingInstructions,
            prompt: DebriefPrompts.closingPrompt(context, observations: observations, strongest: strongest),
            temperature: 0.5
        )
        let fallback = "Thanks for walking me through \(context.title). You showed up for it, and that's the part that counts."
        turns.append(.moko(Self.usableMessage(generated?.message, maxLength: 300) ?? fallback))
        phase = .finished
    }

    // MARK: Scoring bookkeeping (plain Swift)

    /// Saves one AFM reading. Scores are kept in 45...100 so one bad day never looks harsh.
    private func record(_ stat: Stat, _ score: Int, _ evidence: Evidence) {
        let validScore = max(45, min(score, 100))
        readings[stat, default: []].append(Reading(score: validScore, evidence: evidence))
    }

    /// How much evidence we have for a stat so far (sum of its readings' weights).
    private func evidenceWeight(_ stat: Stat) -> Double {
        readings[stat, default: []].map { $0.evidence.weight }.reduce(0, +)
    }

    /// Lowest total evidence wins; ties go to Courage, then Clarity, Presence, Warmth
    /// (Courage/Clarity haven't had a dedicated question yet).
    private func weakestEvidenceStat() -> Stat {
        let order = Stat.allCases
        return order.min { a, b in
            let wa = evidenceWeight(a), wb = evidenceWeight(b)
            if wa != wb { return wa < wb }
            return (order.firstIndex(of: a) ?? 0) < (order.firstIndex(of: b) ?? 0)
        } ?? .courage
    }

    /// Evidence-weighted average per stat. Stats with no evidence get a baseline
    /// from the average answer confidence (68 if there is none), kept in 48...85.
    private func computeFinalScores() -> [Stat: Int] {
        var out: [Stat: Int] = [:]
        let confidences = turns.compactMap { $0.confidence }
        let avgConf = confidences.isEmpty ? 68 : confidences.reduce(0, +) / confidences.count

        for stat in Stat.allCases {
            let rs = readings[stat, default: []]
            let totalWeight = rs.map { $0.evidence.weight }.reduce(0, +)
            if totalWeight > 0 {
                let weighted = rs.map { Double($0.score) * $0.evidence.weight }.reduce(0, +)
                out[stat] = max(45, Int((weighted / totalWeight).rounded()))
            } else {
                out[stat] = max(48, min(avgConf - 4, 85))
            }
        }
        return out
    }

    // MARK: Helpers

    /// Adds the user's bubble and returns its index, so AFM's confidence can be attached later.
    private func appendUser(_ text: String) -> Int {
        turns.append(DebriefTurn(role: .user, text: text))
        return turns.count - 1
    }

    /// The trimmed AFM message if it is 10...maxLength characters, otherwise nil.
    private static func usableMessage(_ s: String?, maxLength: Int) -> String? {
        guard let v = s?.trimmingCharacters(in: .whitespacesAndNewlines),
              v.count >= 10, v.count <= maxLength else { return nil }
        return v
    }

    /// Rejects anything that isn't one short, closed, non-feelings question.
    private static func validQuestion(_ s: String?) -> String? {
        guard let v = s?.trimmingCharacters(in: .whitespacesAndNewlines),
              v.count >= 10, v.count <= 220,
              v.filter({ $0 == "?" }).count == 1,
              !v.lowercased().contains("feel") else { return nil }
        return v
    }
}

