import SwiftUI
import Charts
import SwiftData
import UIKit

/// Profile is presented as a sheet from the Overview avatar.
struct ProfileOverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [Profile]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var quests: [Quest]
    @Query private var insights: [InsightsModel]
    @Query private var onboardingStates: [OnboardingState]

    @State private var countProgress = 0.0
    @State private var xpRange: XPChartRange = .week
    @State private var selectedXPDay: Date?
    @State private var activeSheet: ProfileSheet?

    private var profile: Profile? { profiles.first }
    private var username: String { profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
    private var displayName: String { username.isEmpty ? "Your profile" : username }
    private var xp: Int { profile?.xp ?? 0 }
    private var level: Int { xp / 400 + 1 }
    private var levelXP: Int { xp % 400 }
    private var streak: Int { profile?.currentStreak ?? 0 }
    private var localQuests: [Quest] { quests.filter { $0.ownerID == CurrentUser.localID } }
    private var achievements: [Achievement] {
        Achievement.all(
            profile: profile,
            onboardingCompleted: onboardingStates.contains(where: \.isCompleted),
            quests: localQuests,
            calmDowns: calmDowns,
            insights: insights
        )
    }
    private var earnedBadges: [Achievement] {
        Array(achievements.filter(\.unlocked).sorted { $0.id > $1.id }.prefix(4))
    }

    private struct WeeklyAverage: Identifiable {
        let week: Date
        let score: Double
        var id: Date { week }
    }

    private var weeklyAverages: [WeeklyAverage] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -56, to: .now) ?? .distantPast
        let recent = insights.filter { $0.date >= cutoff }
        let grouped = Dictionary(grouping: recent) { record in
            calendar.dateInterval(of: .weekOfYear, for: record.date)?.start ?? calendar.startOfDay(for: record.date)
        }
        return grouped.map { week, records in
            let values = records.map { Double($0.courage + $0.clarity + $0.presence + $0.warmth) / 4 }
            return WeeklyAverage(week: week, score: values.reduce(0, +) / Double(values.count))
        }.sorted { $0.week < $1.week }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 18) {
                        identityHeader
                        if earnedBadges.isEmpty { profileEmptyScene }
                    }
                    .profileEntrance(order: 0, reduceMotion: reduceMotion)
                    streakRow.profileEntrance(order: 1, reduceMotion: reduceMotion)
                    badgesSection.profileEntrance(order: 2, reduceMotion: reduceMotion)
                    growthSection.profileEntrance(order: 3, reduceMotion: reduceMotion)
                    wardrobeLink.profileEntrance(order: 4, reduceMotion: reduceMotion)
                    settingsSection.profileEntrance(order: 5, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(ProfilePalette.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close profile")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { activeSheet = .editProfile }
                        .fontWeight(.semibold)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
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

    private var identityHeader: some View {
        HStack(spacing: 16) {
            MokoCostumeAvatar(level: level, photoData: profile?.profileImageData, size: 68)

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(ProfilePalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Level \(animated(level)) · \(animated(levelXP)) / 400 XP")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(ProfilePalette.secondary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Level \(level), \(xp) experience points")
                ProgressView(value: Double(levelXP), total: 400)
                    .tint(ProfilePalette.accent)
                    .frame(maxWidth: 210)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .contain)
    }

    private var streakRow: some View {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(ProfilePalette.accent)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                if streak > 0 {
                    Text("\(animated(streak)) day streak")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ProfilePalette.text)
                        .contentTransition(.numericText())
                        Text("One rest day can keep your streak after seven practice days.")
                        .font(.subheadline)
                        .foregroundStyle(ProfilePalette.secondary)
                } else {
                    Text("Your first quest starts it")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ProfilePalette.text)
                }
            }
            Spacer(minLength: 0)
          }
          weeklyStreakDots
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streak > 0 ? "\(streak) day streak. One rest day is available after seven practice days." : "Your first quest starts it.")
    }

    private var weeklyStreakDots: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let activityDays = Set(localQuests.filter(\.isCompleted).map { calendar.startOfDay(for: $0.completedAt ?? $0.date) })
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
                let practiced = activityDays.contains(day)
                let dayBefore = calendar.date(byAdding: .day, value: -1, to: day)
                let dayAfter = calendar.date(byAdding: .day, value: 1, to: day)
                let restDay = !practiced && dayBefore.map(activityDays.contains) == true && dayAfter.map(activityDays.contains) == true
                let isToday = calendar.isDate(day, inSameDayAs: today)
                VStack(spacing: 5) {
                    Circle()
                        .fill(practiced ? ProfilePalette.success : (restDay ? ProfilePalette.accent.opacity(0.25) : ProfilePalette.text.opacity(0.12)))
                        .overlay(Circle().stroke(isToday ? ProfilePalette.accent : .clear, lineWidth: 1.5))
                        .frame(width: 12, height: 12)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2)
                        .foregroundStyle(ProfilePalette.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(practiced ? "practice completed" : (restDay ? "rest day" : "no practice recorded"))")
            }
        }
        .padding(.leading, 58)
        .overlay(alignment: .bottom) {
            HStack(spacing: 12) {
                Label("Done", systemImage: "circle.fill").foregroundStyle(ProfilePalette.success)
                Label("Rest", systemImage: "circle.fill").foregroundStyle(ProfilePalette.accent.opacity(0.55))
                Label("No practice yet", systemImage: "circle.fill").foregroundStyle(ProfilePalette.text.opacity(0.34))
            }
            .font(.caption2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(y: 18)
        }
        .padding(.bottom, 18)
    }

    /// The new-user illustration follows Moko's calm seated pose. The room is
    /// drawn with native vector shapes; the existing character PNG is the only image.
    private var profileEmptyScene: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ProfilePalette.grouped

                Rectangle()
                    .fill(ProfilePalette.accent.opacity(0.13))
                    .frame(width: 88, height: 62)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(ProfilePalette.accent.opacity(0.38)).frame(height: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .position(x: 74, y: 45)

                HStack(alignment: .bottom) {
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(ProfilePalette.accent.opacity(0.72))
                        .padding(.bottom, 56)
                    Image("profile_empty_moko")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 126)
                        .accessibilityHidden(true)
                }
                .padding(.trailing, max(18, geometry.size.width * 0.08))
                .padding(.bottom, 2)

                Rectangle()
                    .fill(ProfilePalette.secondary.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .frame(height: 156)
        .accessibilityLabel("Moko sits calmly in a quiet room with a window and plant")
        .accessibilityAddTraits(.isImage)
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(ProfilePalette.text)
                Spacer()
                NavigationLink {
                    ProfileOverViewAchievementsList()
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    Text("See All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ProfilePalette.accent)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                }
                .accessibilityLabel("See all badges")
            }

            if earnedBadges.isEmpty {
                HStack(spacing: 14) {
                    AchievementBadgeView(achievement: achievements.first(where: { !$0.unlocked }) ?? emptyLockedAchievement, size: 72)
                        .accessibilityHidden(true)
                    Text("Your first badge will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(ProfilePalette.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No badges yet. Your first badge will appear here.")
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(earnedBadges) { badge in
                            badgeButton(badge)
                        }
                        if let locked = achievements.first(where: { !$0.unlocked }) {
                            badgeButton(locked)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.trailing, 2)
            }
        }
    }

    private func badgeButton(_ achievement: Achievement) -> some View {
        Button {
            activeSheet = .badge(achievement)
        } label: {
            VStack(spacing: 6) {
                AchievementBadgeView(achievement: achievement, size: 72)
                Text(achievement.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ProfilePalette.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80, height: 32, alignment: .top)
            }
            .contentShape(Rectangle())
            .frame(width: 84)
            .frame(minHeight: 112)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(achievement.title), \(achievement.unlocked ? "earned" : "locked") badge")
    }

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Growth")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(ProfilePalette.text)
            Text(growthTakeaway)
                .font(.subheadline)
                .foregroundStyle(ProfilePalette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("XP period", selection: $xpRange) {
                ForEach(XPChartRange.allCases) { range in Text(range.title).tag(range) }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("XP chart period")

            xpChart

            if weeklyAverages.isEmpty {
                Text("Your first reflection will start this line.")
                    .font(.subheadline)
                    .foregroundStyle(ProfilePalette.secondary)
                    .frame(maxWidth: .infinity, minHeight: 116, alignment: .center)
                    .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityLabel("No growth data yet. Your first reflection will start this line.")
            } else {
                Chart(weeklyAverages) { point in
                    LineMark(
                        x: .value("Week", point.week),
                        y: .value("Average skill score", point.score)
                    )
                    .foregroundStyle(ProfilePalette.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    if weeklyAverages.count == 1 {
                        PointMark(x: .value("Week", point.week), y: .value("Average skill score", point.score))
                            .foregroundStyle(ProfilePalette.accent)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 132)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel("Line chart of the average of Courage, Clarity, Presence, and Warmth scores over the last eight weeks.")
            }
        }
    }

    private var xpChart: some View {
        let values = dailyXP
        let domainStart = values.first?.day ?? .now
        let domainEnd = values.last?.day ?? .now
        return Chart {
            ForEach(values) { item in
                BarMark(x: .value("Day", item.day, unit: .day), y: .value("XP", item.xp), width: .ratio(0.56))
                    .foregroundStyle(ProfilePalette.accent)
                    .cornerRadius(4)
                    .opacity(selectedXPDay.map { Calendar.current.isDate($0, inSameDayAs: item.day) ? 1 : 0.58 } ?? 0.9)
                if item.xp == 0 {
                    RuleMark(x: .value("Day", item.day, unit: .day), yStart: .value("Base", 0), yEnd: .value("Empty", max(1, maxDailyXP * 0.035)))
                        .foregroundStyle(ProfilePalette.secondary.opacity(0.28))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
            if let selectedXPDay, let value = values.first(where: { Calendar.current.isDate($0.day, inSameDayAs: selectedXPDay) }) {
                RuleMark(x: .value("Selected day", value.day, unit: .day))
                    .foregroundStyle(ProfilePalette.secondary.opacity(0.5))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(value.xp) XP · \(value.day.formatted(.dateTime.weekday(.abbreviated)))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ProfilePalette.text)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(ProfilePalette.grouped, in: Capsule())
                    }
            }
        }
        .chartXScale(domain: domainStart...domainEnd)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: xpRange == .threeMonths ? 14 : 1)) { value in
                AxisGridLine().foregroundStyle(ProfilePalette.secondary.opacity(0.1))
                AxisTick()
                AxisValueLabel(format: xpRange == .week ? .dateTime.weekday(.narrow) : .dateTime.day(), centered: true)
            }
        }
        .chartYScale(domain: 0...maxDailyXP)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine().foregroundStyle(ProfilePalette.text.opacity(0.10))
                AxisValueLabel {
                    if let xp = value.as(Int.self) {
                        Text("\(xp)")
                            .font(.caption2)
                            .foregroundStyle(ProfilePalette.secondary)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.background(ProfilePalette.grouped.opacity(0.22))
        }
        .chartXSelection(value: $selectedXPDay)
        .frame(height: 132)
        .padding(12)
        .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("Daily XP chart")
    }

    private var maxDailyXP: Double { max(1, dailyXP.map(\.xp).max() ?? 1) }

    private var dailyXP: [DailyXP] {
        let calendar = Calendar.current
        let count = xpRange.dayCount
        let start = calendar.date(byAdding: .day, value: -(count - 1), to: calendar.startOfDay(for: .now)) ?? .now
        let sums = Dictionary(grouping: localQuests.filter(\.isCompleted)) { calendar.startOfDay(for: $0.completedAt ?? $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.awardedXP } }
        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DailyXP(day: date, xp: Double(sums[date, default: 0]))
        }
    }

    private var wardrobeLink: some View {
        NavigationLink {
            MokoWardrobeView(level: level)
        } label: {
            HStack(spacing: 14) {
                MokoCostumeAvatar(level: level, photoData: nil, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Moko’s wardrobe").font(.system(.headline, design: .rounded)).foregroundStyle(ProfilePalette.text)
                    Text("\(MokoCostume.unlockedCount(for: level)) of \(MokoCostume.all.count) costumes unlocked").font(.subheadline).foregroundStyle(ProfilePalette.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(ProfilePalette.secondary)
            }
            .padding(14)
            .frame(minHeight: 68)
            .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }.buttonStyle(.plain)
    }

    private var growthTakeaway: String {
        guard weeklyAverages.count >= 2,
              let first = weeklyAverages.first?.score,
              let last = weeklyAverages.last?.score else {
            return "Your four-skill average over the last 8 weeks."
        }
        if last > first + 2 { return "Your four-skill average is moving upward." }
        if last < first - 2 { return "Your progress has room to move at your pace." }
        return "Your four-skill average is holding steady."
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(ProfilePalette.text)

            VStack(spacing: 0) {
                settingsLink("Account Info", symbol: "person.crop.circle", destination: AnyView(ProfileOverViewAccountAndData()))
                settingsDivider
                settingsLink("Reminders and Notifications", symbol: "bell", destination: AnyView(ProfileOverViewNotifications()))
                settingsDivider
                settingsLink("All Settings", symbol: "gearshape", destination: AnyView(ProfileOverViewSettingsOverview()))
            }
            .padding(.horizontal, 16)
            .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var settingsDivider: some View {
        Divider().overlay(ProfilePalette.secondary.opacity(0.18)).padding(.leading, 44)
    }

    private func settingsLink(_ title: String, symbol: String, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.body.weight(.medium))
                    .foregroundStyle(ProfilePalette.accent)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.body)
                    .foregroundStyle(ProfilePalette.text)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ProfilePalette.secondary.opacity(0.65))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var emptyLockedAchievement: Achievement {
        Achievement(id: -1, title: "First Step", detail: "Finish onboarding.", symbol: "shoeprints.fill", shape: .quest, tier: .one, unlocked: false)
    }

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
        withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.6)) {
            countProgress = 1
        }
    }
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

