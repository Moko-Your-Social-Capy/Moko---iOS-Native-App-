// MokoServices.swift
// Glue between the app and AFM:
//   1) Onboarding: deterministic scoring (the AFM insight copy lives in MokoAFM/ReflectionView)
//   2) Quest cards (custom + daily) – AFM writes title/scene/who/goal, app owns difficulty + category image
//   3) Voice debrief context (the state machine itself is AFMDebriefCoach)

import Foundation

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

/// Which "band" a score falls into: 70+ strength, 50–69 steady, below 50 growth.
enum Band {
    case strength, steady, growth
    init(score: Int) { self = score >= 70 ? .strength : (score >= 50 ? .steady : .growth) }
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

// ═══════════════════════════════════════════════════════════════
// MARK: 2) QUEST CARDS
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
// AFM classifies each reply before scoring it. Unclear replies stay on the same question.
// Accepted replies add independent evidence for all four stats. Three follow-ups target missing
// stats first and weaker evidence second, then AFM writes the closing message.

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
        let titleLower = quest.title.lowercased()
        let matched = MissionBank.all.first {
            $0.title.lowercased() == titleLower ||
            titleLower.contains($0.title.lowercased()) ||
            $0.title.lowercased().contains(titleLower)
        } ?? MissionBank.templates(in: quest.category).first ?? MissionBank.all[0]

        if !quest.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scene = quest.notes
            goal = quest.title
            who = matched.who
        } else {
            scene = matched.scene
            who = matched.who
            goal = matched.goal
        }
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
        let titleLower = questTitle.lowercased()
        let matched = MissionBank.all.first {
            $0.title.lowercased() == titleLower ||
            titleLower.contains($0.title.lowercased()) ||
            $0.title.lowercased().contains(titleLower)
        } ?? MissionBank.templates(in: category).first ?? MissionBank.all[0]

        let scene: String
        let goal: String
        let who: String

        if !questNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scene = questNotes
            goal = questTitle
            who = matched.who
        } else if matched.title.lowercased() == titleLower || titleLower.contains(matched.title.lowercased()) {
            scene = matched.scene
            goal = matched.goal
            who = matched.who
        } else {
            scene = "\(questTitle) in a \(category.rawValue.lowercased()) situation"
            goal = questTitle
            who = matched.who
        }

        return AFMDebriefContext(
            title: questTitle,
            scene: scene,
            who: who,
            goal: goal,
            template: matched,
            userName: userName
        )
    }
}
