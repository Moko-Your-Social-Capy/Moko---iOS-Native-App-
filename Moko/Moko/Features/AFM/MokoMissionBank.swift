// MokoMissionBank.swift
// Shared domain types + the 20-situation Mission Bank (v2) from "Lowkey-Mission-Bank-Followups.pdf".
// This is the retrieval source for: similar-mission planning, goals, the debrief main question,
// and the per-stat follow-up questions. AFM personalises these; it never invents them from nothing.

import Foundation

// MARK: - Core vocab

enum Stat: String, CaseIterable, Codable, Hashable, Sendable {
    case courage, clarity, presence, warmth

    var title: String { rawValue.capitalized }

    /// Definitions from the Moko onboarding tagging doc.
    var definition: String {
        switch self {
        case .courage:  return "Approach versus avoidance: moving toward a feared social moment instead of avoiding it."
        case .clarity:  return "Direct, concise communication: saying what you mean without hedging or over-explaining."
        case .presence: return "Being in the moment with the other person instead of self-monitoring or planning what to say next."
        case .warmth:   return "Genuine engagement and openness: taking in the other person's perspective and sharing appropriately."
        }
    }
}

// Note: QuestCategory is declared in QuestModels.swift:
// (.work, .dating, .friends, .family, .others)

enum Difficulty: String, CaseIterable, Codable, Hashable, Sendable {
    case easy, medium, hard
    var rank: Int {
        switch self {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 2
        }
    }
}

extension Difficulty {
    init(intensity: QuestIntensity) {
        switch intensity {
        case .easy: self = .easy
        case .medium: self = .medium
        case .hard: self = .hard
        }
    }

    var intensity: QuestIntensity {
        switch self {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        }
    }
}

extension QuestIntensity {
    init(difficulty: Difficulty) {
        switch difficulty {
        case .easy: self = .easy
        case .medium: self = .medium
        case .hard: self = .hard
        }
    }

    var difficulty: Difficulty {
        Difficulty(intensity: self)
    }
}

struct MissionTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let category: QuestCategory
    /// Lower bound of the bank's tier: 1 (1–3), 4 (4–7), 8 (8–12), 13 (13+).
    let tierLow: Int
    let ageRange: ClosedRange<Int>
    let title: String
    let scene: String
    let who: String
    let goal: String
    /// One closed, concrete debrief question per stat (non-rumination constraint, Section 14.1).
    let followUps: [Stat: String]

    /// Bank tiers → app difficulty. Tune freely.
    var difficulty: Difficulty {
        if tierLow <= 3 { return .easy }
        if tierLow <= 7 { return .medium }
        return .hard
    }
}

// MARK: - Bank

enum MissionBank {
    static func template(id: String) -> MissionTemplate? { all.first { $0.id == id } }

    static func templates(in category: QuestCategory, age: Int? = nil) -> [MissionTemplate] {
        let pool = (category == .others) ? all : all.filter { $0.category == category }
        return pool.filter { t in
            age.map { t.ageRange.contains($0) } ?? true
        }
    }

