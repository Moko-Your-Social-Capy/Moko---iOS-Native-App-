//
//  AchievementsList.swift
//  Moko
//
//  Profile → Achievements: the 60 badges.
//  - `Achievement.all(...)` decides which badges are earned from the saved data.
//  - `AchievementBadgeShape` / `AchievementBadgeView` draw one badge.
//  - `ProfileOverViewAchievementsList` is the grid screen.
//

import SwiftUI
import SwiftData

// A short nickname so we can write `Theme.Colors` instead of `MokoScreenTheme.Colors`.
private typealias Theme = MokoScreenTheme

/// The outline of a badge: each family of badges has its own shape.
enum AchievementBadgeShapeKind: Hashable { case streak, quest, skill, calm }
/// Badge level. Tier 3 is the hardest and gets a gold rim.
enum AchievementTier: Int, Hashable {
    case one = 1, two, three
    var title: String { "Tier \(rawValue)" }
}

/// One badge: its text, icon, shape, tier and whether the user has earned it.
struct Achievement: Identifiable, Hashable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
    /// Small visual sub-element: a leaf, mock icon or subcomponent related to
    /// this achievement. Shown below the main badge symbol.
    let leafSymbol: String
    let shape: AchievementBadgeShapeKind
    let tier: AchievementTier
    let unlocked: Bool

    /// Builds all 60 badges and works out which ones are earned.
    /// It only reads data that is already saved, so it is safe to call from `body`.
    static func all(profile: Profile?, onboardingCompleted: Bool, quests: [Quest], calmDowns: [CalmDownModel], insights: [InsightsModel], now: Date = .now, calendar: Calendar = .current) -> [Achievement] {
        // Finished quests, oldest first.
        let completed = quests.filter(\.isCompleted).sorted { ($0.completedAt ?? $0.date) < ($1.completedAt ?? $1.date) }
        func activityDate(_ quest: Quest) -> Date { quest.completedAt ?? quest.date }
        let friendsFamily = completed.filter { $0.category == .friends || $0.category == .family }
        let friends = completed.filter { $0.category == .friends }
        let family = completed.filter { $0.category == .family }
        let work = completed.filter { $0.category == .work }
        let dating = completed.filter { $0.category == .dating }
        // The best score ever reached in each skill.
        let courage = insights.map(\.courage).max() ?? 0
        let clarity = insights.map(\.clarity).max() ?? 0
        let presence = insights.map(\.presence).max() ?? 0
        let warmth = insights.map(\.warmth).max() ?? 0
        let calmMinutes = calmDowns.reduce(0.0) { $0 + $1.exerciseTime } / 60
        let restUsed = hasRestDay(completed, calendar: calendar)
        let returned = hasReturnAfterBreak(completed, calendar: calendar)
        // True if any one calendar week has 5 or more finished quests.
        let fiveInWeek = Dictionary(grouping: completed) {
            calendar.dateInterval(of: .weekOfYear, for: activityDate($0))?.start ?? calendar.startOfDay(for: activityDate($0))
        }.values.contains { $0.count >= 5 }

        // Small helper rules used by the badge list below.
        func contains(_ rows: [Quest], any words: [String]) -> Bool {
            rows.contains { row in
                let text = "\(row.title) \(row.notes)".lowercased()
                return words.contains { word in text.contains(word) }
            }
        }
        func reached(_ score: Int, _ tier: AchievementTier) -> Bool {
            score >= (tier == .one ? 60 : tier == .two ? 75 : 90)
        }
        func hasWeeklySteadiness() -> Bool {
            let recent = insights.filter {
                guard let age = calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.date), to: calendar.startOfDay(for: now)).day else { return false }
                return (0..<7).contains(age)
            }
            guard Set(recent.map { calendar.startOfDay(for: $0.date) }).count == 7 else { return false }
            let dimensions = [recent.map(\.courage), recent.map(\.clarity), recent.map(\.presence), recent.map(\.warmth)]
            return dimensions.allSatisfy { scores in
                guard let low = scores.min(), let high = scores.max() else { return false }
                return high - low <= 1
            }
        }
        // Skill scores in date order: one list each for courage, clarity, presence, warmth.
        let chronological = insights.sorted { $0.date < $1.date }
        let skillSeries = [chronological.map(\.courage), chronological.map(\.clarity),
                           chronological.map(\.presence), chronological.map(\.warmth)]
        // True if a score ever beat its earlier best.
        func madePersonalBest() -> Bool {
            skillSeries.contains { values in
                var best = Int.min
                for value in values {
                    if best != Int.min && value > best { return true }
                    best = max(best, value)
                }
                return false
            }
        }
        // True if a score went down and then up again.
        func cameBackUp() -> Bool {
            skillSeries.contains { values in
                guard values.count >= 3 else { return false }
                return (2..<values.count).contains { i in values[i - 1] < values[i - 2] && values[i] > values[i - 1] }
            }
        }

        let completedCount = completed.count
        let longest = profile?.longestStreak ?? 0
        let calmTitles = calmDowns.map(\.exerciseTitle)
        // Badge number → earned? The numbers match the order of `catalog` below (1 = first row).
        // PDAM: rules are deliberately much harder so a few logins and a handful of
        // quests never unlock 5–10 badges. Each badge needs real repetition.
        let unlock: [Int: Bool] = [
            1: onboardingCompleted,
            2: completedCount >= 1,
            // Streak badges: PDAM — 3/7/14/30/50/100 days become much bigger numbers.
            3: longest >= 30, 4: longest >= 90, 5: longest >= 180, 6: longest >= 365,
            7: longest >= 730, 8: longest >= 1000,
            9: returned, 10: restUsed,
            // Quest-count badges: PDAM — 5/10/25/50/100 become much bigger numbers.
            11: completedCount >= 50, 12: completedCount >= 100, 13: completedCount >= 250,
            14: completedCount >= 500, 15: completedCount >= 1000,
            16: quests.contains { $0.xp == nil }, 17: completed.contains { $0.xp == nil },
            18: completed.contains { $0.isFromLibrary }, 19: completed.contains { $0.intensity == .hard },
            20: fiveInWeek,
            21: !friendsFamily.isEmpty,
            22: contains(friends, any: ["honest", "share", "tell", "open up"]),
            23: contains(friendsFamily, any: ["group"]),
            24: contains(friendsFamily, any: ["group"]) && contains(friendsFamily, any: ["speak", "spoke", "contribute", "first"]),
            25: contains(dating, any: ["ask", "out", "date"]),
            26: contains(family, any: ["boundary", "decline", "say no", "said no"]),
            27: !family.isEmpty, 28: contains(family, any: ["talk", "conversation", "difficult"]),
            29: contains(work, any: ["introduce", "introduction", "hello"]),
            30: contains(work, any: ["meeting"]) && contains(work, any: ["speak", "spoke", "contribute"]),
            31: reached(courage, .one), 32: reached(courage, .two), 33: reached(courage, .three),
            34: reached(clarity, .one), 35: reached(clarity, .two), 36: reached(clarity, .three),
            37: reached(presence, .one), 38: reached(presence, .two), 39: reached(presence, .three),
            40: reached(warmth, .one), 41: reached(warmth, .two), 42: reached(warmth, .three),
            // Voice reflections and insight visits are not recorded in the current data model.
            43: false, 44: false, 45: false, 46: false, 47: false, 48: false,
            49: calmDowns.count >= 1,
            50: calmTitles.contains { $0.localizedCaseInsensitiveContains("box") },
            51: calmTitles.contains { $0.localizedCaseInsensitiveContains("imagery") },
            52: calmTitles.contains { $0.localizedCaseInsensitiveContains("grounding") },
            53: calmTitles.contains { $0.localizedCaseInsensitiveContains("mirror") },
            54: calmDowns.contains { calm in completed.contains { activityDate($0) >= calm.date && activityDate($0).timeIntervalSince(calm.date) <= 30 * 60 } },
            55: calmDowns.count >= 25, 56: calmMinutes >= 300,
            57: false, 58: madePersonalBest(), 59: hasWeeklySteadiness(), 60: cameBackUp()
        ]

        // (title, description, SF Symbol, leaf sub-symbol, shape, tier) for every badge, in order.
        // The leaf symbol is a small mock/leaf/subcomponent related to the badge's theme.
        let catalog: [(String, String, String, String, AchievementBadgeShapeKind, AchievementTier)] = [
            ("First Step", "Finish onboarding.", "shoeprints.fill", "leaf", .quest, .one),
            ("Day One", "Complete your first quest.", "sunrise.fill", "leaf.fill", .quest, .one),
            ("Thirty Days", "Practise on thirty consecutive days.", "calendar", "leaf.fill", .streak, .two),
            ("Ninety Days", "Practise on ninety consecutive days.", "link", "leaf.fill", .streak, .two),
            ("Half Year", "Practise on one hundred eighty days.", "book.closed", "leaf.fill", .streak, .three),
            ("Full Year", "Practise on three hundred sixty-five days.", "laurel.leading", "leaf.fill", .streak, .three),
            ("Two Years", "Practise on seven hundred thirty days.", "figure.walk", "leaf.fill", .streak, .three),
            ("Thousand Days", "Practise on one thousand days.", "star.fill", "leaf.fill", .streak, .three),
            ("Back Again", "Return after three or more full days away.", "arrow.uturn.backward.circle", "arrow.uturn.backward", .streak, .one),
            ("Rest Is Part of It", "Take one rest day after every seven practice days without breaking your streak.", "moon", "moon.fill", .streak, .one),
            ("Fifty Quests", "Complete fifty quests.", "leaf", "leaf.fill", .quest, .two),
            ("Hundred Quests", "Complete one hundred quests.", "leaf.fill", "tree.fill", .quest, .two),
            ("Two Hundred Fifty Quests", "Complete two hundred fifty quests.", "tree", "tree.fill", .quest, .three),
            ("Five Hundred Quests", "Complete five hundred quests.", "tree.fill", "tree.fill", .quest, .three),
            ("Thousand Quests", "Complete one thousand quests.", "forest", "tree.fill", .quest, .three),
            ("Your Own Quest", "Create your first custom quest.", "flag", "flag.fill", .quest, .one),
            ("Event Day", "Finish a custom quest.", "flag.fill", "flag", .quest, .one),
            ("From the Library", "Complete a scenario from Explore.", "safari", "leaf.fill", .quest, .one),
            ("The Harder One", "Complete a top-difficulty quest.", "stairs", "stairs.fill", .quest, .one),
            ("Quest Week", "Complete fifty quests in one calendar week.", "circle.grid.2x2.fill", "leaf.fill", .quest, .two),
            ("Opened Up", "Finish a quest with friends or family.", "circle.circle", "person.2.fill", .quest, .one),
            ("Told a Friend", "Share something honest in a friend quest.", "bubble.left", "bubble.left.fill", .quest, .one),
            ("Joined a Group", "Take part in a group quest.", "person.3", "person.3.fill", .quest, .one),
            ("Spoke in a Group", "Speak or contribute first in a group quest.", "hand.raised", "hand.raised.fill", .quest, .one),
            ("Made the Ask", "Complete a dating quest about asking someone out.", "envelope", "envelope.fill", .quest, .one),
            ("Said No Kindly", "Set a kind boundary in a family quest.", "hand.raised.fill", "hand.raised", .quest, .one),
            ("Family Table", "Speak up in a family quest.", "cup.and.saucer", "cup.and.saucer.fill", .quest, .one),
            ("Hard Talk at Home", "Finish a difficult family conversation quest.", "chair.lounge", "chair.lounge.fill", .quest, .one),
            ("Work Hello", "Introduce yourself in a work quest.", "handshake", "handshake.fill", .quest, .one),
            ("Spoke in a Meeting", "Contribute in a work meeting quest.", "mic", "mic.fill", .quest, .one),
            ("Courage I", "Reach a Courage score of 60.", "flame", "flame.fill", .skill, .one),
            ("Courage II", "Reach a Courage score of 75.", "flame", "flame.fill", .skill, .two),
            ("Courage III", "Reach a Courage score of 90.", "flame", "flame.fill", .skill, .three),
            ("Clarity I", "Reach a Clarity score of 60.", "drop", "drop.fill", .skill, .one),
            ("Clarity II", "Reach a Clarity score of 75.", "drop", "drop.fill", .skill, .two),
            ("Clarity III", "Reach a Clarity score of 90.", "drop", "drop.fill", .skill, .three),
            ("Presence I", "Reach a Presence score of 60.", "eye", "eye.fill", .skill, .one),
            ("Presence II", "Reach a Presence score of 75.", "eye", "eye.fill", .skill, .two),
            ("Presence III", "Reach a Presence score of 90.", "eye", "eye.fill", .skill, .three),
            ("Warmth I", "Reach a Warmth score of 60.", "sun.max", "sun.max.fill", .skill, .one),
            ("Warmth II", "Reach a Warmth score of 75.", "sun.max", "sun.max.fill", .skill, .two),
            ("Warmth III", "Reach a Warmth score of 90.", "sun.max", "sun.max.fill", .skill, .three),
            ("First Reflection", "Record your first voice reflection. Reflection tracking is not connected yet.", "waveform", "waveform.circle", .skill, .one),
            ("Five Reflections", "Record five voice reflections. Reflection tracking is not connected yet.", "waveform", "waveform.circle", .skill, .one),
            ("Twenty-Five Reflections", "Record twenty-five voice reflections. Reflection tracking is not connected yet.", "waveform", "waveform.circle", .skill, .two),
            ("Spoke Freely", "Record a voice reflection longer than two minutes. Reflection tracking is not connected yet.", "waveform", "mic.fill", .skill, .one),
            ("Reflected Seven Days", "Record reflections on seven consecutive days. Reflection tracking is not connected yet.", "chart.bar", "chart.bar.fill", .skill, .two),
            ("Looked Back", "Open Insights after completing a quest. Insight-view tracking is not connected yet.", "arrow.uturn.backward", "arrow.uturn.backward.circle", .skill, .one),
            ("First Calm", "Finish your first calm session.", "water.waves", "drop.fill", .calm, .one),
            ("Box Breath", "Finish a box-breathing session.", "square", "square.fill", .calm, .one),
            ("Picture It", "Finish an imagery session.", "mountain.2", "mountain.2.fill", .calm, .one),
            ("Grounded", "Finish a 5-4-3-2-1 session.", "circle.grid.3x3", "circle.grid.3x3.fill", .calm, .one),
            ("Mirror Moment", "Finish a mirror session.", "mirror", "mirror.fill", .calm, .one),
            ("Calm Before", "Finish a calm session within thirty minutes before a quest.", "water.waves", "drop.fill", .calm, .two),
            ("Ten Calm Sessions", "Finish ten calm sessions.", "water.waves", "drop.fill", .calm, .two),
            ("Hundred Calm Minutes", "Spend one hundred minutes in calm sessions.", "hourglass", "hourglass.bottomhalf.fill", .calm, .three),
            ("First Insight", "View the first written insight. Written insight tracking is not connected yet.", "lightbulb", "lightbulb.fill", .skill, .one),
            ("Personal Best", "Beat a previous score in any skill.", "arrow.up.right", "arrow.up.right.circle.fill", .skill, .one),
            ("Steady Week", "Keep all four skill scores within one point for seven days.", "equal", "equal.fill", .skill, .two),
            ("Comeback", "Raise a skill score after it dipped.", "chart.line.uptrend.xyaxis", "chart.line.uptrend.xyaxis.circle", .skill, .one)
        ]
        return catalog.enumerated().map { offset, row in
            Achievement(id: offset + 1, title: row.0, detail: row.1, symbol: row.2, leafSymbol: row.3, shape: row.4, tier: row.5, unlocked: unlock[offset + 1] ?? false)
        }
    }

    /// Whole days between two dates (ignores the time of day).
    private static func dayGap(_ previous: Date, _ next: Date, _ calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: previous), to: calendar.startOfDay(for: next)).day ?? 0
    }
    /// True if the user came back after 3+ full days away.
    private static func hasReturnAfterBreak(_ quests: [Quest], calendar: Calendar) -> Bool {
        guard quests.count > 1 else { return false }
        for index in 1..<quests.count where dayGap(quests[index - 1].completedAt ?? quests[index - 1].date, quests[index].completedAt ?? quests[index].date, calendar) >= 4 { return true }
        return false
    }
    /// True if the user skipped exactly one day right after a run of 7, 14, 21... days.
    private static func hasRestDay(_ quests: [Quest], calendar: Calendar) -> Bool {
        guard quests.count > 1 else { return false }
        var activeDays = 1
        for index in 1..<quests.count {
            let gap = dayGap(quests[index - 1].completedAt ?? quests[index - 1].date, quests[index].completedAt ?? quests[index].date, calendar)
            if gap == 1 { activeDays += 1 }
            else if gap == 2 && activeDays >= 7 && activeDays.isMultiple(of: 7) { return true }
            else { activeDays = 1 }
        }
        return false
    }
}

