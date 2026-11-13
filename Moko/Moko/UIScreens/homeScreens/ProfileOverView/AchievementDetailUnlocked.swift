import SwiftUI

private typealias Theme = MocoScreenTheme

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
                BadgeUnlockAnimation(achievement: achievement)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
            } else {
                AchievementBadgeView(achievement: achievement, size: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
            }

            Text(achievement.title)
                .mocoText(Theme.Typeface.profileName)
                .foregroundStyle(Theme.Colors.textTitle)
                .multilineTextAlignment(.center)

            Text(achievement.unlocked ? "Earned · \(achievement.tier.title)" : "Locked · \(achievement.tier.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(achievement.unlocked ? ProfilePalette.accent : ProfilePalette.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(ProfilePalette.grouped, in: Capsule())

            Text(achievement.detail)
                .mocoText(Theme.Typeface.body)
                .foregroundStyle(Theme.Colors.textBody)
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

private struct BadgeUnlockAnimation: View {
    let achievement: Achievement

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var tilt = 0.0

    var body: some View {
        AchievementBadgeView(achievement: achievement, size: 244)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : tilt), axis: (x: 0, y: 1, z: 0))
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard !reduceMotion else { return }
                        tilt = min(25, max(-25, value.translation.width / 4))
                    }
                    .onEnded { _ in
                        withAnimation(Theme.Motion.snapBack) { tilt = 0 }
                    }
            )
            .sensoryFeedback(.success, trigger: appeared)
            .onAppear {
                withAnimation(reduceMotion ? Theme.Motion.crossfade : Theme.Motion.mascotEntrance) {
                    appeared = true
                }
            }
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
