import SwiftUI
import SwiftData

enum AchievementBadgeShapeKind: Hashable { case streak, quest, skill, calm }
enum AchievementTier: Int, Hashable {
    case one = 1, two, three
    var title: String { "Tier \(rawValue)" }
}

struct Achievement: Identifiable, Hashable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
    let shape: AchievementBadgeShapeKind
    let tier: AchievementTier
    let unlocked: Bool

    static func all(profile: Profile?, onboardingCompleted: Bool, quests: [Quest], calmDowns: [CalmDownModel], insights: [InsightsModel], now: Date = .now, calendar: Calendar = .current) -> [Achievement] {
        let completed = quests.filter(\.isCompleted).sorted { ($0.completedAt ?? $0.date) < ($1.completedAt ?? $1.date) }
        func activityDate(_ quest: Quest) -> Date { quest.completedAt ?? quest.date }
        let friendsFamily = completed.filter { $0.category == .friends || $0.category == .family }
        let friends = completed.filter { $0.category == .friends }
        let family = completed.filter { $0.category == .family }
        let work = completed.filter { $0.category == .work }
        let dating = completed.filter { $0.category == .dating }
        let courage = insights.map(\.courage).max() ?? 0
        let clarity = insights.map(\.clarity).max() ?? 0
        let presence = insights.map(\.presence).max() ?? 0
        let warmth = insights.map(\.warmth).max() ?? 0
        let calmMinutes = calmDowns.reduce(0.0) { $0 + $1.exerciseTime } / 60
        let restUsed = hasRestDay(completed, calendar: calendar)
        let returned = hasReturnAfterBreak(completed, calendar: calendar)
        let fiveInWeek = Dictionary(grouping: completed) {
            calendar.dateInterval(of: .weekOfYear, for: activityDate($0))?.start ?? calendar.startOfDay(for: activityDate($0))
        }.values.contains { $0.count >= 5 }

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
        func madePersonalBest() -> Bool {
            let chronological = insights.sorted { $0.date < $1.date }
            let series = [chronological.map(\.courage), chronological.map(\.clarity), chronological.map(\.presence), chronological.map(\.warmth)]
            return series.contains { values in
                var best = Int.min
                for value in values {
                    if best != Int.min && value > best { return true }
                    best = max(best, value)
                }
                return false
            }
        }
        func cameBackUp() -> Bool {
            let series = [insights.sorted { $0.date < $1.date }.map(\.courage), insights.sorted { $0.date < $1.date }.map(\.clarity), insights.sorted { $0.date < $1.date }.map(\.presence), insights.sorted { $0.date < $1.date }.map(\.warmth)]
            return series.contains { values in
                guard values.count >= 3 else { return false }
                return (2..<values.count).contains { i in values[i - 1] < values[i - 2] && values[i] > values[i - 1] }
            }
        }

        let completedCount = completed.count
        let longest = profile?.longestStreak ?? 0
        let calmTitles = calmDowns.map(\.exerciseTitle)
        let unlock: [Int: Bool] = [
            1: onboardingCompleted, 2: completedCount >= 1,
            3: longest >= 3, 4: longest >= 7, 5: longest >= 14, 6: longest >= 30, 7: longest >= 50, 8: longest >= 100,
            9: returned, 10: restUsed,
            11: completedCount >= 5, 12: completedCount >= 10, 13: completedCount >= 25, 14: completedCount >= 50, 15: completedCount >= 100,
            16: quests.contains { $0.xp == nil }, 17: completed.contains { $0.xp == nil }, 18: quests.contains { $0.xp != nil },
            19: completed.contains { $0.intensity == .hard }, 20: fiveInWeek,
            21: !friendsFamily.isEmpty, 22: contains(friends, any: ["honest", "share", "tell", "open up"]),
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
            55: calmDowns.count >= 10, 56: calmMinutes >= 100,
            57: false, 58: madePersonalBest(), 59: hasWeeklySteadiness(), 60: cameBackUp()
        ]

        let catalog: [(String, String, String, AchievementBadgeShapeKind, AchievementTier)] = [
            ("First Step", "Finish onboarding.", "shoeprints.fill", .quest, .one),
            ("Day One", "Complete your first quest.", "sunrise.fill", .quest, .one),
            ("Three Days", "Practise on three consecutive days.", "circle.grid.3x3.fill", .streak, .one),
            ("One Week", "Practise on seven consecutive days.", "circle.dashed.inset.filled", .streak, .one),
            ("Two Weeks", "Practise on fourteen consecutive days.", "link", .streak, .two),
            ("One Month", "Practise on thirty consecutive days.", "calendar", .streak, .two),
            ("Fifty Days", "Practise on fifty consecutive days.", "book.closed", .streak, .three),
            ("Hundred Days", "Practise on one hundred consecutive days.", "laurel.leading", .streak, .three),
            ("Back Again", "Return after three or more full days away.", "arrow.uturn.backward.circle", .streak, .one),
            ("Rest Is Part of It", "Take one rest day after every seven practice days without breaking your streak.", "moon", .streak, .one),
            ("Five Quests", "Complete five quests.", "leaf", .quest, .one),
            ("Ten Quests", "Complete ten quests.", "leaf.fill", .quest, .one),
            ("Twenty-Five Quests", "Complete twenty-five quests.", "leaf", .quest, .two),
            ("Fifty Quests", "Complete fifty quests.", "leaf", .quest, .two),
            ("Hundred Quests", "Complete one hundred quests.", "tree", .quest, .three),
            ("Your Own Quest", "Create your first custom quest.", "flag", .quest, .one),
            ("Event Day", "Finish a custom quest.", "flag.fill", .quest, .one),
            ("From the Library", "Add a scenario from Explore.", "safari", .quest, .one),
            ("The Harder One", "Complete a top-difficulty quest.", "stairs", .quest, .one),
            ("Quest Week", "Complete five quests in one calendar week.", "circle.grid.2x2.fill", .quest, .two),
            ("Opened Up", "Finish a quest with friends or family.", "circle.circle", .quest, .one),
            ("Told a Friend", "Share something honest in a friend quest.", "bubble.left", .quest, .one),
            ("Joined a Group", "Take part in a group quest.", "person.3", .quest, .one),
            ("Spoke in a Group", "Speak or contribute first in a group quest.", "hand.raised", .quest, .one),
            ("Made the Ask", "Complete a dating quest about asking someone out.", "envelope", .quest, .one),
            ("Said No Kindly", "Set a kind boundary in a family quest.", "hand.raised.fill", .quest, .one),
            ("Family Table", "Speak up in a family quest.", "cup.and.saucer", .quest, .one),
            ("Hard Talk at Home", "Finish a difficult family conversation quest.", "chair.lounge", .quest, .one),
            ("Work Hello", "Introduce yourself in a work quest.", "handshake", .quest, .one),
            ("Spoke in a Meeting", "Contribute in a work meeting quest.", "mic", .quest, .one),
            ("Courage I", "Reach a Courage score of 60.", "flame", .skill, .one),
            ("Courage II", "Reach a Courage score of 75.", "flame", .skill, .two),
            ("Courage III", "Reach a Courage score of 90.", "flame", .skill, .three),
            ("Clarity I", "Reach a Clarity score of 60.", "drop", .skill, .one),
            ("Clarity II", "Reach a Clarity score of 75.", "drop", .skill, .two),
            ("Clarity III", "Reach a Clarity score of 90.", "drop", .skill, .three),
            ("Presence I", "Reach a Presence score of 60.", "eye", .skill, .one),
            ("Presence II", "Reach a Presence score of 75.", "eye", .skill, .two),
            ("Presence III", "Reach a Presence score of 90.", "eye", .skill, .three),
            ("Warmth I", "Reach a Warmth score of 60.", "sun.max", .skill, .one),
            ("Warmth II", "Reach a Warmth score of 75.", "sun.max", .skill, .two),
            ("Warmth III", "Reach a Warmth score of 90.", "sun.max", .skill, .three),
            ("First Reflection", "Record your first voice reflection. Reflection tracking is not connected yet.", "waveform", .skill, .one),
            ("Five Reflections", "Record five voice reflections. Reflection tracking is not connected yet.", "waveform", .skill, .one),
            ("Twenty-Five Reflections", "Record twenty-five voice reflections. Reflection tracking is not connected yet.", "waveform", .skill, .two),
            ("Spoke Freely", "Record a voice reflection longer than two minutes. Reflection tracking is not connected yet.", "waveform", .skill, .one),
            ("Reflected Seven Days", "Record reflections on seven consecutive days. Reflection tracking is not connected yet.", "chart.bar", .skill, .two),
            ("Looked Back", "Open Insights after completing a quest. Insight-view tracking is not connected yet.", "arrow.uturn.backward", .skill, .one),
            ("First Calm", "Finish your first calm session.", "water.waves", .calm, .one),
            ("Box Breath", "Finish a box-breathing session.", "square", .calm, .one),
            ("Picture It", "Finish an imagery session.", "mountain.2", .calm, .one),
            ("Grounded", "Finish a 5-4-3-2-1 session.", "circle.grid.3x3", .calm, .one),
            ("Mirror Moment", "Finish a mirror session.", "mirror", .calm, .one),
            ("Calm Before", "Finish a calm session within thirty minutes before a quest.", "water.waves", .calm, .two),
            ("Ten Calm Sessions", "Finish ten calm sessions.", "water.waves", .calm, .two),
            ("Hundred Calm Minutes", "Spend one hundred minutes in calm sessions.", "hourglass", .calm, .three),
            ("First Insight", "View the first written insight. Written insight tracking is not connected yet.", "lightbulb", .skill, .one),
            ("Personal Best", "Beat a previous score in any skill.", "arrow.up.right", .skill, .one),
            ("Steady Week", "Keep all four skill scores within one point for seven days.", "equal", .skill, .two),
            ("Comeback", "Raise a skill score after it dipped.", "chart.line.uptrend.xyaxis", .skill, .one)
        ]
        return catalog.enumerated().map { offset, row in
            Achievement(id: offset + 1, title: row.0, detail: row.1, symbol: row.2, shape: row.3, tier: row.4, unlocked: unlock[offset + 1] ?? false)
        }
    }

    private static func dayGap(_ previous: Date, _ next: Date, _ calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: previous), to: calendar.startOfDay(for: next)).day ?? 0
    }
    private static func hasReturnAfterBreak(_ quests: [Quest], calendar: Calendar) -> Bool {
        guard quests.count > 1 else { return false }
        for index in 1..<quests.count where dayGap(quests[index - 1].completedAt ?? quests[index - 1].date, quests[index].completedAt ?? quests[index].date, calendar) >= 4 { return true }
        return false
    }
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
private enum BadgePalette {
    static let teal = Color(hex: 0x1F7488)
    static let lightTeal = Color(hex: 0x3D94A8)
    static let white = Color(hex: 0xFFFFFF)
    static let cream = Color(hex: 0xF7F5F2)
    static let brown = Color(hex: 0x4A3826)
    static let gold = Color(hex: 0xD9A441)
    static let silver = Color(hex: 0xB9C1C3)
    static let locked = Color(hex: 0xB8BDBD)
    static let lockedFace = Color(hex: 0xD8DADA)
}

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

