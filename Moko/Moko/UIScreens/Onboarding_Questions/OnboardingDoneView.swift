//
//  OnboardingDoneView.swift
//  Onboarding_Questions
//
//  Created by user@14 on 23/10/26.
//
import SwiftUI

struct OnboardingDoneView: View {
    var completed: Int
    var total: Int
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

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Image("capybara_celebrate")
                .resizable()
                .scaledToFit()
                .frame(width: 257, height: 257)
                .accessibilityHidden(true)

            Text("You rock!!!")
                .font(.system(size: 28, weight: .bold))
                .tracking(-1)
                .foregroundStyle(RColor.text)
                .padding(.top, 20)

            VStack(spacing: 30) {
                StatusRow(icon: "checkmark",
                          iconBackground: RColor.mint,
                          title: "\(completed) of \(total) reflections completed",
                          status: "100%",
                          statusColor: RColor.green)
                StatusRow(icon: "list.clipboard",
                          iconBackground: RColor.peach,
                          title: "Baseline calculated",
                          status: "READY",
                          statusColor: RColor.body)
            }
            .padding(.top, 55)
            .padding(.horizontal, 48)

            Spacer(minLength: 0)

            PillButton(title: "Continue to your strengths", action: onContinue)
                .padding(.horizontal, 48)
                .padding(.bottom, 55)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}

private struct StatusRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    let status: String
    let statusColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconBackground)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .frame(width: 32, height: 32)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            Text(status)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OBColor.cardFill)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

#Preview {
    OnboardingDoneView()
}
