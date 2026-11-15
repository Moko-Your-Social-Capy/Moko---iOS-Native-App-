// MokoServices.swift
// Glue between the app and AFM:
//   1) Onboarding: deterministic scoring (the AFM insight copy lives in MokoAFM/ReflectionView)
//   2) Quest cards (custom + daily) – AFM writes title/scene/who/goal, app owns difficulty + category image
//   3) Voice debrief context (the state machine itself is AFMDebriefCoach)

import Foundation

// MARK: 1) ONBOARDING

struct OnboardingScoredAnswer: Codable, Equatable, Sendable {
    let questionID: Int   // 1...8
    let yes: Bool         // every question is phrased so that "yes" = the harder behavior
}

struct StatScores: Codable, Equatable, Sendable {
    var courage = 0, clarity = 0, presence = 0, warmth = 0

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

    init(courage: Int = 0, clarity: Int = 0, presence: Int = 0, warmth: Int = 0) {
        self.courage = courage
        self.clarity = clarity
        self.presence = presence
        self.warmth = warmth
    }

    func makeInsightsModel(date: Date = .now) -> InsightsModel {
        InsightsModel(courage: courage, clarity: clarity, presence: presence, warmth: warmth, date: date)
    }
}

enum Band {
    case strength, steady, growth
    init(score: Int) { self = score >= 70 ? .strength : (score >= 50 ? .steady : .growth) }
}

enum OnboardingScoring {
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

    /// Baseline range: a self-report should never land on a hard 0 or 100.
    static let minScore = 25.0, maxScore = 90.0

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

// ═══════════════════════════════════════════════════════════════
// MARK: 2) QUEST CARDS
// ═══════════════════════════════════════════════════════════════

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

@MainActor
enum QuestCardService {

    // Custom quest → matched bank template + card
    static func customCard(_ quest: CustomQuestInput) async -> (card: QuestCard, template: MissionTemplate) {
        let template = await closestTemplate(title: quest.title, notes: quest.notes, category: quest.category)
        let seed = CardSeed(userTitle: quest.title, userNotes: quest.notes,
                            template: template, difficulty: quest.difficulty)
        return (await makeCard(seed), template)
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

        // Content relevance fallback index
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
            let index = min(max(choice.number - 1, 0), options.count - 1)
            return options[index]
        }
        return options[bestIndex]
    }

    private static func makeCard(_ seed: CardSeed) async -> QuestCard {
        let t = seed.template
        let fallbackTitle = (seed.userTitle?.isEmpty == false) ? seed.userTitle! : t.title

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
// MARK: 3) VOICE DEBRIEF
// ═══════════════════════════════════════════════════════════════
// Flow (fixed, so it can't turn into a rumination chatbot):
//   greeting + main question → user answer (confidence + note; courage & clarity read from it)
//   → follow-up 1 (Presence) → follow-up 2 (Warmth) → follow-up 3 (stat with the weakest evidence so far)
//   → closing → finished (input is rejected from here on)

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
    var afmContext: AFMDebriefContext {
        let template = MissionBank.templates(in: category).first ?? MissionBank.all[0]
        return AFMDebriefContext(title: questTitle, scene: template.scene, who: template.who, goal: template.goal, template: template, userName: userName)
    }
}
