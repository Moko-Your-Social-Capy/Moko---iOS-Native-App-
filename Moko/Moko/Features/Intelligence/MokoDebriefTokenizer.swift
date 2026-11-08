import Foundation
import NaturalLanguage

struct MokoDebriefTokens: Equatable {
    var words: [String]
    var emotions: [String]
    var actions: [String]
    var people: [String]
    var outcomes: [String]
}

enum MokoDebriefTokenizer {
    private static let emotions: Set = ["nervous", "anxious", "calm", "excited", "scared", "afraid", "worried", "awkward", "shy", "happy", "relieved", "proud", "embarrassed", "stressed", "tense", "comfortable"]
    private static let actions: Set = ["said", "asked", "went", "joined", "spoke", "left", "talked", "introduced", "answered", "waved", "greeted", "shared", "told", "started", "replied", "tried"]
    private static let people: Set = ["friend", "friends", "boss", "classmate", "classmates", "parent", "parents", "mom", "dad", "teacher", "coworker", "colleague", "neighbor", "stranger", "sister", "brother", "family"]
    private static let outcomes: Set = ["smiled", "laughed", "ignored", "agreed", "nodded", "thanked", "replied", "welcomed", "listened", "responded", "invited"]
    private static let stopWords: Set = ["i", "was", "but", "the", "a", "an", "and", "for", "to", "of", "my", "in", "on", "with", "it", "that"]

    static func tokenize(_ text: String) -> MokoDebriefTokens {
        let lowered = text.lowercased()
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = lowered
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = lowered
        var words: [String] = []
        tokenizer.enumerateTokens(in: lowered.startIndex..<lowered.endIndex) { range, _ in
            let word = String(lowered[range]).trimmingCharacters(in: .punctuationCharacters)
            let tag = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lexicalClass).0
            if !word.isEmpty, !stopWords.contains(word), tag == .noun || tag == .verb || tag == .adjective {
                words.append(word)
            }
            return words.count < 40
        }
        return MokoDebriefTokens(
            words: words,
            emotions: words.filter(emotions.contains),
            actions: words.filter(actions.contains),
            people: words.filter(people.contains),
            outcomes: words.filter(outcomes.contains)
        )
    }
}

enum MokoFollowUpRule: Equatable {
    case emotionNoAction, actionNoOutcome, outcomeNoEmotion, sparse, none
}

enum MokoDebriefRules {
    static func rule(for tokens: MokoDebriefTokens) -> MokoFollowUpRule {
        if tokens.words.count < 3 { return .sparse }
        if !tokens.emotions.isEmpty && tokens.actions.isEmpty { return .emotionNoAction }
        if !tokens.actions.isEmpty && tokens.outcomes.isEmpty { return .actionNoOutcome }
        if !tokens.outcomes.isEmpty && tokens.emotions.isEmpty { return .outcomeNoEmotion }
        return .none
    }

    static func fallback(for rule: MokoFollowUpRule) -> String {
        switch rule {
        case .emotionNoAction: return "What did you do despite that feeling?"
        case .actionNoOutcome: return "What happened next?"
        case .outcomeNoEmotion: return "How did that feel in the moment?"
        case .sparse: return "What was the hardest part?"
        case .none: return "What stands out most from that moment?"
        }
    }
}

enum MokoScoreValidation {
    static func valid(value: Int, evidence: String, answers: String) -> Bool {
        (1...5).contains(value) && !evidence.isEmpty && answers.range(of: evidence, options: .caseInsensitive) != nil
    }
}
