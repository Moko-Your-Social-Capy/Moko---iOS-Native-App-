import Foundation

struct QuestCardTemplate: Codable, Equatable {
    var title: String
    var situation: String
    var step: String
    var tryThis: String
    var timeEstimate: String
}

#if canImport(FoundationModels)
import FoundationModels

@Generable
struct DailyQuestCopy {
    @Guide(description: "Title, max 6 words")
    var title: String

    @Guide(description: "Situation, one sentence, max 20 words")
    var situation: String

    @Guide(description: "Step, one concrete action starting with a verb, max 18 words")
    var step: String

    @Guide(description: "Try this, short opener the user could say, max 14 words")
    var tryThis: String
}
#endif // canImport(FoundationModels)

enum DailyQuestTemplateGenerator {
    static func generate(
        title: String,
        situation: String,
        step: String,
        tryThis: String,
        estimatedMinutes: Int,
        category: String,
        difficulty: Int
    ) async -> QuestCardTemplate {
        let fallback = QuestCardTemplate(
            title: title,
            situation: situation,
            step: step,
            tryThis: tryThis,
            timeEstimate: "\(estimatedMinutes) min"
        )

#if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return fallback
        }

        do {
            let session = LanguageModelSession(instructions: "Rewrite the given quest in warm, plain English. Use only the provided fields. Do not add new events, people, places or promises. No advice beyond the step. No pressure words.")
            let prompt = "Category: \(category). Difficulty: \(difficulty). Original Title: \(title). Original Situation: \(situation). Original Step: \(step). Original TryThis: \(tryThis)."
            let response = try await session.respond(
                to: prompt,
                generating: DailyQuestCopy.self,
                options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 220)
            )
            let content = response.content

            // Same guardrails as the rest of the app: length, banned wording, no invented numbers
            let source = "\(title) \(situation) \(step) \(tryThis)"
            guard MokoAFMPolicy.passesChecks(content.title, maxWords: 6, source: source),
                  MokoAFMPolicy.passesChecks(content.situation, maxWords: 20, source: source),
                  MokoAFMPolicy.passesChecks(content.step, maxWords: 18, source: source),
                  MokoAFMPolicy.passesChecks(content.tryThis, maxWords: 14, source: source) else {
                return fallback
            }

            return QuestCardTemplate(
                title: content.title,
                situation: content.situation,
                step: content.step,
                tryThis: content.tryThis,
                timeEstimate: "\(estimatedMinutes) min"
            )
        } catch {
            return fallback
        }
#else
        return fallback
#endif
    }

    // MARK: - Generate a new quest for a skill

    /// Builds a brand-new quest for the given skill ("Courage", "Clarity", "Presence", "Warmth").
    /// Uses Apple's on-device model when available and when its answer passes the guardrails,
    /// otherwise a hand-written quest for that skill.
    static func generateQuest(forSkill skill: String, stage: String) async -> LibraryQuestItem {
        let base = fallbackQuest(forSkill: skill, stage: stage)

#if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return base }

        do {
            let session = LanguageModelSession(instructions: "Write one small, gentle social practice quest for the named skill. Warm, plain English. One concrete action that takes about 3 minutes. No pressure words, no medical or therapy language, no promises about outcomes.")
            let prompt = "Skill to practice: \(skill). Setting: \(stageDescription(stage))."
            let response = try await session.respond(
                to: prompt,
                generating: DailyQuestCopy.self,
                options: GenerationOptions(temperature: 0.5, maximumResponseTokens: 220)
            )
            let draft = response.content

            guard MokoAFMPolicy.passesChecks(draft.title, maxWords: 6, source: prompt),
                  MokoAFMPolicy.passesChecks(draft.situation, maxWords: 20, source: prompt),
                  MokoAFMPolicy.passesChecks(draft.step, maxWords: 18, source: prompt),
                  MokoAFMPolicy.passesChecks(draft.tryThis, maxWords: 14, source: prompt) else {
                return base
            }

            var quest = base
            quest.title = draft.title
            quest.situation = draft.situation
            quest.step = draft.step
            quest.tryThis = draft.tryThis
            return quest
        } catch {
            return base
        }
#else
        return base
#endif
    }

    private static func stageDescription(_ stage: String) -> String {
        switch stage {
        case "newGroups": return "meeting people in a new group"
        case "withinGroup": return "taking part inside a group you already know"
        case "family": return "with family"
        default: return "with someone from your close circle"
        }
    }

    private static func fallbackQuest(forSkill skill: String, stage: String) -> LibraryQuestItem {
        let title: String
        let situation: String
        let step: String
        let tryThis: String
        let tip: String

        switch skill.lowercased() {
        case "courage":
            title = "Say the First Hello"
            situation = "Someone familiar is nearby and the moment feels a little big."
            step = "Start the conversation yourself with a short greeting."
            tryThis = "Hi! How is your day going?"
            tip = "Take one slow breath, then go."
        case "clarity":
            title = "Name What You Feel"
            situation = "A short chat leaves you with mixed feelings."
            step = "Pause and put one feeling into a single sentence."
            tryThis = "I'm a bit nervous, but glad to be here."
            tip = "One honest sentence is enough."
        case "presence":
            title = "Listen for One Minute"
            situation = "Someone is telling you about their day."
            step = "Keep your eyes and attention on them for one full minute."
            tryThis = "Tell me more about that."
            tip = "Let your own thoughts pass by."
        default:
            title = "Share One Kind Word"
            situation = "A friend or classmate is nearby."
            step = "Offer a sincere compliment or thank-you."
            tryThis = "Thanks for helping me earlier. I appreciated it."
            tip = "Small and sincere works best."
        }

        let name = skill.isEmpty ? "Warmth" : skill
        return LibraryQuestItem(
            id: "generated-\(name.lowercased())",
            title: title,
            situation: situation,
            step: step,
            tryThis: tryThis,
            skills: [name],
            difficulty: 1,
            category: "Friends",
            onboardingTheme: stage,
            stage: stage,
            estimatedMinutes: 3,
            tip: tip
        )
    }
}
