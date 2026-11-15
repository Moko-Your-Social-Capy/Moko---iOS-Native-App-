//
//  InsightsView.swift
//  Moko
//
//  Insights screen: Day / Week / Month picker, radar chart of the four
//  parameters, overall score and a card per parameter.
//  Scores are averaged from the InsightsModel records saved in SwiftData.
//
//  Flow: a debrief saves an `InsightsModel` → `@Query` below picks it up →
//  `InsightsScores` averages the records for the chosen range → the cards draw them.
//  Debug tip: the preview at the bottom fills the screen with sample records.
//

import SwiftUI
import SwiftData

// MARK: - Model

enum InsightsRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    /// Calendar unit used to find "today", "this week" or "this month"
    var component: Calendar.Component {
        switch self {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        case .year:  return .year
        }
    }
}

/// Average score of each parameter over a set of records.
struct InsightsScores {
    let clarity: Double
    let courage: Double
    let presence: Double
    let warmth: Double

    /// No saved entries
    static let zero = InsightsScores(clarity: 0, courage: 0, presence: 0, warmth: 0)

    /// Average of the four parameter averages
    var overall: Double { (clarity + courage + presence + warmth) / 4 }

    init(clarity: Double, courage: Double, presence: Double, warmth: Double) {
        self.clarity = clarity
        self.courage = courage
        self.presence = presence
        self.warmth = warmth
    }

    /// Each parameter = (sum of its scores) / (number of records). No records = 0.
    init(records: [InsightsModel]) {
        guard !records.isEmpty else {
            self = .zero
            return
        }

        let count = Double(records.count)
        clarity  = Double(records.reduce(0) { $0 + $1.clarity })  / count
        courage  = Double(records.reduce(0) { $0 + $1.courage })  / count
        presence = Double(records.reduce(0) { $0 + $1.presence }) / count
        warmth   = Double(records.reduce(0) { $0 + $1.warmth })   / count
    }
}

/// Everything one parameter card shows.
struct InsightsParameter: Identifiable {
    let name: String
    let score: Double
    /// "Core Strength", "Grounded & Steady" or "Growth Focus".
    let bandTitle: String
    let badgeColor: Color
    /// What the parameter means, in one line.
    let detail: String
    /// Advice for the user's current band.
    let analysis: String
    /// The relax exercise that helps this parameter.
    let supportedBy: String

    // The name never changes, so SwiftUI can animate the same card when the range changes.
    var id: String { name }
}

// MARK: - Screen

struct InsightsView: View {
    /// Every saved record, newest first. The selected range is filtered below.
    @Query(sort: \InsightsModel.date, order: .reverse) private var records: [InsightsModel]

    // Which segment is picked: Day, Week, Month or Year.
    @State private var range: InsightsRange = .day

    private let accent    = MokoScreenTheme.Colors.dataVioletDeep
    private let soft      = MokoScreenTheme.Colors.surfaceLavender
    private let titleDark = MokoScreenTheme.Colors.textTitle
    private let gray      = MokoScreenTheme.Colors.textBody

    /// Records that fall in today / this week / this month / this year.
    private var rangeRecords: [InsightsModel] {
        guard let interval = Calendar.current.dateInterval(of: range.component, for: Date()) else {
            return []
        }
        return records.filter { interval.contains($0.date) }
    }

    /// Scores for the chosen range. If that range has no records yet, the all-time
    /// average is shown instead, so the screen isn't empty (the note explains this).
    private var scores: InsightsScores {
        if !rangeRecords.isEmpty {
            return InsightsScores(records: rangeRecords)
        }
        if !records.isEmpty {
            return InsightsScores(records: records)
        }
        return .zero
    }

    private var parameters: [InsightsParameter] {
        [
            parameterData(for: .courage, score: scores.courage),
            parameterData(for: .clarity, score: scores.clarity),
            parameterData(for: .presence, score: scores.presence),
            parameterData(for: .warmth, score: scores.warmth)
        ]
    }

