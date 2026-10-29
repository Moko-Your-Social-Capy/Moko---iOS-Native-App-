//
//  ProfileOverViewAchievementDetailUnlocked.swift
//  Moko
//
//  Achievement detail, unlocked (matches the "Achievement · Detail unlocked" prototype).
//  Push it with:
//      NavigationLink { ProfileOverViewAchievementDetailUnlocked() } label: { ... }
//  The NavigationStack gives the default back button, so none is drawn here.
//

import SwiftUI

struct ProfileOverViewAchievementDetailUnlocked: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)     // #365948
    private let cream = Color(red: 246/255, green: 232/255, blue: 190/255)

    // Defaults match the prototype; pass other values for other achievements.
    var title = "30-Streak"
    var symbol = "trophy"
    var detail = "Practise 30 days in a row."

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            ZStack(alignment: .topTrailing) {
                Image(systemName: symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                    .frame(width: 140, height: 140)
                    .background(Circle().fill(Color.orange.opacity(0.18)))

                Image(systemName: "party.popper.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(cream))
                    .offset(x: 50, y: -50)
            }
            .padding(.bottom, 20)

            Text(title)
                .font(.largeTitle.bold())

            Text("Unlocked")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(cream))

            Text(detail)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Sample state for design only.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background(screenBg)
        .safeAreaInset(edge: .bottom) {
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(cardGreen)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewAchievementDetailUnlocked()
    }
}