    static let all: [MissionTemplate] = [

        // ───────── WORK ─────────
        t("work-speak-up-meeting", .work, 1, 18...28, "Speak Up in a Meeting",
          scene: "A small team meeting; you have an idea forming.",
          who: "3–4 coworkers.",
          goal: "Say one idea out loud before the meeting ends.",
          c: "Did you say the idea before someone else spoke, or after a pause?",
          cl: "How many sentences did it take you to say the idea?",
          p: "What's one thing a teammate did right after you spoke (nodded, wrote it down, asked a question)?",
          w: "Did you credit or build on anyone else's earlier comment when you spoke?"),

        t("work-decline-extra", .work, 4, 18...28, "Decline Extra Work",
          scene: "Your manager asks you to take on one more task at 5pm.",
          who: "Your manager.",
          goal: "Say no without a long justification.",
          c: "Did you say no in your first sentence, or agree first and walk it back?",
          cl: "What were the exact words you used to say no?",
          p: "What was your manager's reaction right after you said no?",
          w: "Did you acknowledge their situation before or after declining?"),

        t("work-introduce-new-job", .work, 4, 18...28, "Introduce Yourself at a New Job",
          scene: "First day in an open office.",
          who: "A teammate you haven't met.",
          goal: "Introduce yourself first, before they do.",
          c: "Who said their name first — you or them?",
          cl: "Did you state your name and role in one sentence, or did it take more?",
          p: "What's one detail you noticed about them before you spoke?",
          w: "Did you ask them a question about themselves within the first minute?"),

        t("work-correct-boss", .work, 8, 20...28, "Correct Your Boss",
          scene: "Your manager misstates a fact about your work in front of the team.",
          who: "Your manager and team.",
          goal: "Correct the record once, calmly.",
          c: "Did you correct it in the same conversation, or let it go and plan to fix it later?",
          cl: "Did you state the correction in one sentence, or hedge first?",
          p: "How did your manager react right after you corrected them?",
          w: "Did you phrase it to protect their standing (“I think what happened was…”) or state it flatly?"),

        t("work-feedback-after-mistake", .work, 13, 20...28, "Ask for Feedback After a Mistake",
          scene: "You made a visible error on a project.",
          who: "Your manager.",
          goal: "Bring it up yourself and ask how to improve.",
          c: "Did you bring it up, or did they bring it up first?",
          cl: "Did you name the specific mistake, or describe it vaguely?",
          p: "What was their first reaction when you brought it up?",
          w: "Did you ask how it affected them or the team, not just how to fix it for you?"),

        // ───────── DATING ─────────
        t("dating-first-message", .dating, 1, 18...28, "Send the First Message",
          scene: "You matched with someone on an app.",
          who: "The match.",
          goal: "Send an opener within 10 minutes of matching.",
          c: "How many minutes passed between the match and your message?",
          cl: "Did your opener reference something specific from their profile, or was it generic?",
          p: "What detail from their profile did you mention?",
          w: "Did your message ask them a question, or only state something about you?"),

        t("dating-suggest-place", .dating, 4, 18...28, "Suggest the Place",
          scene: "Planning where to meet for a date.",
          who: "Your date.",
          goal: "Propose one specific place instead of “wherever you want.”",
          c: "Did you name a specific place, or ask them to choose?",
          cl: "Did you suggest one place, or list several options?",
          p: "Did you pick the place based on something they'd mentioned?",
          w: "Did you check the time/place worked for them, or just state it?"),

        t("dating-name-what-you-felt", .dating, 4, 18...28, "Name What You Felt",
          scene: "The date went well.",
          who: "Your date.",
          goal: "Tell them directly you enjoyed it, not just “haha yeah, good night.”",
          c: "Did you say it out loud, or only text it afterward?",
          cl: "What exact words did you use to say you enjoyed it?",
          p: "What's one specific thing from the date you mentioned enjoying?",
          w: "Did you ask if they felt the same, or only state your own feeling?"),

        t("dating-exclusivity", .dating, 8, 20...28, "Ask the Exclusivity Question",
          scene: "A few dates in.",
          who: "The person you're seeing.",
          goal: "Ask directly where things stand.",
          c: "Did you ask directly, or hint and wait for them to bring it up?",
          cl: "Did you ask in one direct sentence, or build up to it over several?",
          p: "How did they react in the moment?",
          w: "Did you share your own feelings first, or only ask about theirs?"),

        t("dating-end-it", .dating, 13, 20...28, "End It Clearly",
          scene: "It isn't working.",
          who: "The person you're seeing.",
          goal: "Say it's over directly rather than going quiet.",
          c: "Did you say it was over in words, or let the conversation trail off?",
          cl: "Did you say it in one clear sentence?",
          p: "Did you notice their reaction before you finished speaking?",
          w: "Did you acknowledge the good parts, or only the ending?"),

        // ───────── FRIENDS ─────────
        t("friends-suggest-hangout", .friends, 1, 16...28, "Suggest the Hangout",
          scene: "You want to see a friend but haven't initiated in a while.",
          who: "A friend.",
          goal: "Be the one to suggest plans.",
          c: "Who sent the first message about hanging out — you or them?",
          cl: "Did you suggest a specific day/activity, or keep it open (“we should hang out sometime”)?",
          p: "Did you reference something they'd mentioned wanting to do?",
          w: "Did you ask what they'd want to do, or just state your plan?"),

        t("friends-admit-dont-know", .friends, 1, 16...28, "Admit You Don't Know",
          scene: "A group conversation references something you don't know.",
          who: "A friend group.",
          goal: "Ask instead of nodding along.",
          c: "Did you ask what it meant, or nod and look it up later?",
          cl: "Did you ask directly (“what's that?”), or hint that you were lost?",
          p: "Did you notice who in the group was talking when you asked?",
          w: "Did your question invite them to explain, or did you move past it quickly?"),

        t("friends-say-hurt", .friends, 4, 16...28, "Say You're Hurt",
          scene: "A friend said something that stung.",
          who: "That friend.",
          goal: "Name the specific comment instead of letting it slide.",
          c: "Did you name the specific comment, or describe the feeling in general terms?",
          cl: "Did it take one sentence or several to say what bothered you?",
          p: "Did you notice their reaction as you said it?",
          w: "Did you also say what you valued about the friendship, or only the hurt?"),

        t("friends-turn-down-plan", .friends, 8, 16...28, "Turn Down the Plan",
          scene: "Invited somewhere you don't want to go.",
          who: "A friend group.",
          goal: "Decline without a long excuse.",
          c: "Did you say no directly, or avoid responding until it passed?",
          cl: "How many sentences did your decline take?",
          p: "Did you notice how the group reacted to your decline?",
          w: "Did you suggest an alternative time, or just decline?"),

        t("friends-bring-up-distance", .friends, 13, 18...28, "Bring Up the Distance",
          scene: "A friendship has been quietly fading.",
          who: "That friend.",
          goal: "Name it directly and ask if they want to reconnect.",
          c: "Did you name the distance out loud, or only hint that you'd missed them?",
          cl: "Did you say it in one direct sentence?",
          p: "Did you notice how they responded in the moment?",
          w: "Did you ask if they wanted to reconnect, or just state the observation?"),

        // ───────── FAMILY ─────────
        t("family-share-small", .family, 1, 16...28, "Share Something Small",
          scene: "Family dinner, small talk.",
          who: "A parent or sibling.",
          goal: "Volunteer one real detail about your week, not just “fine.”",
          c: "Did you bring it up yourself, or only answer when asked twice?",
          cl: "What was the one detail you actually shared?",
          p: "Did you notice who was listening when you shared it?",
          w: "Did you ask them something back about their week?"),

        t("family-ask-help", .family, 4, 16...28, "Ask for Help",
          scene: "You need something practical.",
          who: "A family member.",
          goal: "Ask directly instead of hinting.",
          c: "Did you ask directly, or hint and wait for them to offer?",
          cl: "Did you name exactly what you needed?",
          p: "Did you notice their reaction when you asked?",
          w: "Did you thank them specifically, or just accept the help?"),

        t("family-correct-narrative", .family, 8, 16...28, "Correct a Family Narrative",
          scene: "A relative retells an old story about you inaccurately.",
          who: "Extended family.",
          goal: "Gently correct it once.",
          c: "Did you correct it in the moment, or only think about correcting it afterward?",
          cl: "Did you correct it in one sentence, or qualify it several times?",
          p: "What was the relative's reaction when you corrected them?",
          w: "Did you keep it light (a joke, a smile) or was it flat and clinical?"),

        t("family-visit-boundary", .family, 8, 18...28, "Set a Visit Boundary",
          scene: "A relative wants more time or contact than you're ready for.",
          who: "A parent or relative.",
          goal: "State a limit clearly.",
          c: "Did you state the limit yourself, or wait for them to ask first?",
          cl: "Did you state a specific limit, or leave it open-ended?",
          p: "Did you notice their reaction to the boundary?",
          w: "Did you offer an alternative (a call, a shorter visit) alongside the limit?"),

        t("family-unspoken-thing", .family, 13, 18...28, "Bring Up the Unspoken Thing",
          scene: "There's a topic the family avoids.",
          who: "The relevant family member.",
          goal: "Name it in one sentence, even if it doesn't resolve.",
          c: "Did you name the topic directly, or talk around it?",
          cl: "Did it take one sentence, or did you circle it several times before landing on it?",
          p: "What was their first reaction when you named it?",
          w: "Did you leave room for their side, or only state your own?"),
    ]
}

// File-private builder to keep the table above readable.
fileprivate func t(_ id: String, _ category: QuestCategory, _ tierLow: Int, _ ages: ClosedRange<Int>,
                   _ title: String, scene: String, who: String, goal: String,
                   c: String, cl: String, p: String, w: String) -> MissionTemplate {
    MissionTemplate(id: id, category: category, tierLow: tierLow, ageRange: ages,
                    title: title, scene: scene, who: who, goal: goal,
                    followUps: [.courage: c, .clarity: cl, .presence: p, .warmth: w])
}

