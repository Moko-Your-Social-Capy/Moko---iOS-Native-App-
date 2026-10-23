//
//  HomeScreenView.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//

import SwiftUI

struct HomeScreenView: View {
    var userEmail: String
    var onSignOut: () -> Void = {}
    var onReplayOnboarding: () -> Void = {}

    var body: some View {
        ZStack {
            MokoTheme.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Playful Mascot Icon
                Image("moko_splash_icon_raw")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: MokoTheme.primaryText.opacity(0.1), radius: 20, x: 0, y: 10)

                VStack(spacing: 8) {
                    Text("You're all set!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(MokoTheme.textPrimary)

                    Text("Welcome to your Moko home, \(userEmail).")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(MokoTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        MokoTheme.playFeedback(.medium)
                        onSignOut()
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(MokoTheme.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Capsule().fill(MokoTheme.forestGreen))
                    }

                    Button(action: {
                        MokoTheme.playFeedback(.light)
                        onReplayOnboarding()
                    }) {
                        Text("Replay Onboarding")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(MokoTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    HomeScreenView(userEmail: "hello@moko.app")
}
