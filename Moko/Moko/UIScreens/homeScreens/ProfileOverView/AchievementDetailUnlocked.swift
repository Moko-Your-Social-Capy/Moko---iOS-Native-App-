import SwiftUI

struct ProfileOverViewAchievementDetailUnlocked: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    init(achievement: Achievement) {
        self.achievement = achievement
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 24)

            BadgeUnlockRiveView(achievement: achievement)
            .padding(.bottom, 12)

            Text(achievement.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(MokoTheme.titleBrown)
                .multilineTextAlignment(.center)

            Text(achievement.unlocked ? "Earned · \(achievement.tier.title)" : "Locked · \(achievement.tier.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(achievement.unlocked ? Color(hex: 0x1F7488) : MokoTheme.titleBrown.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(MokoTheme.limeSelected, in: Capsule())

            Text(achievement.detail)
                .font(.system(size: 17))
                .foregroundStyle(MokoTheme.bodyBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background(MokoTheme.limeBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(MokoTheme.forestGreen)
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
