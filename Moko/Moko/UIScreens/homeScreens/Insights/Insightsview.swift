//
//  InsightsView.swift
//  Moko
//
//  Insights screen: Day / Week / Month picker, radar chart of the four
//  parameters, overall score and a card per parameter.
//  Scores are averaged from the InsightsModel records saved in SwiftData.
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

struct InsightsParameter: Identifiable {
    let id = UUID()
    let name: String
    let score: Double
    let bandTitle: String
    let badgeColor: Color
    let badgeBg: Color
    let detail: String
    let analysis: String
    let microAction: String
    let supportedBy: String
}

// MARK: - Screen

struct InsightsView: View {
    /// Every saved record, newest first. The selected range is filtered below.
    @Query(sort: \InsightsModel.date, order: .reverse) private var records: [InsightsModel]

    @State private var range: InsightsRange = .day

    private let screenBg  = MokoTheme.limeBackground // #F6FAE8
    private let green     = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    private let mint      = Color(red: 203/255, green: 230/255, blue: 211/255)
    private let titleDark = MokoTheme.titleBrown    // #5C4330
    private let gray      = Color(red: 111/255, green: 103/255, blue: 98/255)  // #6F6762

    /// Axis marks from the center outwards (the outer diamond is 100).
    private let ticks = [25, 50, 75, 100]

    /// Records that fall in today / this week / this month
    private var rangeRecords: [InsightsModel] {
        guard let interval = Calendar.current.dateInterval(of: range.component, for: Date()) else {
            return []
        }
        return records.filter { interval.contains($0.date) }
    }

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

    private func parameterData(for stat: Stat, score: Double) -> InsightsParameter {
        let rounded = Int(score.rounded())
        let band = Band(score: rounded)

        let bandTitle: String
        let badgeColor: Color
        let badgeBg: Color

        switch band {
        case .strength:
            bandTitle = "Core Strength"
            badgeColor = Color(red: 27/255, green: 66/255, blue: 47/255)
            badgeBg = Color(red: 203/255, green: 230/255, blue: 211/255)
        case .steady:
            bandTitle = "Grounded & Steady"
            badgeColor = Color(red: 45/255, green: 75/255, blue: 55/255)
            badgeBg = Color(red: 228/255, green: 238/255, blue: 228/255)
        case .growth:
            bandTitle = "Growth Focus"
            badgeColor = Color(red: 176/255, green: 78/255, blue: 58/255)
            badgeBg = Color(red: 252/255, green: 238/255, blue: 234/255)
        }

        let detail: String
        let analysis: String
        let microAction: String
        let supportedBy: String

        switch stat {
        case .courage:
            detail = "Moving toward social moments instead of stepping back."
            supportedBy = "Reflection & Debrief"
            microAction = "Be the first to speak or ask something today — even just a small hello."
            switch band {
            case .strength:
                analysis = "You consistently step in rather than sit back. That willingness is a real social asset."
            case .steady:
                analysis = "You engage well when it feels right — taking initiative just a touch earlier can open even more doors."
            case .growth:
                analysis = "Starting the interaction is the hardest part, and that's completely normal. One small move — a question, a hello — builds the habit."
            }

        case .clarity:
            detail = "Saying what you mean, directly, without hedging or over-explaining."
            supportedBy = "Grounding Exercise"
            microAction = "Lead with your main point in one sentence before explaining why."
            switch band {
            case .strength:
                analysis = "You communicate with real directness and that makes you easy to trust and understand."
            case .steady:
                analysis = "You land your message well — trusting your first sentence a bit more will make it even cleaner."
            case .growth:
                analysis = "Saying it plainly can feel awkward at first. One short, honest sentence is all it takes to get started."
            }

        case .presence:
            detail = "Being fully with the other person, not rehearsing or replaying in your head."
            supportedBy = "Box Breathing"
            microAction = "Notice one specific thing about the other person — their tone, expression, or what they just said."
            switch band {
            case .strength:
                analysis = "You stay genuinely tuned in to the moment and the person in front of you — that's rare and valuable."
            case .steady:
                analysis = "You hold strong presence in most conversations — catching yourself when your mind wanders keeps it consistent."
            case .growth:
                analysis = "Replaying conversations afterward is very common. Anchoring on one concrete thing the other person says brings you right back."
            }

        case .warmth:
            detail = "Genuine engagement — taking in the other person's world and sharing your own."
            supportedBy = "Mirror Reflection"
            microAction = "Ask one follow-up question today about something the other person mentioned."
            switch band {
            case .strength:
                analysis = "You make people feel genuinely seen and heard — that quality builds lasting connection."
            case .steady:
                analysis = "You're welcoming and kind — one curious follow-up question can deepen even a quick conversation."
            case .growth:
                analysis = "Opening up takes trust, and that's okay. Sharing one small detail with someone you feel comfortable with is a great first step."
            }
        }

        return InsightsParameter(
            name: stat.title,
            score: score,
            bandTitle: bandTitle,
            badgeColor: badgeColor,
            badgeBg: badgeBg,
            detail: detail,
            analysis: analysis,
            microAction: microAction,
            supportedBy: supportedBy
        )
    }

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

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
                        .font(.title3.bold())
                        .foregroundStyle(titleDark)
                        .padding(.top, 8)