enum ProfilePalette {
    static let background = Color(hex: 0xF7F5F2)
    static let grouped = Color(hex: 0xF7F5F2)
    static let text = Color(hex: 0x4A3826)
    static let secondary = Color(hex: 0x4A3826).opacity(0.70)
    static let accent = Color(hex: 0x1F7488)
    static let lime = Color(hex: 0xE2F5B1)
    static let success = Color(hex: 0x2F6E4A)
    static let error = Color(hex: 0xB9583F)
}

private enum XPChartRange: String, CaseIterable, Identifiable {
    case week, month, threeMonths
    var id: Self { self }
    var title: String { switch self { case .week: "Week"; case .month: "Month"; case .threeMonths: "3 Months" } }
    var dayCount: Int { switch self { case .week: 7; case .month: 30; case .threeMonths: 90 } }
}
private struct DailyXP: Identifiable {
    let day: Date
    let xp: Double
    var id: Date { day }
}

private struct ProfileEntranceModifier: ViewModifier {
    let order: Int
    let reduceMotion: Bool
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: reduceMotion || isVisible ? 0 : 12)
            .onAppear {
                guard !isVisible else { return }
                if order >= 6 {
                    isVisible = true
                } else {
                    let animation = reduceMotion
                        ? Animation.easeInOut(duration: 0.2)
                        : Animation.spring(response: 0.42, dampingFraction: 0.88).delay(Double(order) * 0.04)
                    withAnimation(animation) { isVisible = true }
                }
            }
    }
}

private extension View {
    func profileEntrance(order: Int, reduceMotion: Bool) -> some View {
        modifier(ProfileEntranceModifier(order: order, reduceMotion: reduceMotion))
    }
}

private struct ProfileSettingInfoScreen: View {
    let title: String
    let detail: String

    var body: some View {
        List {
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .listRowBackground(ProfilePalette.grouped)
        }
        .scrollContentBackground(.hidden)
        .background(ProfilePalette.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ProfileOverView()
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingState.self], inMemory: true)
}
