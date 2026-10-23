//
//  ContentView.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//

import SwiftUI
import SwiftData
import Auth

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var onboardingStates: [OnboardingState]
    
    enum AppScreen: Equatable {
        case splash
        case intro
        case auth
        case home(userEmail: String)
    }
    
    @State private var currentScreen: AppScreen = .splash
    @State private var signedInEmail: String = ""
    
    private let auth = AuthService()
    
    var body: some View {
        ZStack {
            // Theme background prevents screen flashes during transitions
            MokoTheme.background
                .ignoresSafeArea()
            
            switch currentScreen {
            case .splash:
                SplashScreenView(autoAdvance: true, onFinished: {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                        currentScreen = .intro
                    }
                })
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 1.04))
                ))
                
            case .intro:
                OnboardingIntroView(onLetsBegin: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                        currentScreen = .auth
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .auth:
                OnboardingAuthView(
                    onAuthenticated: { user in
                        completeAuthentication(email: user.email ?? "User")
                    },
                    onContinueWithEmail: { email in
                        completeAuthentication(email: email)
                    },
                    onContinueWithApple: {
                        completeAuthentication(email: "Apple User")
                    },
                    onContinueWithGoogle: {
                        Task {
                            if let user = try? await auth.getCurrentUser() {
                                completeAuthentication(email: user.email ?? "Google User")
                            }
                        }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            currentScreen = .intro
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                
            case .home(let email):
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image("moko_splash_icon_raw")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: MokoTheme.primaryText.opacity(0.08), radius: 16, x: 0, y: 8)
                    
                    Text("Welcome to Moko!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MokoTheme.textPrimary)
                    
                    Text("Signed in as \(email)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(MokoTheme.textSecondary)
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(action: {
                        Task {
                            try? await auth.signOut()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentScreen = .auth
                            }
                        }
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MokoTheme.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Capsule()
                                    .fill(MokoTheme.forestGreen)
                            )
                    }
                    .padding(.horizontal, 32)
                    
                    // Replay Start Screens Button (convenient for testing & review)
                    Button(action: {
                        MokoTheme.playFeedback(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentScreen = .splash
                        }
                    }) {
                        Text("Replay Onboarding")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(MokoTheme.textSecondary)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }
    
    // MARK: - Authentication Completion Helper
    
    private func completeAuthentication(email: String) {
        signedInEmail = email
        
        // Update SwiftData onboarding state
        if let state = onboardingStates.first {
            state.isCompleted = true
            state.updatedAt = .now
        } else {
            let newState = OnboardingState(isCompleted: true)
            modelContext.insert(newState)
        }
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = .home(userEmail: email)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [OnboardingState.self, OnboardingQuestion.self, OnboardingResponse.self, Profile.self], inMemory: true)
}
