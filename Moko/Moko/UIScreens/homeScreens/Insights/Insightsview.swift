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
import Lottie

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
    @State private var showOverallSparkles = false
    @State private var overallSparklesVersion = 0

    private typealias Theme = MokoScreenTheme
    
    // Dark theme aware colors
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool { colorScheme == .dark }
    
    private var accent: Color {
        isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage
    }
    
    private var soft: Color {
        isDarkMode ? Color(hex: 0x1E2D23) : Theme.Colors.surfaceLavender
    }
    
    private var titleColor: Color {
        isDarkMode ? Color(hex: 0xE6F0E8) : Theme.Colors.textTitle
    }
    
    private var bodyColor: Color {
        isDarkMode ? Color(hex: 0xB8C6BB) : Theme.Colors.textBody
    }
    
    private var mutedColor: Color {
        isDarkMode ? Color(hex: 0x8A978D) : Theme.Colors.textMuted
    }

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
        // Use score-based color (yellow/red/green logic)
        let badgeColor = colorForScore(score)

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
                    // MARK: - Range Picker (Clean, no shadow/gradient)
                    Picker("Range", selection: $range) {
                        ForEach(InsightsRange.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage)

                    if records.isEmpty {
                        VStack(spacing: 12) {
                            MokoLottieView(animation: .empty, loopMode: .loop)
                                .frame(width: 140, height: 140)

                            Text("Your insights will appear here")
                                .mokoText(Theme.Typeface.cardTitle)
                                .foregroundStyle(titleColor)

                            Text("Complete your first quest and debrief to start tracking your growth.")
                                .mokoText(Theme.Typeface.body)
                                .foregroundStyle(bodyColor)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    } else {
                        radar
                        overallCard

                        // Keep your existing Social Pulse heading and parameter cards here.
                    }

                    Text("Social Pulse")
                        .mokoText(Theme.Typeface.section)
                        .foregroundStyle(titleColor)
                        .padding(.top, 8)

                    ForEach(parameters.enumerated(), id: \.element.id) { index, parameter in
                        parameterCard(parameter)
                            .mokoReveal(index: index)
                    }
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage)
        .animation(.easeInOut, value: range)
        .onChange(of: scores.overall) { oldValue, newValue in
            guard newValue > oldValue, !records.isEmpty else {
                return
            }

            overallSparklesVersion += 1
            showOverallSparkles = true

            Task {
                try? await Task.sleep(for: .seconds(2))
                showOverallSparkles = false
            }
        }
    }

    // MARK: Radar chart

    /// Radar chart with its four labels at the axis ends:
    /// top Courage, bottom Clarity, left Presence, right Warmth.
    private var radar: some View {
        InsightsAxisRadar(courage: scores.courage,
                          warmth: scores.warmth,
                          clarity: scores.clarity,
                          presence: scores.presence)
            .frame(maxWidth: 420)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(MokoScreenTheme.Space.cardHorizontal)
            .mokoCard()
    }

    // MARK: Overall

    private var overallCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Overall")
                    .mokoText(Theme.Typeface.caption)
                    .foregroundStyle(bodyColor)
                Text("\(Int(scores.overall.rounded()))")
                    .mokoText(Theme.Typeface.numeral)
                    .foregroundStyle(overallColor)
                    .contentTransition(.numericText())
            }

            Text(overallNote)
                .mokoText(Theme.Typeface.body)
                .foregroundStyle(bodyColor)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(isDarkMode ? Color(hex: 0x1A231E) : soft)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(overallColor.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Theme.Elevation.nearColor,
                radius: isDarkMode ? 8 : Theme.Elevation.nearRadius,
                x: 0, y: isDarkMode ? 4 : Theme.Elevation.nearOffset)
    }

    /// Red below 40, yellow below 70, green from 70 up.
    private var overallColor: Color {
        colorForScore(scores.overall)
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
        let parameterColor = colorForParameter(parameter.name)
        let scoreColor = colorForScore(parameter.score)
        
        return VStack(alignment: .leading, spacing: 14) {
            // Header: name + score + band badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Color-coded title based on parameter
                    Text(parameter.name)
                        .mokoText(Theme.Typeface.section)
                        .foregroundStyle(parameterColor)
                    Text(parameter.bandTitle)
                        .mokoText(Theme.Typeface.caption)
                        .foregroundStyle(scoreColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(soft, in: Capsule())
                }
                Spacer()
                Text("\(Int(parameter.score.rounded()))")
                    .mokoText(Theme.Typeface.numeral)
                    .foregroundStyle(scoreColor)
            }

            // Progress bar with parameter-specific color
            ProgressView(value: parameter.score, total: 100)
                .tint(parameterColor)
                .background(parameterColor.opacity(0.2))

            Divider()
                .background(bodyColor.opacity(0.3))

            // What this parameter means
            Text(parameter.detail)
                .mokoText(Theme.Typeface.body)
                .foregroundStyle(bodyColor)
                .fixedSize(horizontal: false, vertical: true)

            // Personalised analysis
            VStack(alignment: .leading, spacing: 6) {
                Label("Analysis", systemImage: "brain.head.profile")
                    .mokoText(Theme.Typeface.caption)
                    .foregroundStyle(parameterColor)
                Text(parameter.analysis)
                    .mokoText(Theme.Typeface.body)
                    .foregroundStyle(bodyColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(isDarkMode ? Color(hex: 0x1A231E) : Theme.Colors.surfaceWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(parameterColor.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Theme.Elevation.nearColor,
                radius: isDarkMode ? 8 : Theme.Elevation.nearRadius,
                x: 0, y: isDarkMode ? 4 : Theme.Elevation.nearOffset)
    }
    
    /// Returns color-coded tint for each parameter with dark theme support
    private func colorForParameter(_ name: String) -> Color {
        switch name {
        case "Courage":
            return isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage
        case "Clarity":
            return isDarkMode ? Theme.Colors.parameterClarityDark : Theme.Colors.parameterClarity
        case "Presence":
            return isDarkMode ? Theme.Colors.parameterPresenceDark : Theme.Colors.parameterPresence
        case "Warmth":
            return isDarkMode ? Theme.Colors.parameterWarmthDark : Theme.Colors.parameterWarmth
        default:
            return accent
        }
    }
    
    /// Returns score-based color (yellow/red/green logic) with dark theme support
    private func colorForScore(_ score: Double) -> Color {
        if score < 40 {
            return isDarkMode ? Theme.Colors.scoreNeedsImprovementDark : Theme.Colors.scoreNeedsImprovement
        } else if score < 70 {
            return isDarkMode ? Theme.Colors.scoreGoodDark : Theme.Colors.scoreGood
        } else {
            return isDarkMode ? Theme.Colors.scoreExcellentDark : Theme.Colors.scoreExcellent
        }
    }
}

// MARK: - Preview with sample records

#Preview {
    // An in-memory database, so preview data never touches the real app data.
    guard let container = try? ModelContainer(
        for: InsightsModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return AnyView(Text("Preview database could not be created"))
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

    return AnyView(
        NavigationStack {
            InsightsView()
        }
        .modelContainer(container)
    )
}


// MARK: - Radar chart with labels at the axes

/// Four-axis radar. Vertex order is top, right, bottom, left:
///   top Courage, right Warmth, bottom Clarity, left Presence.
/// Scores are 0–100 and are clamped, so the shape never leaves the outer ring.
/// The four names sit outside the chart at the end of their axis, and the radius
/// is worked out from the available size so nothing is clipped on any device.
private struct InsightsAxisRadar: View {
    let courage: Double
    let warmth: Double
    let clarity: Double
    let presence: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool { colorScheme == .dark }
    private typealias Theme = MokoScreenTheme

    private let levels: [Double] = [25, 50, 75, 100]
    private let sideLabelWidth: CGFloat = 66
    private let endLabelHeight: CGFloat = 44
    private let labelGap: CGFloat = 8

    private var grid: Color {
        isDarkMode ? Theme.Colors.parameterCourageDark.opacity(0.2) : Theme.Colors.parameterCourage.opacity(0.25)
    }
    
    private var fillColor: Color {
        isDarkMode ? Theme.Colors.parameterCourageDark.opacity(0.15) : Theme.Colors.parameterCourage.opacity(0.22)
    }
    
    private var strokeColor: Color {
        isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage
    }

    /// 0...1 per axis, in the order top, right, bottom, left.
    private var fractions: [Double] {
        [courage, warmth, clarity, presence].map { min(max($0 / 100, 0), 1) }
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = max(30, min(geo.size.width / 2 - sideLabelWidth - labelGap,
                                     geo.size.height / 2 - endLabelHeight - labelGap))

            ZStack {
                // Rings: 25 / 50 / 75 dashed, 100 solid
                ForEach(levels, id: \.self) { level in
                    InsightsRadarShape(fractions: Array(repeating: level / 100, count: 4))
                        .stroke(grid, style: StrokeStyle(lineWidth: 1,
                                                         dash: level == 100 ? [] : [3, 3]))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                // Axes
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    path.move(to: CGPoint(x: center.x - radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                }
                .stroke(grid, lineWidth: 1)

                // Level numbers beside the upper half of the vertical axis
                ForEach(levels, id: \.self) { level in
                    Text("\(Int(level))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .position(x: center.x + 12, y: center.y - radius * level / 100 + 7)
                }

                // Value polygon
                InsightsRadarShape(fractions: fractions)
                    .fill(fillColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                InsightsRadarShape(fractions: fractions)
                    .stroke(strokeColor,
                            style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Dots where each score meets its axis
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(strokeColor)
                        .frame(width: 8, height: 8)
                        .position(dot(index, center, radius))
                }

                // Names + scores outside the chart, at the end of each axis
                endLabel("Courage", courage)
                    .position(x: center.x,
                              y: center.y - radius - labelGap - endLabelHeight / 2)
                endLabel("Clarity", clarity)
                    .position(x: center.x,
                              y: center.y + radius + labelGap + endLabelHeight / 2)
                sideLabel("Presence", presence, alignment: .trailing)
                    .position(x: center.x - radius - labelGap - sideLabelWidth / 2,
                              y: center.y)
                sideLabel("Warmth", warmth, alignment: .leading)
                    .position(x: center.x + radius + labelGap + sideLabelWidth / 2,
                              y: center.y)
            }
        }
        // Smooth, subtle polygon update when the range (Day / Week / Month / Year) changes.
        .animation(.smooth(duration: 0.6), value: fractions)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Courage \(Int(courage.rounded())), Warmth \(Int(warmth.rounded())), Clarity \(Int(clarity.rounded())), Presence \(Int(presence.rounded()))")
    }

    private func endLabel(_ name: String, _ score: Double) -> some View {
        labelContent(name, score, textAlignment: .center)
            .frame(width: 110, height: endLabelHeight)
    }

    private func sideLabel(_ name: String, _ score: Double, alignment: Alignment) -> some View {
        labelContent(name, score, textAlignment: alignment == .trailing ? .trailing : .leading)
            .frame(width: sideLabelWidth, height: endLabelHeight, alignment: alignment)
    }

    private func labelContent(_ name: String, _ score: Double, textAlignment: HorizontalAlignment) -> some View {
        VStack(alignment: textAlignment, spacing: 1) {
            Text(name)
                .mokoText(Theme.Typeface.caption)
                .foregroundStyle(colorForParameterName(name))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("\(Int(score.rounded()))")
                .mokoText(Theme.Typeface.body)
                .fontWeight(.semibold)
                .foregroundStyle(colorForScore(score))
                .contentTransition(.numericText())
        }
    }
    
    private func colorForParameterName(_ name: String) -> Color {
        switch name {
        case "Courage":
            return isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage
        case "Clarity":
            return isDarkMode ? Theme.Colors.parameterClarityDark : Theme.Colors.parameterClarity
        case "Presence":
            return isDarkMode ? Theme.Colors.parameterPresenceDark : Theme.Colors.parameterPresence
        case "Warmth":
            return isDarkMode ? Theme.Colors.parameterWarmthDark : Theme.Colors.parameterWarmth
        default:
            return isDarkMode ? Theme.Colors.parameterCourageDark : Theme.Colors.parameterCourage
        }
    }
    
    private func colorForScore(_ score: Double) -> Color {
        if score < 40 {
            return isDarkMode ? Theme.Colors.scoreNeedsImprovementDark : Theme.Colors.scoreNeedsImprovement
        } else if score < 70 {
            return isDarkMode ? Theme.Colors.scoreGoodDark : Theme.Colors.scoreGood
        } else {
            return isDarkMode ? Theme.Colors.scoreExcellentDark : Theme.Colors.scoreExcellent
        }
    }

    /// Point on axis `index` (0 top, 1 right, 2 bottom, 3 left) at the score's distance.
    private func dot(_ index: Int, _ center: CGPoint, _ radius: CGFloat) -> CGPoint {
        let d = CGFloat(fractions[index]) * radius
        switch index {
        case 0:  return CGPoint(x: center.x, y: center.y - d)
        case 1:  return CGPoint(x: center.x + d, y: center.y)
        case 2:  return CGPoint(x: center.x, y: center.y + d)
        default: return CGPoint(x: center.x - d, y: center.y)
        }
    }
}

/// Diamond with one vertex per axis (top, right, bottom, left) at the given 0–1 fractions.
/// Conforms to Animatable so the polygon morphs smoothly between two score sets.
private struct InsightsRadarShape: Shape {
    var fractions: [Double]

    var animatableData: InsightsAnimatableVector {
        get { InsightsAnimatableVector(values: fractions) }
        set { fractions = newValue.values }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let f = fractions + Array(repeating: 0, count: max(0, 4 - fractions.count))
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - r * f[0]))
        path.addLine(to: CGPoint(x: c.x + r * f[1], y: c.y))
        path.addLine(to: CGPoint(x: c.x, y: c.y + r * f[2]))
        path.addLine(to: CGPoint(x: c.x - r * f[3], y: c.y))
        path.closeSubpath()
        return path
    }
}

/// Lets SwiftUI animate an array of numbers.
private struct InsightsAnimatableVector: VectorArithmetic {
    var values: [Double]

    static var zero: InsightsAnimatableVector { InsightsAnimatableVector(values: []) }

    static func + (l: InsightsAnimatableVector, r: InsightsAnimatableVector) -> InsightsAnimatableVector {
        combine(l, r, +)
    }
    static func - (l: InsightsAnimatableVector, r: InsightsAnimatableVector) -> InsightsAnimatableVector {
        combine(l, r, -)
    }
    private static func combine(_ l: InsightsAnimatableVector, _ r: InsightsAnimatableVector,
                                _ op: (Double, Double) -> Double) -> InsightsAnimatableVector {
        let n = max(l.values.count, r.values.count)
        return InsightsAnimatableVector(values: (0..<n).map {
            op($0 < l.values.count ? l.values[$0] : 0, $0 < r.values.count ? r.values[$0] : 0)
        })
    }
    mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }
    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }
}
