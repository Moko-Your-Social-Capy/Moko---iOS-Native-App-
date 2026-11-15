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

                        missionSection
                            .padding(.top, Theme.Space.s7)

                        progressSection
                            .padding(.top, Theme.Space.s7)
                    }
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.bottom, Theme.Space.tabBand)
                }
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
                    // The hero owns a close button, so the grabber would only
                    // collide with the centred title.
                    .presentationDragIndicator(.hidden)
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
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: Theme.Line.hair)

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
                .mokoCard()
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

    /// Today's warmth score next to a small radar chart.
    private var insightsCard: some View {
        progressCard {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeader(title: "Insights")

                    Spacer(minLength: Theme.Space.gapInner)

                    metric(value: "\(Int(data.insights.warmth.rounded()))", unit: "warmth")
                }

                MokoRadarChart(scores: data.insights)
                    .frame(width: Theme.Size.radar, height: Theme.Size.radar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Today's relax minutes next to a bar chart of the last six days.
    private var calmDownCard: some View {
        progressCard {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeader(title: "Calm Down")

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

    /// Shared shell for the two growth cards: one fill, full height, 18/20 insets.
    private func progressCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, Theme.Space.cardHorizontal)
            .padding(.vertical, Theme.Space.cardVertical)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.progressCard, alignment: .leading)
            .mokoCard()
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
