//
//  OverviewResumeScreen.swift
//  Moko
//
//  Overview content only. Insights card opens the radar info sheet,
//  Calm Down card pushes the Summary screen.
//

import SwiftUI
import SwiftData

struct OverviewResumeScreen: View {
    /// The quest whose debrief is waiting to be finished.
    var quest: Quest? = nil

    // Insights flow: card -> info sheet -> InsightsView (pushed)
    @State private var showRadarInfo: Bool = false
    @State private var openInsights: Bool = false
    @State private var showInsights: Bool = false

    // Optional callback: opens the debrief that was left unfinished
    var onSlideResume: (() -> Void)? = nil

    // MARK: - State Properties
    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]

    private var data: OverviewData {
        OverviewData(insights: insights, calmDowns: calmDowns)
    }

    /// Where the saved conversation stopped, so the user knows nothing was lost.
    private var resumeDescription: String {
        guard let quest, let draft = DebriefDraftStore.load(for: quest.id) else {
            return "Pick up where you left off and share how it went."
        }

        let total = DebriefSession.followUpCount + 1
        let answered = min(draft.answers.count, total)
        if answered == 0 {
            return "Your debrief is saved. Slide to answer the first question."
        }
        return "\(answered) of \(total) answers saved. Slide to pick up where you left off."
    }

    // Palette matching design specifications
    private let primaryGreen = MocoScreenTheme.Colors.dataVioletDeep // #1B422F
    private let titleDark = MocoScreenTheme.Colors.textTitle // #5C4330
    private let subtextGray = MocoScreenTheme.Colors.textBody // #6F6762

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MocoBackdrop()

                // Scrollable Content Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: - Header
                        headerSection
                            .padding(.horizontal, MocoScreenTheme.Space.page)
                            .padding(.top, 14)

                        // MARK: - Today's Mission Section
                        todaysMissionSection
                            .padding(.top, 28)
                            .padding(.horizontal, MocoScreenTheme.Space.page)

                        // MARK: - Statistics Section
                        statisticsSection
                            .padding(.top, 28)
                            .padding(.horizontal, MocoScreenTheme.Space.page)
                            .padding(.bottom, 24)
                    }
                }
            }
            // This screen keeps its own header; pushed screens get the default bar and back button
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
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Overview")
                .mocoText(MocoScreenTheme.Typeface.title1)
                .foregroundColor(MocoScreenTheme.Colors.textTitle)

            Spacer()

            // Avatar Circle: opens the Profile screen
            NavigationLink {
                ProfileOverView()
            } label: {
                ZStack {
                    Circle()
                        .fill(MocoScreenTheme.Colors.avatarFill)
                        .frame(width: MocoScreenTheme.Size.avatar, height: MocoScreenTheme.Size.avatar)

                    if let name = profiles.first?.username, !name.isEmpty {
                        Text(String(name.prefix(2)).uppercased())
                            .mocoText(MocoScreenTheme.Typeface.slider)
                            .foregroundColor(MocoScreenTheme.Colors.avatarText)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(MocoScreenTheme.Colors.avatarText)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Today's Mission Section
    private var todaysMissionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mission")
                .mocoText(MocoScreenTheme.Typeface.title2)
                .foregroundColor(titleDark)

            VStack(alignment: .leading, spacing: 0) {
                // Mission Title
                Text(quest?.title ?? "Unfinished Debrief")
                    .mocoText(MocoScreenTheme.Typeface.section)
                    .foregroundColor(primaryGreen)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                // Mission Subtitle / Description
                Text(resumeDescription)
                    .mocoText(MocoScreenTheme.Typeface.body)
                    .foregroundColor(subtextGray)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                // The pill opens the unfinished debrief straight away — no second button
                MocoSlideControl(label: "Slide to Resume") {
                    onSlideResume?()
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mocoCard()
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Growth")
                .mocoText(MocoScreenTheme.Typeface.title2)
                .foregroundColor(titleDark)

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

    // MARK: - Insights Card
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Top Row
            HStack(alignment: .center) {
                Text("Insights")
                    .mocoText(MocoScreenTheme.Typeface.section)
                    .foregroundColor(primaryGreen)

                Spacer()

                HStack(spacing: 4) {
                    Text(Date.now.formatted(
                        .dateTime
                            .locale(Locale(identifier: "en_US"))
                            .month(.abbreviated)
                            .day()
                    ))
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundColor(titleDark)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(titleDark)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            // Card Content: Number + Radar Chart
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(Int(data.insights.warmth.rounded()))")
                        .mocoText(MocoScreenTheme.Typeface.numeral)
                        .foregroundColor(primaryGreen)

                    Text("warmth")
                        .mocoText(MocoScreenTheme.Typeface.unit)
                        .foregroundColor(primaryGreen)
                }
                .padding(.bottom, 6)

                Spacer()

                // Radar / Diamond Shape Chart
                MocoRadarChart(scores: data.insights)
                    .frame(width: MocoScreenTheme.Size.radar, height: MocoScreenTheme.Size.radar)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MocoScreenTheme.Radius.card, style: .continuous))
        .mocoCard()
    }

    // MARK: - Calm Down Card
    private var calmDownCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Top Row
            HStack(alignment: .center) {
                Text("Calm Down")
                    .mocoText(MocoScreenTheme.Typeface.section)
                    .foregroundColor(primaryGreen)

                Spacer()

                HStack(spacing: 4) {
                    Text(Date.now.formatted(
                        .dateTime
                            .locale(Locale(identifier: "en_US"))
                            .month(.abbreviated)
                            .day()
                    ))
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .foregroundColor(titleDark)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(titleDark)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            // Card Content: Number + Bar Chart
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(data.calmDownMinutes)")
                        .mocoText(MocoScreenTheme.Typeface.numeral)
                        .foregroundColor(primaryGreen)

                    Text("min")
                        .mocoText(MocoScreenTheme.Typeface.unit)
                        .foregroundColor(primaryGreen)
                }
                .padding(.bottom, 6)

                Spacer()

                // Bar Chart Visual
                MocoBarChart(values: data.calmDownBars)
                    .frame(width: MocoScreenTheme.Size.barChart.width, height: MocoScreenTheme.Size.barChart.height)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MocoScreenTheme.Radius.card, style: .continuous))
        .mocoCard()
    }
}

#Preview {
    OverviewResumeScreen()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
