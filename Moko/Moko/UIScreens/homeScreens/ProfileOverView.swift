//
//  ProfileOverView.swift
//  Moko
//
//  "Moko Screen Theme" v1.0 — Profile, direction 01 (Wave hero).
//  Every colour, size, radius, shadow and type style comes from MokoScreenTheme.
//  Cards carry no stroke: they separate from the canvas by the two-layer lift.
//

import SwiftUI
import SwiftData

private typealias Theme = MokoScreenTheme

/// Screen-internal nudges. They describe this one composition rather than a
/// shared design decision, so they stay out of the token registry.
private enum Nudge {
    static let subtitleTop: CGFloat = 3
    static let chipTop: CGFloat = 9
    static let journeyValueTop: CGFloat = 9
    static let journeyValueGap: CGFloat = 7
    static let journeyBarsTop: CGFloat = 11
    static let journeyAxisTop: CGFloat = 6
    static let sectionHeadGap: CGFloat = 10
}

/// Profile is presented as a sheet from the Overview avatar, so the hero owns the
/// header row and the navigation bar stays hidden.
struct ProfileOverView: View {
    // Closes the Profile sheet.
    @Environment(\.dismiss) private var dismiss
    // The phone's "Reduce Motion" setting. When on, numbers appear without counting up.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // @Query reads saved SwiftData rows and redraws this screen when they change.
    @Query private var profiles: [Profile]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var quests: [Quest]
    @Query private var insights: [InsightsModel]
    @Query private var onboardingStates: [OnboardingState]
    @Query private var activityRecords: [ActivityRecord]

    // Goes from 0 to 1 once, so the stat numbers count up from zero.
    @State private var countProgress = 0.0
    // Which tab of the Day / Week / Month control is picked.
    @State private var journeySelection = JourneyRange.week.rawValue
    // The sheet that is open (edit profile or a badge). `nil` means none.
    @State private var activeSheet: ProfileSheet?
    // Accessibility text gets full-width badges so titles never need to shrink.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
    // Every 400 XP is one level. `levelXP` is the progress inside the current level.
    private var level: Int { xp / 400 + 1 }
    private var levelXP: Int { xp % 400 }
    
    // Streak stats computed from ActivityRecord rows via StreakService (single source of truth).
    private var streakStats: StreakStats {
        StreakService.shared.stats(from: activityRecords)
    }
    private var streak: Int { streakStats.currentStreak }
    private var longestStreak: Int { streakStats.longestStreak }
    private var totalActiveDays: Int { streakStats.totalActiveDays }

    // Only quests that belong to the person on this phone.
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
                MokoBackdrop()

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
                        // Clearance for the bigger avatar, which overlaps the hero seam.
                        .padding(.top, Theme.Size.avatarExtraLarge / 2 + Theme.Space.s4)
                        .padding(.bottom, Theme.Space.s8)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(ProfilePalette.accent)
            // `.task` runs when the screen appears: start the count-up animation.
            .task { animateNumbersOnce() }
            // One `.sheet(item:)` for every sheet: the `switch` picks which screen to show.
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
                case .streakDetail:
                    NavigationStack {
                        StreakDetailView()
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .preferredColorScheme(nil)
    }

    /// Bigger avatar for the brighter profile section.
    private var avatar: some View {
        MokoProfileAvatar(level: level, photoData: profile?.profileImageData, size: Theme.Size.avatarExtraLarge)
    }

    // MARK: - §3 Hero

    private var hero: some View {
        MokoProfileHero(title: "Profile",
                        onClose: { dismiss() },
                        onOverflow: { activeSheet = .editProfile },
                        height: Theme.Size.heroLarge,
                        avatarSize: Theme.Size.avatarExtraLarge) {
            avatar
        }
    }

    // MARK: - §4 Identity

