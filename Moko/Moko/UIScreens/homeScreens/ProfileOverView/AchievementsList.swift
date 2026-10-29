//
//  ProfileOverViewAchievementsList.swift
//  Moko
//
//  Achievements grid (matches the "Achievements · List · Light" prototype).
//  Push it from Profile with:
//      NavigationLink("View All") { ProfileOverViewAchievementsList() }
//  Unlocked cards open ProfileOverViewAchievementDetailUnlocked.
//  The NavigationStack gives the default back button, so none is drawn here.
//

import SwiftUI
import SwiftData

/// One achievement. Unlocked states come from the Profile and CalmDownModel data.
struct Achievement: Identifiable {
    let title: String
    let symbol: String
    let detail: String
    let unlocked: Bool
    var id: String { title }

    static func all(profile: Profile?, calmDownCount: Int) -> [Achievement] {
        [
            Achievement(title: "Early Dawn", symbol: "sun.max", detail: "Practise before 7 AM.",
                        unlocked: profile?.lastActivityDate.map { Calendar.current.component(.hour, from: $0) < 7 } ?? false),
            Achievement(title: "Zen Mind", symbol: "leaf", detail: "Finish a calm down set.",
                        unlocked: calmDownCount > 0),
            Achievement(title: "30-Streak", symbol: "trophy", detail: "Practise 30 days in a row.",
                        unlocked: (profile?.longestStreak ?? 0) >= 30),
            Achievement(title: "Stillness", symbol: "lock", detail: "Complete a long, quiet session.",
                        unlocked: false)
        ]
    }
}

struct ProfileOverViewAchievementsList: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7

    @Query private var profiles: [Profile]
    @Query private var calmDowns: [CalmDownModel]

    private var achievements: [Achievement] {
        Achievement.all(profile: profiles.first, calmDownCount: calmDowns.count)
    }

    private var unlockedCount: Int { achievements.filter(\.unlocked).count }

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(unlockedCount) of \(achievements.count) unlocked")
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(achievements) { item in
                        if item.unlocked {
                            NavigationLink {
                                ProfileOverViewAchievementDetailUnlocked(title: item.title,
                                                                         symbol: item.symbol,
                                                                         detail: item.detail)
                            } label: {
                                card(item)
                            }
                            .buttonStyle(.plain)
                        } else {
                            card(item)
                        }
                    }
                }

            }
            .padding(.horizontal, 16)
        }
        .background(screenBg)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private func card(_ item: Achievement) -> some View {
        VStack(spacing: 10) {
            Image(systemName: item.symbol)
                .font(.title2)
                .foregroundStyle(item.unlocked ? .orange : .secondary)
                .frame(width: 64, height: 64)
                .background(Circle().fill(item.unlocked ? Color.orange.opacity(0.18) : Color(.systemGray5)))

            Text(item.title)
                .font(.headline)

            if item.unlocked {
                Text("Unlocked")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Locked · \(item.detail)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewAchievementsList()
    }
    .modelContainer(for: [Profile.self, CalmDownModel.self], inMemory: true)
}
