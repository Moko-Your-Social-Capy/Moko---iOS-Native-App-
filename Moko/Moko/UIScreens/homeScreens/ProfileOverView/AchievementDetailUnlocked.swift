//
//  AchievementDetailUnlocked.swift
//  Moko
//
//  The detail page for one badge. Earned badges pop in and can be
//  tilted with a finger; locked badges are shown still and smaller.
//

import SwiftUI

private typealias Theme = MokoScreenTheme

struct ProfileOverViewAchievementDetailUnlocked: View {
    let achievement: Achievement

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
                .mokoText(Theme.Typeface.profileName)
                .foregroundStyle(Theme.Colors.textTitle)
                .multilineTextAlignment(.center)

            Text(achievement.unlocked ? "Earned · \(achievement.tier.title)" : "Locked · \(achievement.tier.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(achievement.unlocked ? ProfilePalette.accent : ProfilePalette.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(ProfilePalette.grouped, in: Capsule())

            Text(achievement.detail)
                .mokoText(Theme.Typeface.body)
                .foregroundStyle(Theme.Colors.textBody)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background(MokoBackdrop())
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The earned badge: it grows in once, and you can drag sideways to tilt it.
private struct BadgeUnlockAnimation: View {
    let achievement: Achievement

    // The phone setting "Reduce Motion". If it is on, no grow and no tilt.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // False at the start, true once the badge has popped in.
    @State private var appeared = false

    // How far the badge is turned, in degrees. Follows the finger while dragging.
    @State private var tilt = 0.0

    /// The badge never turns more than this, so it can't flip over.
    private let maxTilt = 25.0

    var body: some View {
        AchievementBadgeView(achievement: achievement, size: 244)
            // Starts slightly smaller (never from zero) and grows to full size.
            .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
            // rotation3DEffect turns the badge like a coin spinning on a table.
            .rotation3DEffect(.degrees(reduceMotion ? 0 : tilt), axis: (x: 0, y: 1, z: 0))
            .gesture(tiltGesture)
            // A little "success" buzz when the badge appears.
            .sensoryFeedback(.success, trigger: appeared)
            // .onAppear runs when the badge first shows. It starts the pop-in.
            .onAppear {
                withAnimation(reduceMotion ? Theme.Motion.crossfade : Theme.Motion.mascotEntrance) {
                    appeared = true
                }
            }
    }

    /// Drag left or right to tilt. Let go and it springs back flat.
    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !reduceMotion else { return }
                tilt = min(maxTilt, max(-maxTilt, value.translation.width / 4))
            }
            .onEnded { _ in
                withAnimation(Theme.Motion.snapBack) { tilt = 0 }
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
                leafSymbol: "leaf.fill",
                shape: .streak,
                tier: .two,
                unlocked: true
            )
        )
    }
}
