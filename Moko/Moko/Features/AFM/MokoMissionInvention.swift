// MokoMissionInvention.swift
// Lets AFM INVENT fresh daily missions (more variety) while keeping them doable and grounded.
//
// How "interesting but not random" is enforced:
//   1. ANCHOR      – every invented mission is tied to a vetted Mission Bank situation and must practise the same
//                    core behavior, so that situation's four follow-up questions still apply at debrief time.
//   2. SEEDS       – Swift (not the model) picks the variety: 3 candidate formats + a tone, rotated per day.
//                    The model adapts them; it doesn't roam free.
//   3. VALIDATOR   – plain-Swift rules: length, single sentence, verb-first, blocked topics, outcome-style goals,
//                    no repeated titles.
//   4. REVIEW PASS – a second, low-temperature AFM call answers five yes/no checks (doable, single behavior,
//                    follow-ups still fit, believable, safe).
//   5. FAIL CLOSED – any failure retries once with feedback; after that we return nil and the caller falls back
//                    to the reworded bank situation. A bad invention never reaches the user.

import Foundation
import FoundationModels

// MARK: - Generable types

@Generable
struct InventedMission {
    @Guide(description: "Max 15 words: how this mission practises the SAME core behavior as the pattern's goal.")
    var sameSkillReason: String
    @Guide(description: "Card title, 2–4 words, Title Case, naming the moment (not the feeling). No emojis, no punctuation.")
    var cardTitle: String
    @Guide(description: "THE SCENE: 1–2 short sentences, present tense, an ordinary everyday moment with one small concrete detail. No advice.")
    var scene: String
    @Guide(description: "WHO: short role phrase such as 'A teammate and you.' Never invent names.")
    var who: String
    @Guide(description: "YOUR GOAL: ONE sentence starting with an action verb, one concrete behavior, max 30 words. Not an outcome.")
    var goal: String
}

@Generable
struct MissionCheck {
    @Guide(description: "True only if a typical person can complete the goal today in ONE interaction under 10 minutes, with no travel, money, props, planning or special access.")
    var doableToday: Bool
    @Guide(description: "True only if the goal asks for exactly one concrete behavior, not several tasks.")
    var singleBehavior: Bool
    @Guide(description: "True only if ALL four debrief questions would still make sense after doing this mission.")
    var followUpsFit: Bool
    @Guide(description: "True only if the scene is ordinary, believable everyday life: nothing bizarre, theatrical, cringe or challenge-style.")
    var believable: Bool
    @Guide(description: "True only if it is safe, respectful and appropriate for the stated age range: nothing sexual, coercive, deceptive, or involving substances, isolation or confronting a dangerous person.")
    var safe: Bool
}

// MARK: - Variety seeds (chosen by Swift, adapted by the model)

enum VarietyPool {
    static let formats = [
        "in person, one-on-one",
        "over text or chat",
        "on a short phone or video call",
        "in a small group of 3–4 people",
        "while doing something together (walking, cooking, commuting, waiting)",
        "in a short voice note",
        "right after something wraps up (a meeting, a class, a meal)",
        "at a casual, low-pressure moment of the day",
    ]
    static let tones = ["light and playful", "calm and direct", "curious and open", "kind and straightforward"]

    /// Deterministic per (seed, day): same quest → stable variety, different days → different seeds.
    static func pick(dayNumber: Int, seed: String) -> (formats: [String], tone: String) {
        let offset = stableOffset(seed)
        let start = (offset + dayNumber * 3) % formats.count
        let three = (0..<3).map { formats[(start + $0 * 2) % formats.count] }   // 3 distinct formats
        return (three, tones[(offset + dayNumber) % tones.count])
    }

    private static func stableOffset(_ s: String) -> Int {
        s.unicodeScalars.reduce(7) { ($0 * 31 + Int($1.value)) % 10_007 }
    }
}

// MARK: - Plain-Swift validator

enum MissionValidator {
    private static let blockedWords: Set<String> = [
        "drunk", "alcohol", "beer", "vape", "drugs", "weed", "stalk", "secretly", "spy", "prank", "dare",
        "trick", "lie", "lying", "fake", "pretend", "threaten", "blackmail", "nude", "naked", "sex", "sexy",
        "kiss", "money", "cash", "borrow", "loan", "buy", "purchase",
    ]
    private static let blockedPhrases = [
        "make them", "make him", "make her", "get them to", "get him to", "get her to", "convince", "impress",
        "at night", "late night", "alone with", "drive to", "fly to", "travel to", "go to a party",
    ]
    private static let notVerbStarts: Set<String> = ["you", "your", "the", "a", "an", "it", "they", "this", "to", "be"]

