//
//  OverviewNoActiveQuestScreen.swift
//  Moko
//
//  Overview content only. Insights card opens the radar info sheet,
//  Calm Down card pushes the Summary screen.
//

import SwiftUI
import SwiftData

struct OverviewDebriefDone: View {
    // Insights flow: card -> info sheet -> InsightsView (pushed)
    @State private var showRadarInfo: Bool = false
    @State private var openInsights: Bool = false
    @State private var showInsights: Bool = false

    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]

    private var data: OverviewData {
        OverviewData(insights: insights, calmDowns: calmDowns)
    }

    // Palette matching design specifications
    private let screenBg = MocoScreenTheme.Colors.canvasTop // #F6FAE8
    private let primaryGreen = MocoScreenTheme.Colors.dataVioletDeep // #1B422F
    private let titleDark = MocoScreenTheme.Colors.textTitle // #5C4330
    private let subtextGray = MocoScreenTheme.Colors.textBody // #6F6762
    private let timerBlue = MocoScreenTheme.Colors.countdownValue // #0A84FF

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

                // Card Header
                Text("No Active Quest")
                    .mocoText(MocoScreenTheme.Typeface.title2)
                    .foregroundColor(primaryGreen)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                // Completion Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(
                        MocoScreenTheme.Colors.dataVioletDeep
                    )
                    .padding(12)
                    .background(
                        MocoScreenTheme.Colors.dataVioletDeep
                            .opacity(0.10),
                        in: Circle()
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                // Main Message
                Text("All quests completed!")
                    .mocoText(MocoScreenTheme.Typeface.section)
                    .foregroundColor(titleDark)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Description
                Text("You've finished today's quests. Discover more interesting challenges in the quest library.")
                    .mocoText(MocoScreenTheme.Typeface.body)
                    .foregroundColor(subtextGray)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.horizontal, MocoScreenTheme.Space.page)

                // Countdown Footer
                HStack(spacing: 7) {
                    Image(systemName: "clock")
                        .font(.system(size: 14, weight: .medium))

                    Text("New quests in")
                        .mocoText(MocoScreenTheme.Typeface.body)

                    Text("12 hrs 48 mins")
                        .mocoText(MocoScreenTheme.Typeface.slider)
                        .foregroundColor(timerBlue)
                }
                .foregroundColor(subtextGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    MocoScreenTheme.Colors.surfaceLavender,
                    in: RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
                .padding(.horizontal, 20)
                .padding(.top, 26)
                .padding(.bottom, 20)
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
    OverviewDebriefDone()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
