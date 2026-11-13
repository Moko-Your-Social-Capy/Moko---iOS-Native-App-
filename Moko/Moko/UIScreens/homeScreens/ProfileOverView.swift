//
//  ProfileOverView.swift
//  Moko
//
//  "Moco Screen Theme" v1.0 — Profile, direction 01 (Wave hero).
//  Every colour, size, radius, shadow and type style comes from MocoScreenTheme.
//  Cards carry no stroke: they separate from the canvas by the two-layer lift.
//

import SwiftUI
import SwiftData

private typealias Theme = MocoScreenTheme

/// Screen-internal nudges. They describe this one composition rather than a
/// shared design decision, so they stay out of the token registry.
private enum Nudge {
    static let subtitleTop: CGFloat = 3
    static let chipTop: CGFloat = 9
    static let journeyValueTop: CGFloat = 9
    static let journeyValueGap: CGFloat = 7
    static let journeyBarsTop: CGFloat = 11
    static let journeyAxisTop: CGFloat = 6
    static let chipGap: CGFloat = 7
    static let sectionHeadGap: CGFloat = 10
}

/// Profile is presented as a sheet from the Overview avatar, so the hero owns the
/// header row and the navigation bar stays hidden.
struct ProfileOverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var profiles: [Profile]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var quests: [Quest]
    @Query private var insights: [InsightsModel]
    @Query private var onboardingStates: [OnboardingState]

    @State private var countProgress = 0.0
    @State private var journeySelection = JourneyRange.week.rawValue
    @State private var activeSheet: ProfileSheet?

    // MARK: - Model

    private var profile: Profile? { profiles.first }

    private var displayName: String {
        let name = profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Your profile" : name
    }

    private var handle: String? {
        guard let handle = profile?.handle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !handle.isEmpty else { return nil }
        return handle
    }

    private var xp: Int { profile?.xp ?? 0 }
    private var level: Int { xp / 400 + 1 }
    private var levelXP: Int { xp % 400 }
    private var streak: Int { profile?.currentStreak ?? 0 }

    private var localQuests: [Quest] { quests.filter { $0.ownerID == CurrentUser.localID } }
    private var questsDone: Int { localQuests.filter(\.isCompleted).count }

    private var achievements: [Achievement] {
        Achievement.all(
            profile: profile,
            onboardingCompleted: onboardingStates.contains(where: \.isCompleted),
            quests: localQuests,
            calmDowns: calmDowns,
            insights: insights
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(colors: [Theme.Colors.canvasTop, Theme.Colors.canvasBottom],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        hero

                        VStack(spacing: Theme.Space.gapCard) {
                            identityBlock
                            statsRow
                            journeyCard
                            achievementsSection
                            settingsSection
                        }
                        .padding(.horizontal, Theme.Space.profilePage)
                        /// Clearance for the avatar, which overlaps the hero seam.
                        .padding(.top, Theme.Size.avatarLarge / 2 + Theme.Space.s3)
                        .padding(.bottom, Theme.Space.s7)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(ProfilePalette.accent)
            .task { animateNumbersOnce() }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .editProfile:
                    ProfileOverViewEditProfile()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                case .badge(let achievement):
                    NavigationStack {
                        ProfileOverViewAchievementDetailUnlocked(achievement: achievement)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .preferredColorScheme(nil)
    }

    // MARK: - §3 Hero

    private var hero: some View {
        MocoProfileHero(title: "Profile",
                        onClose: { dismiss() },
                        onOverflow: { activeSheet = .editProfile }) {
            MocoProfileAvatar(level: level, photoData: profile?.profileImageData)
        }
    }

    // MARK: - §4 Identity

    private var identityBlock: some View {
        VStack(spacing: 0) {
            Text(displayName)
                .mocoText(Theme.Typeface.profileName)
                .foregroundStyle(Theme.Colors.textTitle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(handle.map { "@\($0)" } ?? "\(animated(levelXP)) XP to level \(level + 1)")
                .mocoText(Theme.Typeface.caption)
                .foregroundStyle(Theme.Colors.textMuted)
                .contentTransition(.numericText())
                .padding(.top, Nudge.subtitleTop)

            MocoLevelChip(level: level)
                .padding(.top, Nudge.chipTop)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: - §5 Stats

    private var statsRow: some View {
        MocoStatsRow(tiles: [
            MocoStat(id: 0,
                     symbol: "flame.fill",
                     value: "\(animated(streak))",
                     label: "Day streak",
                     plate: Theme.Colors.tileSage,
                     tint: Theme.Colors.forest,
                     fill: Theme.Colors.surfaceWhite),
            MocoStat(id: 1,
                     symbol: "checkmark.seal.fill",
                     value: "\(animated(questsDone))",
                     label: "Quests done",
                     plate: Theme.Colors.tileLilac,
                     tint: Theme.Colors.dataVioletDeep,
                     fill: Theme.Colors.surfaceLavender),
            MocoStat(id: 2,
                     symbol: "bolt.fill",
                     value: animated(xp).formatted(),
                     label: "Total XP",
                     plate: Theme.Colors.tileCream,
                     tint: Theme.Colors.forest,
                     fill: Theme.Colors.cream)
        ])
    }

    // MARK: - §6 Journey

    private var journeyRange: JourneyRange { JourneyRange(rawValue: journeySelection) ?? .week }

    private var journeyCard: some View {
        let buckets = journeyBuckets
        let peak = buckets.indices.max { buckets[$0].xp < buckets[$1].xp } ?? 0
        let tallest = max(1, buckets.map(\.xp).max() ?? 1)
        let total = buckets.reduce(0) { $0 + $1.xp }

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Theme.Space.s2) {
                Text("My Journey")
                    .mocoText(Theme.Typeface.title2)
                    .foregroundStyle(Theme.Colors.textTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: Theme.Space.s2)

                MocoSegmented(titles: JourneyRange.allCases.map(\.title),
                              selection: $journeySelection)
            }

            HStack(alignment: .firstTextBaseline, spacing: Nudge.journeyValueGap) {
                Text("\(Int(total).formatted()) XP")
                    .mocoText(Theme.Typeface.journeyValue)
                    .foregroundStyle(Theme.Colors.dataVioletDeep)
                    .contentTransition(.numericText())

                Text(journeyRange.caption)
                    .mocoText(Theme.Typeface.caption)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .lineLimit(1)
            }
            .padding(.top, Nudge.journeyValueTop)

            MocoWeekBars(values: buckets.map { $0.xp / tallest }, peak: peak)
                .padding(.top, Nudge.journeyBarsTop)

            HStack(spacing: MocoWeekBars.spacing) {
                ForEach(buckets) { bucket in
                    Text(axisLabel(for: bucket.start))
                        .mocoText(Theme.Typeface.badge)
                        .foregroundStyle(Theme.Colors.axisLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, Nudge.journeyAxisTop)
            .accessibilityHidden(true)
        }
        .padding(Theme.Space.profileCard)
        .mocoCard(fill: Theme.Colors.cream)
        .animation(reduceMotion ? nil : Theme.Motion.tap, value: journeySelection)
        .accessibilityElement(children: .contain)
    }

    private func axisLabel(for start: Date) -> String {
        switch journeyRange {
        case .day: start.formatted(.dateTime.weekday(.narrow))
        case .week: start.formatted(.dateTime.day())
        case .month: start.formatted(.dateTime.month(.narrow))
        }
    }

    /// Seven complete periods ending with the current one, oldest first.
    private var journeyBuckets: [JourneyBucket] {
        let calendar = Calendar.current
        let component = journeyRange.component
        let current = calendar.dateInterval(of: component, for: .now)?.start
            ?? calendar.startOfDay(for: .now)
        let starts: [Date] = (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: component, value: -offset, to: current)
        }
        let sums = Dictionary(grouping: localQuests.filter(\.isCompleted)) { quest in
            let date = quest.completedAt ?? quest.date
            return calendar.dateInterval(of: component, for: date)?.start
                ?? calendar.startOfDay(for: date)
        }.mapValues { rows in
            rows.reduce(0.0) { $0 + Double($1.awardedXP) }
        }
        return starts.map { JourneyBucket(start: $0, xp: sums[$0] ?? 0) }
    }

    // MARK: - §7 Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Nudge.sectionHeadGap) {
            HStack(spacing: Theme.Space.s2) {
                Text("Achievements")
                    .mocoText(Theme.Typeface.section)
                    .foregroundStyle(Theme.Colors.textTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: Theme.Space.s2)

                NavigationLink {
                    ProfileOverViewAchievementsList()
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    Text("View all")
                        .mocoText(Theme.Typeface.caption)
                        .foregroundStyle(Theme.Colors.dataVioletDeep)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                }
                .accessibilityLabel("View all achievements")
            }

            HStack(spacing: Nudge.chipGap) {
                ForEach(chips) { chip in
                    Button {
                        activeSheet = .badge(chip.achievement)
                    } label: {
                        MocoAchievementChip(symbol: chip.achievement.symbol,
                                            title: chip.achievement.title,
                                            plate: chip.plate,
                                            tint: chip.tint,
                                            locked: !chip.achievement.unlocked)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(chip.achievement.title), \(chip.achievement.unlocked ? "earned" : "locked") badge")
                }
            }
        }
    }

    /// Three most recent badges plus the next one still locked, so the row always
    /// shows something to reach for.
    private var chips: [AchievementChipItem] {
        var picked = Array(achievements.filter(\.unlocked).sorted { $0.id > $1.id }.prefix(3))
        if let locked = achievements.first(where: { !$0.unlocked }) {
            picked.append(locked)
        }
        let plates = [Theme.Colors.tileSage,
                      Theme.Colors.tileLilac,
                      Theme.Colors.tileCream,
                      Theme.Colors.tileSage]
        let tints = [Theme.Colors.forest,
                     Theme.Colors.dataVioletDeep,
                     Theme.Colors.forest,
                     Theme.Colors.forest]
        return picked.enumerated().map { index, achievement in
            AchievementChipItem(achievement: achievement,
                                plate: plates[index % plates.count],
                                tint: tints[index % tints.count])
        }
    }

    // MARK: - §8 Settings

    private var settingsSection: some View {
        VStack(spacing: Theme.Space.s2) {
            settingsRow("Moko’s wardrobe",
                        symbol: "tshirt",
                        destination: AnyView(MokoWardrobeView(level: level)))
            settingsRow("Settings & privacy",
                        symbol: "gearshape",
                        destination: AnyView(ProfileOverViewSettingsOverview()))
            settingsRow("Account & data",
                        symbol: "person.crop.circle",
                        destination: AnyView(ProfileOverViewAccountAndData()))
        }
    }

    private func settingsRow(_ title: String, symbol: String, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            MocoSettingRow(symbol: symbol, title: title)
                .mocoCard(fill: Theme.Card.fill, radius: Theme.Radius.chip)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // MARK: - Numbers

    private func animated(_ value: Int) -> Int {
        Int((Double(value) * countProgress).rounded())
    }

    private func animateNumbersOnce() {
        guard !ProfileSessionAnimation.didAnimateNumbers else {
            countProgress = 1
            return
        }
        ProfileSessionAnimation.didAnimateNumbers = true
        guard !reduceMotion else {
            countProgress = 1
            return
        }
        withAnimation(Theme.Motion.tap) { countProgress = 1 }
    }
}

// MARK: - Data

private enum JourneyRange: Int, CaseIterable, Identifiable {
    case day, week, month

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }

    var caption: String {
        switch self {
        case .day: "last 7 days"
        case .week: "last 7 weeks"
        case .month: "last 7 months"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
    }
}

private struct JourneyBucket: Identifiable {
    let start: Date
    let xp: Double
    var id: Date { start }
}

private struct AchievementChipItem: Identifiable {
    let achievement: Achievement
    let plate: Color
    let tint: Color
    var id: Int { achievement.id }
}

private enum ProfileSheet: Identifiable {
    case editProfile
    case badge(Achievement)

    var id: String {
        switch self {
        case .editProfile: "edit-profile"
        case .badge(let achievement): "badge-\(achievement.id)"
        }
    }
}

@MainActor
private enum ProfileSessionAnimation {
    static var didAnimateNumbers = false
}

// MARK: - Palette

/// The profile cluster's shared palette. Remapped onto the theme so every screen
/// pushed from here — edit, wardrobe, badges, settings, legal — re-skins at once.
enum ProfilePalette {
    static let background = MocoScreenTheme.Colors.canvasTop
    static let grouped = MocoScreenTheme.Colors.cream
    static let text = MocoScreenTheme.Colors.textTitle
    static let secondary = MocoScreenTheme.Colors.textBody
    static let accent = MocoScreenTheme.Colors.sage
    static let lime = MocoScreenTheme.Colors.tileCream
    static let success = MocoScreenTheme.Colors.forest
    static let error = MocoScreenTheme.Colors.error
}

#Preview {
    ProfileOverView()
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingState.self], inMemory: true)
}