// MARK: - Flat vector badge artwork
/// Medal artwork. Every value resolves through the theme so the badges belong to
/// the same palette as the screen that shows them.
private enum BadgePalette {
    static let teal = Theme.Colors.forest
    static let lightTeal = Theme.Colors.sage
    static let white = Theme.Colors.surfaceWhite
    static let cream = Theme.Colors.cream
    static let brown = Theme.Colors.textTitle
    static let gold = Theme.Colors.medalGold
    static let silver = Theme.Colors.medalSilver
    static let locked = Theme.Colors.lockedInk
    static let lockedFace = Theme.Colors.ringTrack
}

/// Draws the outline for each badge family with `Path` (a list of points and curves).
struct AchievementBadgeShape: Shape {
    var kind: AchievementBadgeShapeKind
    func path(in rect: CGRect) -> Path {
        switch kind {
        case .quest: return Circle().path(in: rect)
        case .calm: return RoundedRectangle(cornerRadius: rect.width * 0.22, style: .continuous).path(in: rect)
        case .skill:
            var path = Path()
            path.addLines([
                CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.24),
                CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.76), CGPoint(x: rect.midX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.76), CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.24)
            ])
            path.closeSubpath()
            return path
        case .streak:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.16), control: CGPoint(x: rect.maxX * 0.88, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.56))
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.maxY - rect.height * 0.1))
            path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.56), control: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.1))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.16))
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY))
            path.closeSubpath()
            return path
        }
    }
}

