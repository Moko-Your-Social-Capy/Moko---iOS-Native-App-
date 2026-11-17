//
//  OverviewScaffold.swift
//  Moko
//
//  The frame shared by all three Overview versions (to-do, resume, debrief done):
//  background, "Overview" header with the profile button, a Mission card that
//  each version passes in, and the two Growth cards (Insights and Calm Down).
//
//  Usage:
//      OverviewScaffold {
//          Text("My mission card content")
//      }
//
//  Navigation:
//  - Profile button      → ProfileOverView sheet
//  - Insights card       → RadarInfoSheet → (Continue) → InsightsView pushed
//  - Calm Down card      → SummaryView pushed
//

import SwiftUI
import SwiftData

// Short name so the code below reads `Theme.Colors...` instead of `MokoScreenTheme.Colors...`.
private typealias Theme = MokoScreenTheme

struct OverviewScaffold<MissionCard: View>: View {
    /// The content of the Mission card. The scaffold adds the card's padding and background.
    private let missionCard: MissionCard

    init(@ViewBuilder missionCard: () -> MissionCard) {
        self.missionCard = missionCard()
    }

    // `@Query` reads saved data and redraws this screen when it changes.
    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]

    @State private var showRadarInfo: Bool = false      // "How your radar chart works" sheet
    @State private var openInsights: Bool = false       // set by the sheet's Continue button
    @State private var showInsights: Bool = false       // pushes InsightsView
    @State private var showProfile: Bool = false        // profile sheet
    // Shows placeholder cards while the mission / growth data are loading.
    @State private var isLoading = true

    // Reads the session-end closure set by ContentView so we can dismiss the
    // profile sheet before the root screen transitions away.
    @Environment(\.endSession) private var endSession

    /// Today's numbers for the two Growth cards.
    private var data: OverviewData {
        OverviewData(insights: insights, calmDowns: calmDowns)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Shared lavender background used by every tab.
                MokoBackdrop()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection

                        if isLoading {
                            missionSkeleton
                                .padding(.top, Theme.Space.s7)

                            progressSkeleton
                                .padding(.top, Theme.Space.s7)
                        } else {
                            missionSection
                                .padding(.top, Theme.Space.s7)

                            progressSection
                                .padding(.top, Theme.Space.s7)
                        }
                    }
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.bottom, Theme.Space.tabBand)
                }
            }
            .task {
                isLoading = false
            }
            // Overview keeps its own header; pushed screens get the default bar and back button.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showInsights) {
                InsightsView()
            }
            .sheet(isPresented: $showRadarInfo, onDismiss: {
                // Push Insights only after the sheet has fully closed,
                // otherwise the push and the sheet animation clash.
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
                    .presentationDragIndicator(.hidden)
                    // Intercept endSession: dismiss this sheet first, then let
                    // ContentView switch the root screen once the sheet is gone.
                    .environment(\.endSession) { reason in
                        showProfile = false
                        // Give the sheet dismiss animation a beat before the root
                        // screen transitions, so there is no visual overlap.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            endSession?(reason)
                        }
                    }
            }
        }
    }

    // MARK: - Skeletons

    /// Placeholder Mission card while the real mission is being prepared.
    private var missionSkeleton: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapSection) {
            Text("Mission")
                .mokoText(Theme.Typeface.section)
                .foregroundStyle(Theme.Colors.textTitle)

            VStack(alignment: .leading, spacing: Theme.Space.gapCard) {
                MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 2)
                    .padding(.horizontal, Theme.Space.cardHorizontal)
                    .padding(.vertical, Theme.Space.cardVertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mokoCard(fill: MokoScreenTheme.Card.missionFill)
            }
        }
    }

    /// Placeholder Growth cards while insights / calm-down data are loading.
    private var progressSkeleton: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapSection) {
            Text("Growth")
                .mokoText(Theme.Typeface.section)
                .foregroundStyle(Theme.Colors.textTitle)

            VStack(alignment: .leading, spacing: Theme.Space.gapCard) {
                MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 2)
                    .padding(.horizontal, Theme.Space.cardHorizontal)
                    .padding(.vertical, Theme.Space.cardVertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mokoCard()
            }

            VStack(alignment: .leading, spacing: Theme.Space.gapCard) {
                MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 2)
                    .padding(.horizontal, Theme.Space.cardHorizontal)
                    .padding(.vertical, Theme.Space.cardVertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mokoCard()
            }
        }
    }

    // MARK: - Header

    /// "Overview" title and the round profile button.
    private var headerSection: some View {
        HStack(alignment: .center, spacing: Theme.Space.s4) {
            Text("Overview")
                .mokoText(Theme.Typeface.title1)
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
                    .strokeBorder(Theme.Colors.avatarRing, lineWidth: Theme.Line.hair)

                avatarGlyph
            }
            .frame(width: Theme.Size.avatar, height: Theme.Size.avatar)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile")
    }

    /// The user's first two letters, or a person icon if there is no name yet.
    @ViewBuilder
    private var avatarGlyph: some View {
        if let name = profiles.first?.username, !name.isEmpty {
            Text(String(name.prefix(2)).uppercased())
                .mokoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.avatarText)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: Theme.Glyph.avatar, weight: .semibold))
                .foregroundStyle(Theme.Colors.avatarText)
        }
    }

    // MARK: - Mission

    private var missionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapSection) {
            Text("Mission")
                .mokoText(Theme.Typeface.section)
                .foregroundStyle(Theme.Colors.textTitle)

            missionCard
                .padding(.horizontal, Theme.Space.cardHorizontal)
                .padding(.vertical, Theme.Space.cardVertical)
                .frame(maxWidth: .infinity, alignment: .leading)
                .mokoCard(fill: MokoScreenTheme.Card.missionFill)
        }
    }

    // MARK: - Growth

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapSection) {
            Text("Growth")
                .mokoText(Theme.Typeface.section)
                .foregroundStyle(Theme.Colors.textTitle)

            // Insights card (opens the radar chart info sheet).
            // A Button (not onTapGesture) so VoiceOver reads it as tappable.
            Button {
                showRadarInfo = true
            } label: {
                insightsCard
            }
            .buttonStyle(.plain)

            // Calm Down card (pushes the Summary screen).
            NavigationLink {
                SummaryView()
            } label: {
                calmDownCard
            }
            .buttonStyle(.plain)
        }
    }

    /// Today's overall score (the average of all four parameters) next to a small radar chart.
    private var insightsCard: some View {
        progressCard {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeader(title: "Insights")

                    Spacer(minLength: Theme.Space.gapInner)

                    insightsDelta

                    Spacer(minLength: Theme.Space.gapInner)

                    metric(value: "\(Int(data.insights.overall.rounded()))", unit: "overall")
                }

                MokoRadarChart(scores: data.insights)
                    .frame(width: Theme.Size.radar, height: Theme.Size.radar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Change indicator between the last two debrief records.
    /// Green + arrow-up if improved, brown + arrow-down if declined, gray prompt if < 2 records.
    private var insightsDelta: some View {
        let sorted = insights.sorted { $0.date < $1.date }

        if sorted.count < 2 {
            // Not enough data yet
            return AnyView(
                Text("Try out one quest.")
                    .mokoText(Theme.Typeface.body)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        let prev    = InsightsScores(records: [sorted[sorted.count - 2]])
        let current = InsightsScores(records: [sorted[sorted.count - 1]])

        guard prev.overall > 0 else {
            return AnyView(
                Text("Try out one quest.")
                    .mokoText(Theme.Typeface.body)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        let pct    = ((current.overall - prev.overall) / prev.overall) * 100
        let isUp   = pct >= 0
        let symbol = isUp ? "arrow.up.right" : "arrow.down.right"
        let color: Color = isUp ? Theme.Colors.scoreExcellent : Theme.Colors.error

        return AnyView(
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                Text("\(abs(Int(pct.rounded())))%")
                    .font(.system(size: 30, weight: .bold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
        )
    }

    /// Today's relax minutes next to a bar chart of the last six days.
    private var calmDownCard: some View {
        progressCard {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeader(title: "Calm Down")

                    Spacer(minLength: Theme.Space.gapInner)

                    calmDownLastExercise

                    Spacer(minLength: Theme.Space.gapInner)

                    metric(value: "\(data.calmDownMinutes)", unit: "min")
                }

                MokoBarChart(values: data.calmDownBars)
                    .frame(width: Theme.Size.barChart.width, height: Theme.Size.barChart.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Most recent exercise name, or a nudge if nothing has been done yet.
    private var calmDownLastExercise: some View {
        let title = calmDowns.max(by: { $0.date < $1.date })?.exerciseTitle

        return Text(title ?? "Try Relax")
            .mokoText(Theme.Typeface.body)
            .foregroundStyle(title != nil ? Theme.Colors.dataTeal : Theme.Colors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
    }

    /// Shared shell for the two growth cards: elevated surface, full height, 18/20 insets.
    private func progressCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, Theme.Space.cardHorizontal)
            .padding(.vertical, Theme.Space.cardVertical)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.progressCard, alignment: .leading)
            .mokoCard(fill: MokoScreenTheme.Card.progressFill)
    }

    /// Card title on the left, today's date and a chevron on the right.
    private func cardHeader(title: String) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.s2) {
            Text(title)
                .mokoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.textTitle)

            Spacer(minLength: 0)

            HStack(spacing: Theme.Space.s1) {
                Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                    .mokoText(Theme.Typeface.caption)
                    .foregroundStyle(Theme.Colors.textMuted)

                Image(systemName: "chevron.right")
                    .font(.system(size: Theme.Glyph.disclosure, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .accessibilityHidden(true)
            }
        }
    }

    /// A big number with a small unit after it, e.g. "12 min".
    private func metric(value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s1) {
            Text(value)
                .mokoText(Theme.Typeface.numeral)
                .foregroundStyle(Theme.Colors.dataNumeral)

            Text(unit)
                .mokoText(Theme.Typeface.unit)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }
}

#Preview {
    OverviewScaffold {
        Text("Mission card content goes here")
    }
    .modelContainer(
        for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
        inMemory: true
    )
}