struct AchievementBadgeView: View {
    let achievement: Achievement
    var size: CGFloat = 74
    private var rim: Color {
        guard achievement.unlocked else { return BadgePalette.locked }
        switch achievement.tier { case .one: return BadgePalette.lightTeal; case .two: return BadgePalette.silver; case .three: return BadgePalette.gold }
    }
    var body: some View {
        let artSize = size * 0.76 // leaves 12% clear space on every side
        ZStack {
            AchievementBadgeShape(kind: achievement.shape).fill(rim)
            AchievementBadgeShape(kind: achievement.shape).fill(achievement.unlocked ? BadgePalette.teal : BadgePalette.lockedFace).padding(artSize * 0.075)
            AchievementBadgeShape(kind: achievement.shape).stroke(achievement.unlocked ? BadgePalette.brown.opacity(0.38) : BadgePalette.locked.opacity(0.75), lineWidth: 1).padding(artSize * 0.12)
            Image(systemName: achievement.symbol)
                .font(.system(size: artSize * 0.31, weight: .regular))
                .foregroundStyle(achievement.unlocked ? BadgePalette.white : BadgePalette.locked)
                .frame(width: artSize * 0.45, height: artSize * 0.45)
        }
        .frame(width: artSize, height: artSize)
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title), \(achievement.unlocked ? "earned" : "locked"), \(achievement.tier.title)")
    }
}

