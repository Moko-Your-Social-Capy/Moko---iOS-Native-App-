//
//  ProfileOverView.swift
//  Moko
//
//  Profile screen (matches the "Profile · Overview · Light" prototype).
//  Open it from the Overview avatar ("AJ") with:
//      NavigationLink { ProfileOverView() } label: { ...avatar... }
//  It must be inside a NavigationStack, which gives the default back button.
//

import SwiftUI
import Charts
import SwiftData
import PhotosUI

struct ProfileOverView: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)     // #1B422F
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)     // #365948
    private let cream = Color(red: 246/255, green: 232/255, blue: 190/255)

    // Real data from SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @Query private var calmDowns: [CalmDownModel]

    @State private var photoItem: PhotosPickerItem?

    private var profile: Profile? { profiles.first }
    private var hasName: Bool { profile?.username.isEmpty == false }
    private var name: String { hasName ? profile!.username : "New here" }
    private var streak: Int { profile?.currentStreak ?? 0 }
    private var totalXP: Int { profile?.xp ?? 0 }
    private var sets: Int { calmDowns.count }          // completed calm down sets
    private var level: Int { totalXP / 100 + 1 }       // 100 XP per level
    private var achievements: [Achievement] {
        Achievement.all(profile: profile, calmDownCount: calmDowns.count)
    }

    @State private var range = Range.week
    @State private var showEditProfile = false

    enum Range: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month"
        var id: String { rawValue }
    }

    private struct Bar: Identifiable {
        let label: String
        let xp: Int
        var id: String { label }
    }

    private var bars: [Bar] {
        switch range {
        case .day:
            return [("6a", 10), ("9a", 40), ("12p", 65), ("3p", 30), ("6p", 80), ("9p", 45)].map { Bar(label: $0.0, xp: $0.1) }
        case .week:
            return [("M", 40), ("T", 65), ("W", 0), ("T2", 80), ("F", 55), ("S", 90), ("S2", 22)].map { Bar(label: $0.0, xp: $0.1) }
        case .month:
            return [("W1", 300), ("W2", 420), ("W3", 352), ("W4", 480)].map { Bar(label: $0.0, xp: $0.1) }
        }
    }

    private var totalForRange: Int { bars.reduce(0) { $0 + $1.xp } }
    private var hasEarnedXP: Bool { totalXP > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Button("Edit Profile") { showEditProfile = true }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                statsRow
                streakBanner
                journeyCard
                achievementsSection
                linksList
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(screenBg)
        .task(id: photoItem) { await savePickedPhoto() }
        .navigationBarTitleDisplayMode(.inline)
        .tint(deepGreen)
        .sheet(isPresented: $showEditProfile) {
            ProfileOverViewEditProfile()
        }
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 16) {
            // Tap the photo to choose one (works for a new account too)
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let data = profile?.profileImageData, let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else {
                            Image(systemName: "person")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 96, height: 96)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())

                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(deepGreen)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.title.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let age = profile?.age, age > 0 {
                    Text("Age \(age)")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Add your name and age")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Level \(level)")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(cream))
            }
            Spacer(minLength: 0)
        }
    }

    /// Saves the chosen photo straight into the Profile (creates one for a new account).
    private func savePickedPhoto() async {
        guard let data = try? await photoItem?.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.8) else { return }

        if let profile {
            profile.profileImageData = jpeg
            profile.updatedAt = .now
        } else {
            modelContext.insert(Profile(username: "", age: 0, profileImageData: jpeg))
        }
        do { try modelContext.save() } catch { print("Photo save failed:", error) }
    }

    // MARK: Stats
    private var statsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                stat("flame", streak > 0 ? "\(streak)" : "Not started", "Day streak")
                stat("checkmark.circle", "\(sets)", "Sets completed")
                stat("sparkle", totalXP.formatted(), "Total XP")
            }
        }
    }

    private func stat(_ symbol: String, _ value: String, _ title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(deepGreen)
                .frame(width: 32, height: 32)
                .background(Circle().fill(cream))
            Text(value)
                .font(value == "Not started" ? .subheadline.bold() : .title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: 28)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 6)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Streak banner (opens the achievement detail)
    @ViewBuilder
    private var streakBanner: some View {
        if (profile?.longestStreak ?? 0) >= 30 {
        NavigationLink {
            ProfileOverViewAchievementDetailUnlocked()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("30-Streak unlocked").font(.headline)
                    Text("See what you have earned so far.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(cream, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        }
    }

    // MARK: Your Journey
    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Journey").font(.title3.bold())

            VStack(alignment: .leading, spacing: 10) {
                Picker("Range", selection: $range) {
                    ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Daily XP earned")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if hasEarnedXP {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(totalForRange) XP").font(.title.bold())
                        Text("This \(range.rawValue.lowercased()) · sample data")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Chart(bars) { bar in
                        BarMark(x: .value("Day", bar.label), y: .value("XP", bar.xp))
                            .foregroundStyle(cardGreen)
                            .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                // "T2" / "S2" are only unique ids; show the first letter
                                if let s = value.as(String.self) { Text(String(s.prefix(range == .week ? 1 : 3))) }
                            }
                        }
                    }
                    .frame(height: 170)
                } else {
                    // New account: nothing earned yet
                    Text("0 XP").font(.title.bold())

                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("Not started")
                            .font(.headline)
                        Text("Complete a mission to earn XP and see your journey here.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements").font(.title3.bold())
                Spacer()
                NavigationLink("View All") {
                    ProfileOverViewAchievementsList()
                }
                .font(.subheadline.bold())
            }

            HStack(spacing: 10) {
                ForEach(achievements) { item in
                    badge(item.unlocked ? item.symbol : "lock",
                          item.title, unlocked: item.unlocked)
                }
            }
        }
    }

    private func badge(_ symbol: String, _ title: String, unlocked: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(unlocked ? .orange : .secondary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(unlocked ? cream : Color(.systemGray5)))
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(unlocked ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Settings / Account & Data
    private var linksList: some View {
        VStack(spacing: 0) {
            NavigationLink {
                ProfileOverViewSettingsOverview()
            } label: {
                linkRow("Settings", "gearshape")
            }
            Divider().padding(.leading, 56)
            NavigationLink {
                ProfileOverViewAccountAndData()
            } label: {
                linkRow("Account & Data", "person")
            }
        }
        .buttonStyle(.plain)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private func linkRow(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(deepGreen)
                .frame(width: 32, height: 32)
                .background(Circle().fill(cream))
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ProfileOverView()
    }
    .modelContainer(for: [Profile.self, CalmDownModel.self], inMemory: true)
}