/// One badge picture. Earned badges are filled; locked ones are just an outline.
struct AchievementBadgeView: View {
    let achievement: Achievement
    var size: CGFloat = 74
    // The outer ring colour: teal, silver or gold by tier, grey when locked.
    private var rim: Color {
        guard achievement.unlocked else { return BadgePalette.locked }
        switch achievement.tier { case .one: return BadgePalette.lightTeal; case .two: return BadgePalette.silver; case .three: return BadgePalette.gold }
    }
    var body: some View {
        let artSize = size * 0.76 // leaves 12% clear space on every side
        ZStack {
            if achievement.unlocked {
                AchievementBadgeShape(kind: achievement.shape).fill(rim)
                AchievementBadgeShape(kind: achievement.shape).fill(BadgePalette.teal).padding(artSize * 0.075)
                AchievementBadgeShape(kind: achievement.shape).stroke(BadgePalette.brown.opacity(0.38), lineWidth: 1).padding(artSize * 0.12)
            } else {
                AchievementBadgeShape(kind: achievement.shape)
                    .stroke(BadgePalette.locked, style: StrokeStyle(lineWidth: max(1.4, size * 0.035), lineJoin: .round))
                    .padding(artSize * 0.10)
            }
            Image(systemName: achievement.symbol)
                .font(.system(size: artSize * 0.31, weight: .regular))
                .foregroundStyle(achievement.unlocked ? BadgePalette.white : BadgePalette.locked)
                .frame(width: artSize * 0.45, height: artSize * 0.45)

            // The leaf symbol is a small subcomponent that makes the badge unique.
            // It sits at the bottom right of the main symbol.
            Image(systemName: achievement.leafSymbol)
                .font(.system(size: artSize * 0.14, weight: .bold))
                .foregroundStyle(achievement.unlocked ? BadgePalette.white.opacity(0.8) : BadgePalette.locked.opacity(0.5))
                .offset(x: artSize * 0.12, y: artSize * 0.12)
        }
        .frame(width: artSize, height: artSize)
        .frame(width: size, height: size)
        // VoiceOver reads the whole badge as one sentence instead of its parts.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title), \(achievement.unlocked ? "earned" : "locked"), \(achievement.tier.title)")
    }
}