    private var identityBlock: some View {
        VStack(spacing: 0) {
            Text(displayName)
                .mokoText(Theme.Typeface.profileName)
                .foregroundStyle(Theme.Colors.textTitle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(handle.map { "@\($0)" } ?? "\(animated(levelXP)) XP to level \(level + 1)")
                .mokoText(Theme.Typeface.caption)
                .foregroundStyle(Theme.Colors.textMuted)
                .contentTransition(.numericText())
                .padding(.top, Nudge.subtitleTop)

            MokoLevelChip(level: level)
                .padding(.top, Nudge.chipTop)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: - §5 Stats

    private var statsRow: some View {
        MokoStatsRow(tiles: [
            MokoStat(id: 0,
                     symbol: "flame.fill",
                     value: "\(animated(streak)) days",
                     label: "Day streak",
                     plate: Theme.Colors.tileSage,
                     tint: Theme.Colors.brightGreen,
                     fill: Theme.Colors.surfaceWhite,
                     action: { showStreakDetail() }),
            MokoStat(id: 1,
                     symbol: "checkmark.seal.fill",
                     value: "\(animated(questsDone))",
                     label: "Quests done",
                     plate: Theme.Colors.tileLilac,
                     tint: Theme.Colors.dataVioletDeep,
                     fill: Theme.Colors.surfaceLavender),
            MokoStat(id: 2,
                     symbol: "bolt.fill",
                     value: animated(xp).formatted(),
                     label: "Total XP",
                     plate: Theme.Colors.tileCream,
                     tint: Theme.Colors.forest,
                     fill: Theme.Colors.cream)
        ])
    }
    
    private func showStreakDetail() {
        // Navigate to streak detail view
        activeSheet = .streakDetail
    }

    // MARK: - §6 Journey

    private var journeyRange: JourneyRange { JourneyRange(rawValue: journeySelection) ?? .week }

    private var journeyCard: some View {
        let buckets = journeyBuckets
        let peak = buckets.indices.max { buckets[$0].xp < buckets[$1].xp } ?? 0
        let tallest = max(1, buckets.map(\.xp).max() ?? 1)
        let total = buckets.reduce(0) { $0 + $1.xp }

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Space.s3) {
                Text("My Journey")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.Colors.textTitle)

                MokoSegmented(titles: JourneyRange.allCases.map(\.title),
                              selection: $journeySelection)
            }

            HStack(alignment: .firstTextBaseline, spacing: Nudge.journeyValueGap) {
                Text("\(Int(total).formatted()) XP")
                    .mokoText(Theme.Typeface.journeyValue)
                    .foregroundStyle(Theme.Colors.dataVioletDeep)
                    .contentTransition(.numericText())

                Text(journeyRange.caption)
                    .mokoText(Theme.Typeface.caption)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .lineLimit(1)
            }
            .padding(.top, Nudge.journeyValueTop)

            MokoWeekBars(values: buckets.map { $0.xp / tallest }, peak: peak)
                .padding(.top, Nudge.journeyBarsTop)

            HStack(spacing: MokoWeekBars.spacing) {
                ForEach(buckets) { bucket in
                    Text(axisLabel(for: bucket.start))
                        .mokoText(Theme.Typeface.badge)
                        .foregroundStyle(Theme.Colors.axisLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, Nudge.journeyAxisTop)
            .accessibilityHidden(true)
        }
        .padding(Theme.Space.profileCard)
        .mokoCard(fill: Theme.Colors.cream)
        .animation(reduceMotion ? nil : Theme.Motion.tap, value: journeySelection)
        .accessibilityElement(children: .contain)
    }

    /// Short date under each bar: weekday letter, day number or month letter.
    private func axisLabel(for start: Date) -> String {
        switch journeyRange {
        case .day: start.formatted(.dateTime.weekday(.narrow))
        case .week: start.formatted(.dateTime.day())
        case .month: start.formatted(.dateTime.month(.narrow))
        }
    }

    /// Seven complete periods ending with the current one, oldest first.
    /// Each bucket adds up the XP from quests finished in that day, week or month.
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

    private var badgeColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 140), spacing: Theme.Space.s3)]
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Nudge.sectionHeadGap) {
            HStack(spacing: Theme.Space.s2) {
                Text("Achievements")
                    .mokoText(Theme.Typeface.section)
                    .foregroundStyle(Theme.Colors.textTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: Theme.Space.s2)

                NavigationLink {
                    ProfileOverViewAchievementsList()
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    Text("View all")
                        .mokoText(Theme.Typeface.caption)
                        .foregroundStyle(Theme.Colors.dataVioletDeep)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                }
                .accessibilityLabel("View all achievements")
            }

            // Let larger cards wrap instead of squeezing four badge names into one row.
            LazyVGrid(columns: badgeColumns, spacing: Theme.Space.s3) {
                ForEach(chips) { chip in
                    Button {
                        activeSheet = .badge(chip.achievement)
                    } label: {
                        MokoAchievementChip(symbol: chip.achievement.symbol,
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
        VStack(spacing: Theme.Space.s3) {
            settingsRow("Settings & preferences", symbol: "gearshape") {
                ProfileSettingsView()
            }
            settingsRow("Moko’s wardrobe", symbol: "tshirt") {
                MokoWardrobeView(level: level)
            }
            settingsRow("Account & data", symbol: "person.crop.circle") {
                ProfileOverViewAccountAndData()
            }
        }
    }

    /// One settings row that opens `destination` when tapped.
    /// `Destination` is a generic, so each row can open a different screen without `AnyView`.
    private func settingsRow<Destination: View>(
        _ title: String,
        symbol: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
                // Profile hides its own bar, but its detail screens need a Back button.
                .toolbar(.visible, for: .navigationBar)
        } label: {
            MokoSettingRow(symbol: symbol, title: title)
                .mokoCard(fill: Theme.Card.fill, radius: Theme.Radius.chip)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // MARK: - Numbers

    /// The number to show right now while counting up (e.g. 50% of 120 = 60).
    private func animated(_ value: Int) -> Int {
        Int((Double(value) * countProgress).rounded())
    }

    /// Counts the numbers up only the first time Profile opens in this app session.
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

/// The Day / Week / Month choice for the "My Journey" chart.
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

/// One bar in the chart: when the period starts and how much XP was earned.
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

/// The sheets Profile can open. `Identifiable` is needed for `.sheet(item:)`.
private enum ProfileSheet: Identifiable {
    case editProfile
    case badge(Achievement)
    case streakDetail

    var id: String {
        switch self {
        case .editProfile: "edit-profile"
        case .badge(let achievement): "badge-\(achievement.id)"
        case .streakDetail: "streak-detail"
        }
    }
}

/// Remembers (until the app is closed) that the numbers already counted up once.
@MainActor
private enum ProfileSessionAnimation {
    static var didAnimateNumbers = false
}

// MARK: - Palette

/// The profile cluster's shared palette. Remapped onto the theme so every screen
/// pushed from here — edit, wardrobe, badges, settings, legal — re-skins at once.
enum ProfilePalette {
    static let background = MokoScreenTheme.Colors.canvasTop
    static let grouped = MokoScreenTheme.Colors.cream
    static let text = MokoScreenTheme.Colors.textTitle
    static let secondary = MokoScreenTheme.Colors.textBody
    static let accent = MokoScreenTheme.Colors.sage
    static let lime = MokoScreenTheme.Colors.tileCream
    static let success = MokoScreenTheme.Colors.forest
    static let error = MokoScreenTheme.Colors.error
}

#Preview {
    ProfileOverView()
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingState.self], inMemory: true)
}

#Preview("Profile — Larger Text") {
    ProfileOverView()
        .environment(\.dynamicTypeSize, .accessibility3)
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingState.self], inMemory: true)
}