    /// Returns a human-readable failure reason, or nil if the mission passes.
    static func validate(_ m: InventedMission, anchor: MissionTemplate, recentTitles: [String]) -> String? {
        let title = m.cardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let scene = m.scene.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = m.who.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = m.goal.trimmingCharacters(in: .whitespacesAndNewlines)

        let titleWords = title.split(separator: " ").count
        guard (2...6).contains(titleWords), title.count <= 40 else { return "Title must be 2-4 words." }
        let known = (recentTitles + [anchor.title]).map { $0.lowercased() }
        guard !known.contains(title.lowercased()) else { return "Title repeats an earlier mission; make it new." }

        guard !scene.isEmpty, scene.count <= 220 else { return "Scene must be 1-2 short sentences." }
        guard !who.isEmpty, who.count <= 60 else { return "Who must be a short role phrase." }

        let goalWords = goal.split(separator: " ").count
        guard (4...30).contains(goalWords) else { return "Goal must be 4-30 words." }
        guard goal.filter({ ".?!".contains($0) }).count <= 1 else { return "Goal must be a single sentence." }
        let first = goal.split(separator: " ").first.map { $0.lowercased() } ?? ""
        guard !notVerbStarts.contains(first) else { return "Goal must start with an action verb." }

        let text = "\(title) \(scene) \(who) \(goal)".lowercased()
        let words = Set(text.split(whereSeparator: { !$0.isLetter }).map(String.init))
        if let bad = words.first(where: { blockedWords.contains($0) }) {
            return "Remove the topic '\(bad)'; keep it ordinary and safe."
        }
        if let bad = blockedPhrases.first(where: { text.contains($0) }) {
            return "Remove '\(bad)'; the goal must be a behavior the user does, not an outcome or a risky situation."
        }
        return nil
    }

    static func failureReason(_ c: MissionCheck) -> String? {
        var problems: [String] = []
        if !c.doableToday    { problems.append("not doable today in one short interaction") }
        if !c.singleBehavior { problems.append("asks for more than one behavior") }
        if !c.followUpsFit   { problems.append("the debrief questions would not fit it") }
        if !c.believable     { problems.append("not an ordinary, believable moment") }
        if !c.safe           { problems.append("not clearly safe and appropriate") }
        return problems.isEmpty ? nil : "Review failed: " + problems.joined(separator: "; ") + "."
    }
}

// MARK: - Prompts

enum InventionPrompts {
    static let instructions = """
    You invent a fresh daily practice mission for Moko, a social-confidence app. A mission is a small real-life social moment the user can do TODAY.

    You receive a vetted PATTERN. Your mission must practise the SAME core behavior as the pattern's goal (so its debrief questions still apply), but in a NEW everyday situation.

    MAKE IT INTERESTING, KEEP IT REAL
    - Do not copy the pattern. Change the setting, the format and add one small realistic detail (time of day, what is happening around them).
    - Choose ONE of the offered formats that fits the pattern naturally. If none fits, keep the pattern's own setting.
    - Ordinary life only: classmates, coworkers, friends, family, people the user already knows or meets in normal routines. Nothing bizarre, theatrical or challenge-style.

    MUST BE DOABLE
    - Completable today in one interaction under 10 minutes. No travel, money, props, planning or special access.
    - Exactly ONE concrete behavior the user can later describe. Goal = one sentence, starts with a verb, max 30 words. Never an outcome ("make them laugh"), never several tasks.
    - easy = low stakes, familiar person, short. medium = a little exposure. hard = higher stakes but still a single step.
    - Never invent names, facts or backstory. Use roles ("a teammate", "your cousin").

    SAFE
    - Respectful and honest. Nothing sexual, coercive, deceptive or risky.

    EXAMPLES
    pattern goal: "Say one idea out loud before the meeting ends." (Speak Up in a Meeting)
    → title: "Share a Thought in Chat" | scene: "A team chat thread is picking a spot for the next team lunch. You have a small idea." | who: "Your team and you." | goal: "Post one idea in the chat before the thread moves on."

    pattern goal: "Ask directly instead of hinting." (Ask for Help)
    → title: "Ask for a Hand" | scene: "A sibling is nearby while you are stuck on an online form." | who: "A sibling and you." | goal: "Ask your sibling for help by saying exactly what you need."
    """

