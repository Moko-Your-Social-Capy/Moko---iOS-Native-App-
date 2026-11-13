//
//  TodoOverviewScreen.swift
//  Moko
//
//  Overview content only. Calm Down card pushes the Summary screen.
//

import SwiftUI
import SwiftData

private typealias Theme = MocoScreenTheme

struct Overview: View {
    @Binding var selectedTab: MokoTab

    /// The real quest shown as today's mission. Nil means there is nothing active.
    let mission: Quest?

    // Called with the mission when the user starts its debrief
    var onStartDebrief: ((Quest) -> Void)? = nil

    init(selectedTab: Binding<MokoTab> = .constant(.overview),
         mission: Quest? = nil,
         onStartDebrief: ((Quest) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.mission = mission
        self.onStartDebrief = onStartDebrief
    }

    // MARK: - State Properties
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]
    @Query(sort: \Quest.date, order: .reverse) private var allQuests: [Quest]

    @State private var showRadarInfo: Bool = false      // "How your radar chart works" sheet
    @State private var openInsights: Bool = false       // set by the sheet's button
    @State private var showInsights: Bool = false       // pushes InsightsView
    @State private var showProfile: Bool = false
    /// Set from the slide until the debrief cover has taken over, so the pill cannot flip
    /// to "Slide to Debrief" in the frames between completing and the cover appearing.
    @State private var isHandingOffToDebrief: Bool = false

    private var data: OverviewData {
        OverviewData(insights: insights, calmDowns: calmDowns)
    }

    /// The active quest to display. If no custom quest was explicitly passed in,
    /// checks database or falls back to today's daily mission from Mission Bank / AFM.
    private var activeMission: Quest {
        if let mission {
            return mission
        }
        if let existing = Quest.overviewMission(from: allQuests) {
            return existing
        }
        if let todayQuest = allQuests.first(where: { Calendar.current.isDateInToday($0.date) && !$0.isFromLibrary }) {
            return todayQuest
        }
        return DailyMissionService.todayFallbackQuest(existingQuests: allQuests)
    }

    /// True once the quest is complete — reachable only by leaving a debrief behind, because
    /// completing the mission opens the debrief in the same slide.
    private var isMissionCompleted: Bool {
        activeMission.isCompleted
    }

