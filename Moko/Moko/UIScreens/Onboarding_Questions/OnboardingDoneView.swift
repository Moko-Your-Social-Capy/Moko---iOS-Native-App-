//
//  OnboardingDoneView.swift
//  Moko
//
//  The "You rock!!!" celebration after the last swipe question.
//  The illustrated valley is the whole backdrop; text sits in the pale sky
//  at the top and the button rests at the bottom, so the art stays visible.
//  Then the user moves on to ReflectionView.
//

import SwiftUI

struct OnboardingDoneView: View {
    var completed: Int
    var total: Int
    /// Called when the user taps "Continue to your strengths".
    var onContinue: () -> Void

    init(
        completed: Int = OnboardingCardQuestion.totalSteps,
        total: Int = OnboardingCardQuestion.totalSteps,
        onContinue: @escaping () -> Void = {}
    ) {
        self.completed = completed
        self.total = total
        self.onContinue = onContinue
    }

    // Colours picked to stay readable on the pale mint sky.
    private let ink = Color(hex: 0x1C3A33)
    private let cardFill = Color(hex: 0xFBF8EF).opacity(0.95)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The tick animation celebrates the completed onboarding.
            MokoTickCompleteView(size: 180)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

            // Headline and short summary share the left edge with the cards below.
            Text("You rock!!!")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .tracking(-1)
                .foregroundStyle(ink)

            Text("All \(total) cards complete.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink.opacity(0.72))
                .padding(.top, 6)

            // Four short result cards, in the same order as the next screens.
            VStack(spacing: 12) {
                OnboardingStatusRow(
                    icon: "checkmark",
                    iconBackground: RColor.mint,
                    title: "\(completed) of \(total) reflections completed",
                    status: "100%",
                    statusColor: RColor.green,
                    fill: cardFill,
                    stroke: ink
                )
                OnboardingStatusRow(
                    icon: "list.clipboard",
                    iconBackground: RColor.peach,
                    title: "Baseline calculated",
                    status: "READY",
                    statusColor: RColor.body,
                    fill: cardFill,
                    stroke: ink
                )
                OnboardingStatusRow(
                    icon: "sparkles",
                    iconBackground: RColor.lilac,
                    title: "Your strengths mapped",
                    status: "3 FOUND",
                    statusColor: RColor.green,
                    fill: cardFill,
                    stroke: ink
                )
                OnboardingStatusRow(
                    icon: "flag.fill",
                    iconBackground: RColor.sky,
                    title: "First quest unlocked",
                    status: "OPEN",
                    statusColor: RColor.green,
                    fill: cardFill,
                    stroke: ink
                )
            }
            .padding(.top, 20)

            // Empty middle lets the valley and Moko mascot show through.
            Spacer(minLength: 24)

            PillButton(title: "Continue to your strengths", action: onContinue)
                // A soft shadow lifts the button off the water.
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
        // The artwork is light, so keep status bar text dark even in dark mode.
        .preferredColorScheme(.light)
        // Background artwork is a separate layer, so it never pushes the text around.
        .background {
            ZStack {
                // The full colour illustration fills the whole screen.
                Image("onboarding_complete_bg")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.85)
                    .accessibilityHidden(true)

            // A soft cream wash at the very top keeps the title crisp.
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0xF4F1E4).opacity(0.55), location: 0),
                    .init(color: Color(hex: 0xF4F1E4).opacity(0.15), location: 0.28),
                    .init(color: .clear, location: 0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Status row

/// Icon in a colored circle, a title, and a short status on the right ("100%", "READY").
private struct OnboardingStatusRow: View {
    /// SF Symbol name.
    let icon: String
    let iconBackground: Color
    let title: String
    let status: String
    let statusColor: Color
    let fill: Color
    let stroke: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconBackground)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MokoTheme.titleBrown)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)                // shrink slightly rather than cut off

            Spacer(minLength: 8)

            Text(status)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)
                .overlay(
                    // A faint outline separates the card from the pale sky.
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(stroke.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.10), radius: 10, y: 4)
        // VoiceOver reads the row as one item: "Baseline calculated, READY".
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingDoneView()
}