/// The grid of all badges. Tapping one opens its detail sheet.
struct ProfileOverViewAchievementsList: View {
    // The badge the user tapped. Setting it opens the sheet; `nil` closes it.
    @State private var selectedAchievement: Achievement?
    // @Query loads saved SwiftData rows and refreshes the screen when they change.
    @Query private var profiles: [Profile]
    @Query private var quests: [Quest]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var insights: [InsightsModel]
    @Query private var onboardingStates: [OnboardingState]

    // Only quests that belong to the person on this phone.
    private var localQuests: [Quest] { quests.filter { $0.ownerID == CurrentUser.localID } }
    private var achievements: [Achievement] {
        Achievement.all(profile: profiles.first, onboardingCompleted: onboardingStates.contains(where: \.isCompleted), quests: localQuests, calmDowns: calmDowns, insights: insights)
    }
    private var unlockedCount: Int { achievements.filter(\.unlocked).count }
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(unlockedCount) of \(achievements.count) earned")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(BadgePalette.brown)
                    Spacer()
                    Text("\(achievements.count) badges").font(.caption).foregroundStyle(BadgePalette.brown.opacity(0.7))
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(achievements) { item in
                        Button { selectedAchievement = item } label: { card(item) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 24)
        }
        .background(ProfilePalette.background.ignoresSafeArea())
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        // `.sheet(item:)` opens when `selectedAchievement` gets a value, and passes it in.
        .sheet(item: $selectedAchievement) { achievement in
            NavigationStack {
                ProfileOverViewAchievementDetailUnlocked(achievement: achievement)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    /// One tile in the grid: badge, title and "Earned · Tier 1".
    private func card(_ item: Achievement) -> some View {
        VStack(spacing: 9) {
            AchievementBadgeView(achievement: item, size: 74)
            Text(item.title)
                .mokoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.textTitle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(minHeight: 38)
            Text("\(item.unlocked ? "Earned" : "Locked") · \(item.tier.title)")
                .mokoText(Theme.Typeface.badge)
                .foregroundStyle(item.unlocked ? Theme.Colors.sage : Theme.Colors.lockedInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 152)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .mokoCard(fill: Theme.Card.fill)
    }
}

#Preview {
    NavigationStack { ProfileOverViewAchievementsList() }
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingState.self], inMemory: true)
}
