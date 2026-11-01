import SwiftUI
import Charts
import SwiftData
import UIKit

/// Profile is presented as a sheet from the Overview avatar.
struct ProfileOverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.endSession) private var endSession
    @Query private var profiles: [Profile]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var quests: [Quest]
    @Query private var insights: [InsightsModel]
    @Query private var onboardingStates: [OnboardingState]

    @State private var showSignOut = false
    @State private var countProgress = 0.0

    private var profile: Profile? { profiles.first }
    private var username: String { profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
    private var displayName: String { username.isEmpty ? "Your profile" : username }
    private var initials: String {
        let parts = username.split(whereSeparator: \.isWhitespace)
        let letters = parts.prefix(2).compactMap(\.first)
        return letters.isEmpty ? "M" : String(letters).uppercased()
    }
    private var xp: Int { profile?.xp ?? 0 }
    private var level: Int { xp / 100 + 1 }
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
                    settingsSection.profileEntrance(order: 4, reduceMotion: reduceMotion)
                    signOutButton.profileEntrance(order: 5, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(ProfilePalette.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Close profile")
                }
            }
            .tint(ProfilePalette.accent)
            .task { animateNumbersOnce() }
            .signOutAlert(isPresented: $showSignOut) {
                guard let endSession else { return }
                endSession(.signOut)
                Task { try? await AuthService().signOut() }
            }
        }
        .preferredColorScheme(nil)
    }

    private var identityHeader: some View {
        HStack(spacing: 16) {
            Text(initials)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.accent)
                .frame(width: 64, height: 64)
                .background(ProfilePalette.grouped, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(ProfilePalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Level \(animated(level)) · \(animated(xp)) XP")
                    .font(.body)
                    .foregroundStyle(ProfilePalette.secondary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Level \(level), \(xp) experience points")
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), level \(level), \(xp) XP")
    }

    private var streakRow: some View {
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
                    Text("1 rest day available")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streak > 0 ? "\(streak) day streak. 1 rest day available." : "Your first quest starts it.")
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
                    .padding(.horizontal, 18)
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
                .padding(14)
                .background(ProfilePalette.grouped, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        NavigationLink {
            ProfileOverViewAchievementDetailUnlocked(achievement: achievement)
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
                settingsLink("Reminders", symbol: "bell", destination: AnyView(ProfileOverViewNotifications()))
                settingsDivider
                settingsLink("Apple Health", symbol: "heart", destination: AnyView(ProfileSettingInfoScreen(title: "Apple Health", detail: "Apple Health connection is not available yet.")))
                settingsDivider
                settingsLink("Privacy and voice data", symbol: "hand.raised", destination: AnyView(ProfileOverViewPrivacy()))
                settingsDivider
                settingsLink("Language", symbol: "globe", destination: AnyView(ProfileSettingInfoScreen(title: "Language", detail: "MOKO currently follows the language set for your iPhone.")))
                settingsDivider
                settingsLink("Help", symbol: "questionmark.circle", destination: AnyView(ProfileOverViewHelpSupport()))
                settingsDivider
                settingsLink("About", symbol: "info.circle", destination: AnyView(ProfileOverViewAboutMoko()))
            }
            .padding(.horizontal, 14)
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

    private var signOutButton: some View {
        Button("Sign Out", role: .destructive) { showSignOut = true }
            .font(.body)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel("Sign out of MOKO")
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

@MainActor
private enum ProfileSessionAnimation {
    static var didAnimateNumbers = false
}

private enum ProfilePalette {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1) : .white
    })
    static let grouped = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1) : UIColor(red: 247/255, green: 245/255, blue: 242/255, alpha: 1)
    })
    static let text = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.95, alpha: 1) : UIColor(red: 74/255, green: 56/255, blue: 38/255, alpha: 1)
    })
    static let secondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.72, alpha: 1) : UIColor(red: 107/255, green: 91/255, blue: 68/255, alpha: 1)
    })
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 61/255, green: 148/255, blue: 168/255, alpha: 1) : UIColor(red: 31/255, green: 116/255, blue: 136/255, alpha: 1)
    })
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
