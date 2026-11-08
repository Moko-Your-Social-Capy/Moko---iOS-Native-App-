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
}
