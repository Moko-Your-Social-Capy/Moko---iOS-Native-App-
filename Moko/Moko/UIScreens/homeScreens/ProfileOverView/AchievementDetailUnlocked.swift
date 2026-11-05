import SwiftUI

struct ProfileOverViewAchievementDetailUnlocked: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    init(achievement: Achievement) {
        self.achievement = achievement
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 24)

            if achievement.unlocked {
                BadgeUnlockRiveView(achievement: achievement)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
            } else {
                AchievementBadgeView(achievement: achievement, size: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
            }

            Text(achievement.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(ProfilePalette.text)
                .multilineTextAlignment(.leading)

            Text(achievement.unlocked ? "Earned · \(achievement.tier.title)" : "Locked · \(achievement.tier.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(achievement.unlocked ? ProfilePalette.accent : ProfilePalette.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(ProfilePalette.grouped, in: Capsule())

            Text(achievement.detail)
                .font(.system(size: 17))
                .foregroundStyle(ProfilePalette.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background(ProfilePalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewAchievementDetailUnlocked(
            achievement: Achievement(
                id: 6,
                title: "One Month",
                detail: "Practise on thirty consecutive days.",
                symbol: "calendar",
                shape: .streak,
                tier: .two,
                unlocked: true
            )
        )
    }
}