                    ForEach(parameters) { parameter in
                        parameterCard(parameter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .animation(.easeInOut, value: range)
    }

    // MARK: Radar chart

    private var radar: some View {
        VStack(spacing: 8) {
            label("Courage", scores.courage)

            HStack {
                label("Clarity", scores.clarity)

                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let radius = min(geo.size.width, geo.size.height) / 2
                    let points = radarPoints(center: center, radius: radius)

                    ZStack {
                        DiamondShape()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        DiamondShape()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .scaleEffect(0.5)

                        // X and Y axes
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: center.y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: center.y))
                            path.move(to: CGPoint(x: center.x, y: 0))
                            path.addLine(to: CGPoint(x: center.x, y: geo.size.height))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)

                        // Tick marks: right of center (x) and above center (y)
                        Path { path in
                            for tick in ticks {
                                let offset = radius * CGFloat(tick) / 100
                                path.move(to: CGPoint(x: center.x + offset, y: center.y - 3))
                                path.addLine(to: CGPoint(x: center.x + offset, y: center.y + 3))
                                path.move(to: CGPoint(x: center.x - 3, y: center.y - offset))
                                path.addLine(to: CGPoint(x: center.x + 3, y: center.y - offset))
                            }
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)

                        Path { path in
                            path.addLines(points)
                            path.closeSubpath()
                        }
                        .fill(green.opacity(0.25))

                        Path { path in
                            path.addLines(points)
                            path.closeSubpath()
                        }
                        .stroke(green, lineWidth: 2)

                        ForEach(points.indices, id: \.self) { index in
                            Circle()
                                .fill(green)
                                .frame(width: 8, height: 8)
                                .position(points[index])
                        }

                        // Axis numbers
                        ForEach(ticks, id: \.self) { tick in
                            let offset = radius * CGFloat(tick) / 100

                            Text("\(tick)")
                                .font(.system(size: 7))
                                .foregroundStyle(gray)
                                .position(x: center.x + offset, y: center.y + 9)

                            Text("\(tick)")
                                .font(.system(size: 7))
                                .foregroundStyle(gray)
                                .position(x: center.x + 12, y: center.y - offset)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)

                label("Presence", scores.presence)
            }

            label("Warmth", scores.warmth)
        }
        .padding(.top, 8)
    }

    private func label(_ name: String, _ score: Double) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.subheadline.bold())
                .foregroundStyle(titleDark)
            Text("\(Int(score.rounded()))")
                .font(.subheadline)
                .foregroundStyle(gray)
        }
    }

    /// Top = Courage, right = Presence, bottom = Warmth, left = Clarity.
    private func radarPoints(center: CGPoint, radius: CGFloat) -> [CGPoint] {
        let courage  = radius * CGFloat(scores.courage) / 100
        let presence = radius * CGFloat(scores.presence) / 100
        let warmth   = radius * CGFloat(scores.warmth) / 100
        let clarity  = radius * CGFloat(scores.clarity) / 100

        return [
            CGPoint(x: center.x, y: center.y - courage),
            CGPoint(x: center.x + presence, y: center.y),
            CGPoint(x: center.x, y: center.y + warmth),
            CGPoint(x: center.x - clarity, y: center.y)
        ]
    }

    // MARK: Overall

    private var overallCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Overall")
                    .font(.footnote.bold())
                    .foregroundStyle(gray)
                Text("\(Int(scores.overall.rounded()))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(green)
            }

            Text(overallNote)
                .font(.footnote)
                .foregroundStyle(gray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(mint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

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
                        .font(.title3.bold())
                        .foregroundStyle(titleDark)
                    Text(parameter.bandTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(parameter.badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(parameter.badgeBg, in: Capsule())
                }
                Spacer()
                Text("\(Int(parameter.score.rounded()))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(green)
            }

            // Progress bar
            ProgressView(value: parameter.score, total: 100)
                .tint(green)

            Divider()

            // What this parameter means
            Text(parameter.detail)
                .font(.subheadline)
                .foregroundStyle(gray)
                .fixedSize(horizontal: false, vertical: true)

            // Personalised analysis
            VStack(alignment: .leading, spacing: 6) {
                Label("Analysis", systemImage: "brain.head.profile")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(green)
                Text(parameter.analysis)
                    .font(.subheadline)
                    .foregroundStyle(gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Daily micro-action
            VStack(alignment: .leading, spacing: 6) {
                Label("Today's Practice", systemImage: "figure.walk")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(green)
                Text(parameter.microAction)
                    .font(.subheadline)
                    .foregroundStyle(titleDark)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Supported-by tag
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(green)
                    .font(.caption)
                Text("Supported by \(parameter.supportedBy)")
                    .font(.caption)
                    .foregroundStyle(gray)
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Preview with sample records

#Preview {
    let container = try! ModelContainer(
        for: InsightsModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

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
