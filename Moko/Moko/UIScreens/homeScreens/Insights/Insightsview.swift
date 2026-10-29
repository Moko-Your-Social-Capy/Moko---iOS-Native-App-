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

    var id: String { rawValue }

    /// Calendar unit used to find "today", "this week" or "this month"
    var component: Calendar.Component {
        switch self {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        }
    }
}

/// Average score of each parameter over a set of records.
struct InsightsScores {
    let clarity: Double
    let courage: Double
    let presence: Double
    let warmth: Double

    /// Average of the four parameter averages
    var overall: Double { (clarity + courage + presence + warmth) / 4 }

    /// Each parameter = (sum of its scores) / (number of records). No records = 0.
    init(records: [InsightsModel]) {
        guard !records.isEmpty else {
            clarity = 0; courage = 0; presence = 0; warmth = 0
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
    let detail: String
    let supportedBy: String
}

// MARK: - Screen

struct InsightsView: View {
    /// Every saved record, newest first. The selected range is filtered below.
    @Query(sort: \InsightsModel.date, order: .reverse) private var records: [InsightsModel]

    @State private var range: InsightsRange = .day

    private let screenBg  = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let green     = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    private let mint      = Color(red: 203/255, green: 230/255, blue: 211/255)
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255)    // #2F2A28
    private let gray      = Color(red: 111/255, green: 103/255, blue: 98/255)  // #6F6762

    /// Axis marks from the center outwards (the outer diamond is 100).
    private let ticks = Array(stride(from: 10, through: 100, by: 10))

    /// Records that fall in today / this week / this month
    private var rangeRecords: [InsightsModel] {
        guard let interval = Calendar.current.dateInterval(of: range.component, for: Date()) else {
            return []
        }
        return records.filter { interval.contains($0.date) }
    }

    private var scores: InsightsScores { InsightsScores(records: rangeRecords) }

    private var parameters: [InsightsParameter] {
        [
            InsightsParameter(name: "Clarity", score: scores.clarity,
                              detail: "How clearly you notice your thoughts and feelings.",
                              supportedBy: "Grounding"),
            InsightsParameter(name: "Courage", score: scores.courage,
                              detail: "How readily you take on things that feel uncomfortable.",
                              supportedBy: "Reflection"),
            InsightsParameter(name: "Presence", score: scores.presence,
                              detail: "How fully you stay with the moment you are in.",
                              supportedBy: "Breathing"),
            InsightsParameter(name: "Warmth", score: scores.warmth,
                              detail: "How kindly you treat yourself and others.",
                              supportedBy: "Body awareness")
        ]
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

                    Text("Your four parameters")
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
            return "No data yet. Your scores appear after sessions."
        }
        return "Average of \(count) \(count == 1 ? "entry" : "entries") for \(range == .day ? "today" : "this \(range.rawValue.lowercased())")."
    }

    // MARK: Parameter card

    private func parameterCard(_ parameter: InsightsParameter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(parameter.name)
                    .font(.title3.bold())
                    .foregroundStyle(titleDark)
                Spacer()
                Text("\(Int(parameter.score.rounded()))")
                    .font(.title.bold())
                    .foregroundStyle(titleDark)
            }

            ProgressView(value: parameter.score, total: 100)
                .tint(green)

            Text(parameter.detail)
                .font(.subheadline)
                .foregroundStyle(gray)

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