struct ProfileOverViewAchievementsList: View {
    @Query private var profiles: [Profile]
    @Query private var quests: [Quest]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var insights: [InsightsModel]
    @Query private var onboardingStates: [OnboardingState]

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
                    Text("60 badges").font(.caption).foregroundStyle(BadgePalette.brown.opacity(0.7))
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(achievements) { item in
                        NavigationLink { ProfileOverViewAchievementDetailUnlocked(achievement: item) } label: { card(item) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 24)
        }
        .background(MokoTheme.limeBackground.ignoresSafeArea())
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private func card(_ item: Achievement) -> some View {
        VStack(spacing: 9) {
            AchievementBadgeView(achievement: item, size: 74)
            Text(item.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(BadgePalette.brown)
                .multilineTextAlignment(.center).lineLimit(2).frame(height: 38)
            Text("\(item.unlocked ? "Earned" : "Locked") · \(item.tier.title)")
                .font(.caption2.weight(.medium)).foregroundStyle(item.unlocked ? BadgePalette.teal : BadgePalette.brown.opacity(0.62))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 152).padding(.vertical, 14).padding(.horizontal, 8)
        .background(Color(hex: 0xFFFFFF), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(BadgePalette.lightTeal.opacity(0.16), lineWidth: 1))
    }
}

#Preview {
    NavigationStack { ProfileOverViewAchievementsList() }
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingState.self], inMemory: true)
}