    /// Builds one card's text and colours from the parameter and its score.
    private func parameterData(for stat: Stat, score: Double) -> InsightsParameter {
        let rounded = Int(score.rounded())
        let band = Band(score: rounded)

        let bandTitle: String
        switch band {
        case .strength: bandTitle = "Core Strength"
        case .steady:   bandTitle = "Grounded & Steady"
        case .growth:   bandTitle = "Growth Focus"
        }
        // "Growth Focus" uses a softer colour so it doesn't read as a warning.
        let badgeColor = band == .growth ? MokoScreenTheme.Colors.textBody : accent

        let detail: String
        let analysis: String
        let supportedBy: String

        switch stat {
        case .courage:
            detail = "Moving toward social moments instead of stepping back."
            supportedBy = "Reflection & Debrief"
            switch band {
            case .strength:
                analysis = "You consistently step in rather than sit back. Keep building this momentum by continuing to speak first in unfamiliar settings."
            case .steady:
                analysis = "You engage well when the moment feels right. Taking initiative just a few seconds earlier can help carry this confidence into higher-pressure situations."
            case .growth:
                analysis = "Starting an interaction can feel daunting, which is completely natural. Try making one small first move—like a quick greeting or simple question—to build ease."
            }

        case .clarity:
            detail = "Saying what you mean, directly, without hedging or over-explaining."
            supportedBy = "Grounding Exercise"
            switch band {
            case .strength:
                analysis = "You speak with clear directness, which makes you easy to understand and trust. Keep trusting your first sentence without over-explaining."
            case .steady:
                analysis = "You convey your core message well. Leading with your main point before offering background details will make your delivery even crisper."
            case .growth:
                analysis = "Saying what you genuinely mean can feel vulnerable at first. Practicing a single, short sentence without over-qualifying is a gentle way to grow."
            }

        case .presence:
            detail = "Being fully with the other person, not rehearsing or replaying in your head."
            supportedBy = "Box Breathing"
            switch band {
            case .strength:
                analysis = "You stay deeply grounded and tuned in to the person in front of you. Noticing concrete details about others keeps your conversations effortless."
            case .steady:
                analysis = "You hold strong presence in relaxed conversations. When your mind begins rehearsing what to say next, gently anchoring on the other person's voice brings you back."
            case .growth:
                analysis = "Replaying what was said or worrying about what to say is very common. Focusing on one concrete thing the other person is saying helps anchor you in the moment."
            }

        case .warmth:
            detail = "Genuine engagement — taking in the other person's world and sharing your own."
            supportedBy = "Mirror Reflection"
            switch band {
            case .strength:
                analysis = "You bring natural openness and care that makes others feel valued. Continue asking curious follow-up questions to deepen your connections."
            case .steady:
                analysis = "You are welcoming and considerate. Adding a personal follow-up question or sharing a small detail from your day will turn friendly chat into real warmth."
            case .growth:
                analysis = "Opening up takes time and self-trust, and that is okay. Sharing one small, genuine detail with someone you feel comfortable with is a wonderful start."
            }
        }

        return InsightsParameter(
            name: stat.title,
            score: score,
            bandTitle: bandTitle,
            badgeColor: badgeColor,
            detail: detail,
            analysis: analysis,
            supportedBy: supportedBy
        )
    }