    /// Held at "Slide to Complete" during the handoff so the label never flashes the next
    /// action before the debrief is on screen.
    private var slideTitle: String {
        isMissionCompleted && !isHandingOffToDebrief ? "Slide to Debrief" : "Slide to Complete"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // §5 Canvas: graded green, bush bottom-left, leaf right edge.
                MocoBackdrop()

                // Safe/Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection

                        missionSection
                            .padding(.top, Theme.Space.s7)

                        progressSection
                            .padding(.top, Theme.Space.s7)
                    }
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.bottom, Theme.Space.tabBand)
                }
            }
            // Overview keeps its own header; pushed screens get the default bar and back button
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showInsights) {
                InsightsView()
            }
            .sheet(isPresented: $showRadarInfo, onDismiss: {
                // Push Insights only after the sheet has fully closed
                if openInsights {
                    openInsights = false
                    showInsights = true
                }
            }) {
                RadarInfoSheet(onViewInsights: { openInsights = true })
            }
            .sheet(isPresented: $showProfile) {
                ProfileOverView()
                    .presentationDetents([.large])
                    /// The hero owns a close button, so the grabber would only
                    /// collide with the centred title.
                    .presentationDragIndicator(.hidden)
            }
            .task {
                await DailyMissionService.ensureDailyMission(in: modelContext, existingQuests: allQuests)
            }
        }
    }

    // MARK: - Header (§4 Header/Title + Avatar/User)

    private var headerSection: some View {
        HStack(alignment: .center, spacing: Theme.Space.s4) {
            Text("Overview")
                .mocoText(Theme.Typeface.title1)
                .foregroundStyle(Theme.Colors.textTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            avatarButton
        }
        .padding(.top, Theme.Space.s2)
    }

    private var avatarButton: some View {
        Button {
            showProfile = true
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Colors.avatarFill)

                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: Theme.Line.hair)

                avatarGlyph
            }
            .frame(width: Theme.Size.avatar, height: Theme.Size.avatar)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile")
    }

    @ViewBuilder
    private var avatarGlyph: some View {
        if let name = profiles.first?.username, !name.isEmpty {
            Text(String(name.prefix(2)).uppercased())
                .mocoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.avatarText)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: Theme.Glyph.avatar, weight: .semibold))
                .foregroundStyle(Theme.Colors.avatarText)
        }
    }

    // MARK: - Mission (§4 Section/Mission + Card/Mission)

    private var missionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapSection) {
            Text("Mission")
                .mocoText(Theme.Typeface.section)
                .foregroundStyle(Theme.Colors.textTitle)

            missionCard(for: activeMission)
        }
    }

    private func missionCard(for quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapInner) {
            Text(quest.title)
                .mocoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.textTitle)
                .fixedSize(horizontal: false, vertical: true)

            Text(missionDescription(for: quest))
                .mocoText(Theme.Typeface.body)
                .foregroundStyle(Theme.Colors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            missionAction(for: quest)
                .padding(.top, Theme.Space.gapSection)
        }
        .padding(.horizontal, Theme.Space.cardHorizontal)
        .padding(.vertical, Theme.Space.cardVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mocoCard()
        .animation(Theme.Motion.crossfade, value: isMissionCompleted)
    }

    /// One slide does the whole thing: the quest is completed (XP and streak awarded) and the
    /// debrief opens in the same gesture. Afterwards the same pill reads "Slide to Debrief".
    private func missionAction(for quest: Quest) -> some View {
        MocoSlideControl(label: slideTitle) {
            isHandingOffToDebrief = true
            if !isMissionCompleted {
                QuestProgress.complete(quest, in: modelContext)
            }
            openDebrief(for: quest)

            // The cover needs a beat to cover the card; only then may the pill reflect
            // the new state (it is behind the debrief by that point).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isHandingOffToDebrief = false
            }
        }
        // `MocoSlideControl` stays completed once slid, so a new label gets a fresh control:
        // "Slide to Debrief" must still be draggable after the cover closes.
        .id("\(quest.id)-\(slideTitle)")
    }

    private func openDebrief(for quest: Quest) {
        if quest.modelContext == nil {
            modelContext.insert(quest)
            try? modelContext.save()
        }
        onStartDebrief?(quest)
    }

    /// A description built from the quest's notes or category and intensity.
    private func missionDescription(for quest: Quest) -> String {
        let trimmed = quest.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return "A \(quest.intensity.rawValue.lowercased()) \(quest.category.rawValue.lowercased()) quest. Take your time and go at your pace."
    }

    // MARK: - Progress (§4 Section/Progress)

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapSection) {
            Text("Growth")
                .mocoText(Theme.Typeface.section)
                .foregroundStyle(Theme.Colors.textTitle)

            // Insights Card (opens the radar chart info sheet)
            insightsCard
                .onTapGesture {
                    showRadarInfo = true
                }

            // Calm Down Card (pushes the Summary screen)
            NavigationLink {
                SummaryView()
            } label: {
                calmDownCard
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Insights Card (§6.5)

    private var insightsCard: some View {
        progressCard {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeader(title: "Insights")

                    Spacer(minLength: Theme.Space.gapInner)

                    metric(value: "\(Int(data.insights.warmth.rounded()))", unit: "warmth")
                }

                MocoRadarChart(scores: data.insights)
                    .frame(width: Theme.Size.radar, height: Theme.Size.radar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Calm Down Card (§6.6)

    private var calmDownCard: some View {
        progressCard {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeader(title: "Calm Down")

                    Spacer(minLength: Theme.Space.gapInner)

                    metric(value: "\(data.calmDownMinutes)", unit: "min")
                }

                MocoBarChart(values: data.calmDownBars)
                    .frame(width: Theme.Size.barChart.width, height: Theme.Size.barChart.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }

    /// Shared shell for the two growth cards: one fill, full height, 18/20 insets.
    private func progressCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, Theme.Space.cardHorizontal)
            .padding(.vertical, Theme.Space.cardVertical)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.progressCard, alignment: .leading)
            .mocoCard()
    }

    private func cardHeader(title: String) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.s2) {
            Text(title)
                .mocoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.textTitle)

            Spacer(minLength: 0)

            HStack(spacing: Theme.Space.s1) {
                Text(Date.now.formatted(
                    .dateTime
                        .locale(Locale(identifier: "en_US"))
                        .month(.abbreviated)
                        .day()
                ))
                .mocoText(Theme.Typeface.caption)
                .foregroundStyle(Theme.Colors.textMuted)

                Image(systemName: "chevron.right")
                    .font(.system(size: Theme.Glyph.disclosure, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
    }

    private func metric(value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s1) {
            Text(value)
                .mocoText(Theme.Typeface.numeral)
                .foregroundStyle(Theme.Colors.dataNumeral)

            Text(unit)
                .mocoText(Theme.Typeface.unit)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }
}

// MARK: - Insights Radar Chart Component
struct InsightsRadarChartView: View {
    /// Today's real scores. Top = courage, right = presence,
    /// bottom = warmth, left = clarity.
    var scores: InsightsScores = .zero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let radiusX = w * 0.47
            let radiusY = h * 0.47

            // Data points from the real scores (100 = outer diamond)
            let topPt = CGPoint(x: center.x, y: center.y - radiusY * ratio(scores.courage))
            let rightPt = CGPoint(x: center.x + radiusX * ratio(scores.presence), y: center.y)
            let bottomPt = CGPoint(x: center.x, y: center.y + radiusY * ratio(scores.warmth))
            let leftPt = CGPoint(x: center.x - radiusX * ratio(scores.clarity), y: center.y)
            let points = [topPt, rightPt, bottomPt, leftPt]

            ZStack {
                // Background Outer Diamond
                DiamondShape()
                    .stroke(Color(red: 227/255, green: 232/255, blue: 227/255), lineWidth: 1.6)
                    .frame(width: w * 0.94, height: h * 0.94)

                // Inner Guide Diamond
                DiamondShape()
                    .stroke(Color(red: 227/255, green: 232/255, blue: 227/255), lineWidth: 1.2)
                    .frame(width: w * 0.47, height: h * 0.47)

                // Cross axes
                Path { path in
                    // Vertical axis
                    path.move(to: CGPoint(x: center.x, y: center.y - (h * 0.47)))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + (h * 0.47)))

                    // Horizontal axis
                    path.move(to: CGPoint(x: center.x - (w * 0.47), y: center.y))
                    path.addLine(to: CGPoint(x: center.x + (w * 0.47), y: center.y))
                }
                .stroke(Color(red: 203/255, green: 211/255, blue: 203/255), lineWidth: 1.4)

                Path { path in
                    path.move(to: topPt)
                    path.addLine(to: rightPt)
                    path.addLine(to: bottomPt)
                    path.addLine(to: leftPt)
                    path.closeSubpath()
                }
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 127/255, green: 163/255, blue: 140/255).opacity(0.18),
                            Color(red: 78/255, green: 122/255, blue: 95/255).opacity(0.58)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.5
                    )
                )

                Path { path in
                    path.move(to: topPt)
                    path.addLine(to: rightPt)
                    path.addLine(to: bottomPt)
                    path.addLine(to: leftPt)
                    path.closeSubpath()
                }
                .stroke(Color(red: 62/255, green: 92/255, blue: 74/255), lineWidth: 2.4)

                // Vertex Circles
                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 62/255, green: 92/255, blue: 74/255))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(points[index])
                }
            }
        }
    }

    private func ratio(_ score: Double) -> CGFloat {
        CGFloat(max(0, min(100, score)) / 100)
    }
}

// MARK: - Diamond Shape
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Calm Down Bar Chart Component
struct CalmDownBarChartView: View {
    /// Minutes for each bar, oldest first. The bars scale to the tallest day.
    var minutes: [Double] = Array(repeating: 0, count: 6)

    private let barColor = Color(red: 27/255, green: 66/255, blue: 47/255)
    private let barWidth: CGFloat = 5.7

    var body: some View {
        GeometryReader { geo in
            let peak = max(minutes.max() ?? 0, 1)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(minutes.indices, id: \.self) { index in
                    let value = minutes[index]

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor.opacity(value > 0 ? 1 : 0.15))
                        .frame(
                            width: barWidth,
                            height: barHeight(for: value, peak: peak, available: geo.size.height)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func barHeight(for value: Double, peak: Double, available: CGFloat) -> CGFloat {
        guard value > 0 else { return 2 }
        return max(2, available * CGFloat(value / peak))
    }
}

#Preview {
    Overview()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