    static func prompt(anchor: MissionTemplate, difficulty: Difficulty, formats: [String], tone: String,
                       dayNumber: Int, totalDays: Int, practiceFor: String?,
                       focusStat: Stat? = nil,
                       recentTitles: [String], feedback: String?) -> String {
        var parts = [
            "CATEGORY: \(anchor.category.rawValue)",
            "DIFFICULTY: \(difficulty.rawValue)",
            """
            PATTERN (same core behavior, new situation)
            Situation: \(anchor.title)
            Scene: \(anchor.scene)
            Who: \(anchor.who)
            Goal: \(anchor.goal)
            """,
            "OFFERED FORMATS (pick one that fits): " + formats.joined(separator: " | "),
            "TONE: \(tone)",
        ]
        if let target = practiceFor {
            parts.append("This is practice day \(dayNumber) of \(totalDays) before the user's upcoming \"\(target.sanitizedForPrompt(limit: 80))\". Make it a stepping stone toward that event, preparing them for the interaction without spoon-feeding the exact same situation.")
        }
        if let stat = focusStat {
            parts.append("GROWTH FOCUS: Emphasize \(stat.title.uppercased()) (\(stat.definition)). Shape the goal so it specifically offers a concrete moment to practice \(stat.title).")
        }
        let avoid = recentTitles.suffix(8)
        if !avoid.isEmpty {
            parts.append("Do not reuse these titles: " + avoid.joined(separator: "; "))
        }
        if let feedback {
            parts.append("Your previous attempt was rejected: \(feedback) Fix this.")
        }
        return parts.joined(separator: "\n\n")
    }

    static let reviewInstructions = """
    You are a strict reviewer for a social-confidence app. You get a pattern, four debrief questions, and a proposed daily mission. Answer each check honestly with true or false. When unsure, answer false.
    """

    static func reviewPrompt(anchor: MissionTemplate, mission: InventedMission) -> String {
        let questions = Stat.allCases
            .compactMap { stat in anchor.followUps[stat].map { "- \($0)" } }
            .joined(separator: "\n")
        return """
        AGE RANGE: \(anchor.ageRange.lowerBound)-\(anchor.ageRange.upperBound)
        PATTERN GOAL: \(anchor.goal)
        DEBRIEF QUESTIONS (asked after the mission):
        \(questions)

        PROPOSED MISSION
        Title: \(mission.cardTitle)
        Scene: \(mission.scene)
        Who: \(mission.who)
        Goal: \(mission.goal)
        """
    }
}

// MARK: - Inventor

@MainActor
enum MissionInventor {
    /// Returns a checked, invented card, or nil if the model is unavailable or nothing passed all checks.
    static func invent(anchor: MissionTemplate,
                       difficulty: Difficulty,
                       dayNumber: Int,
                       totalDays: Int,
                       practiceFor: String?,
                       focusStat: Stat? = nil,
                       seed: String,
                       recentTitles: [String]) async -> QuestCard? {
        guard AFM.isAvailable else { return nil }
        let variety = VarietyPool.pick(dayNumber: dayNumber, seed: seed)
        var feedback: String? = nil

        for attempt in 0..<2 {
            guard let m = try? await AFM.generate(
                InventedMission.self,
                instructions: InventionPrompts.instructions,
                prompt: InventionPrompts.prompt(anchor: anchor, difficulty: difficulty,
                                                formats: variety.formats, tone: variety.tone,
                                                dayNumber: dayNumber, totalDays: totalDays,
                                                practiceFor: practiceFor,
                                                focusStat: focusStat,
                                                recentTitles: recentTitles, feedback: feedback),
                temperature: attempt == 0 ? 0.8 : 0.5,
                retries: 0
            ) else { continue }

            if let reason = MissionValidator.validate(m, anchor: anchor, recentTitles: recentTitles) {
                feedback = reason
                continue
            }

            // Review pass: if the reviewer errors out we reject (fail closed).
            guard let check = try? await AFM.generate(
                MissionCheck.self,
                instructions: InventionPrompts.reviewInstructions,
                prompt: InventionPrompts.reviewPrompt(anchor: anchor, mission: m),
                temperature: 0.1,
                retries: 0
            ) else { continue }

            if let reason = MissionValidator.failureReason(check) {
                feedback = reason
                continue
            }

            return QuestCard(templateID: anchor.id,
                             category: anchor.category,
                             difficulty: difficulty,
                             title: m.cardTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                             scene: m.scene.trimmingCharacters(in: .whitespacesAndNewlines),
                             who: m.who.trimmingCharacters(in: .whitespacesAndNewlines),
                             goal: m.goal.trimmingCharacters(in: .whitespacesAndNewlines),
                             isInvented: true)
        }
        return nil
    }
}

extension QuestCardService {
    /// Today's mission: invent a fresh one from a bank template (optionally targeting a custom quest or lowest stat),
    /// or fall back to the bank text as written.
    static func freshDailyCard(from template: MissionTemplate,
                               recentTitles: [String],
                               seed: String = "daily",
                               dayNumber: Int = 1,
                               totalDays: Int = 1,
                               practiceFor: String? = nil,
                               focusStat: Stat? = nil) async -> QuestCard {
        if let invented = await MissionInventor.invent(anchor: template,
                                                       difficulty: template.difficulty,
                                                       dayNumber: dayNumber,
                                                       totalDays: totalDays,
                                                       practiceFor: practiceFor,
                                                       focusStat: focusStat,
                                                       seed: seed,
                                                       recentTitles: recentTitles) {
            return invented
        }
        return libraryCard(template)
    }
}