    var body: some View {
        ZStack {
            MokoBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Range", selection: $range) {
                        ForEach(InsightsRange.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    radar

                    overallCard

                    Text("Social Pulse")
                        .mokoText(MokoScreenTheme.Typeface.section)
                        .foregroundStyle(titleDark)
                        .padding(.top, 8)

                    ForEach(parameters) { parameter in
                        parameterCard(parameter)
                    }
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(MokoScreenTheme.Colors.dataVioletDeep)
        // Smoothly updates the numbers and bars when another range is picked.
        .animation(.easeInOut, value: range)
    }

    // MARK: Radar chart

    /// The radar chart with a name + score label on each of its four sides.
    private var radar: some View {
        VStack(spacing: 8) {
            label("Courage", scores.courage)

            HStack {
                label("Clarity", scores.clarity)

                MokoRadarChart(scores: scores)
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityHidden(true)

                label("Presence", scores.presence)
            }

            label("Warmth", scores.warmth)
        }
        .padding(MokoScreenTheme.Space.cardHorizontal)
        .mokoCard()
    }

    /// "Courage" above its score. VoiceOver reads both together.
    private func label(_ name: String, _ score: Double) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(titleDark)
            Text("\(Int(score.rounded()))")
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(gray)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Overall

    private var overallCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Overall")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(gray)
                Text("\(Int(scores.overall.rounded()))")
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .foregroundStyle(accent)
            }

            Text(overallNote)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(gray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mokoCard(fill: soft)
    }

    /// The sentence next to the overall score. Explains where the number comes from.
    private var overallNote: String {
        let count = rangeRecords.count
        if count == 0 {
            if !records.isEmpty {
                return "Showing your all-time average across \(records.count) \(records.count == 1 ? "session" : "sessions"). Complete more quests to populate \(range.rawValue.lowercased()) data."
            }
            return "Complete your first quest and debrief to see your scores here."
        }
        let overall = Int(scores.overall.rounded())
        let rangeLabel = range == .day ? "today" : "this \(range.rawValue.lowercased())"
        let summaryLine: String
        switch overall {
        case 80...100: summaryLine = "Excellent across the board."
        case 65...79:  summaryLine = "Consistently strong performance."
        case 50...64:  summaryLine = "Solid foundation with clear growth areas."
        default:       summaryLine = "Early stages — every session builds momentum."
        }
        return "\(summaryLine) Average of \(count) \(count == 1 ? "entry" : "entries") for \(rangeLabel)."
    }

    // MARK: Parameter card

    private func parameterCard(_ parameter: InsightsParameter) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: name + score + band badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(parameter.name)
                        .mokoText(MokoScreenTheme.Typeface.section)
                        .foregroundStyle(titleDark)
                    Text(parameter.bandTitle)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(parameter.badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(soft, in: Capsule())
                }
                Spacer()
                Text("\(Int(parameter.score.rounded()))")
                    .mokoText(MokoScreenTheme.Typeface.numeral)
                    .foregroundStyle(accent)
            }

            // Progress bar
            ProgressView(value: parameter.score, total: 100)
                .tint(accent)

            Divider()

            // What this parameter means
            Text(parameter.detail)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(gray)
                .fixedSize(horizontal: false, vertical: true)

            // Personalised analysis
            VStack(alignment: .leading, spacing: 6) {
                Label("Analysis", systemImage: "brain.head.profile")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(accent)
                Text(parameter.analysis)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Supported-by tag
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accent)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .accessibilityHidden(true)
                Text("Supported by \(parameter.supportedBy)")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(gray)
            }
        }
        .padding(20)
        .mokoCard()
    }
}

// MARK: - Preview with sample records

#Preview {
    // An in-memory database, so preview data never touches the real app data.
    guard let container = try? ModelContainer(
        for: InsightsModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return Text("Preview database could not be created")
    }

    // Two entries today (average: clarity 56, courage 32, presence 42, warmth 78)
    // plus earlier entries so Week and Month differ from Day.
    let calendar = Calendar.current
    let samples: [(daysAgo: Int, clarity: Int, courage: Int, presence: Int, warmth: Int)] = [
        (0, 50, 30, 40, 74),
        (0, 62, 34, 44, 82),
        (2, 70, 50, 62, 84),
        (4, 78, 58, 74, 90),
        (12, 85, 76, 80, 92)
    ]
    for sample in samples {
        let date = calendar.date(byAdding: .day, value: -sample.daysAgo, to: Date()) ?? Date()
        container.mainContext.insert(
            InsightsModel(courage: sample.courage,
                          clarity: sample.clarity,
                          presence: sample.presence,
                          warmth: sample.warmth,
                          date: date)
        )
    }

    return NavigationStack {
        InsightsView()
    }
    .modelContainer(container)
}
