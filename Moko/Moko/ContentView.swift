//
//  ContentView.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var onboardingStates: [OnboardingState]
    
    enum AppScreen: Equatable {
        case splash
        case intro
        case auth
        case home(userIdentifier: String)
    }
    
    @State private var currentScreen: AppScreen = .auth
    @State private var signedInUser: String = ""
    
    var body: some View {
        ZStack {
            // Background to prevent white flash during screen transitions
            MokoTheme.background
                .ignoresSafeArea()
            
            switch currentScreen {
            case .splash:
                SplashScreenView(autoAdvance: false, onFinished: {
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
                    onContinueWithEmail: { email in
                        completeOnboarding(identifier: email)
                    },
                    onContinueWithApple: {
                        completeOnboarding(identifier: "Apple ID User")
                    },
                    onContinueWithGoogle: {
                        completeOnboarding(identifier: "Google User")
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
                
            case .home(let user):
                // Home / Connected Welcome Screen
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image("moko_splash_icon_raw")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                    
                    Text("Welcome to Moko!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MokoTheme.textPrimary)
                    
                    Text("Connected as \(user)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(MokoTheme.textSecondary)
                    
                    Spacer()
                    
                    // Button to replay start screens (helpful for presentation and testing)
                    Button(action: {
                        MokoTheme.playFeedback(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentScreen = .splash
                        }
                    }) {
                        Text("Replay Onboarding")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MokoTheme.forestGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Capsule()
                                    .stroke(MokoTheme.forestGreen, lineWidth: 1.5)
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Onboarding Completion Helper
    private func completeOnboarding(identifier: String) {
        signedInUser = identifier
        
        // Update SwiftData state if present, or create new state
        if let state = onboardingStates.first {
            state.isCompleted = true
            state.updatedAt = .now
        } else {
            let newState = OnboardingState(isCompleted: true)
            modelContext.insert(newState)
        }
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = .home(userIdentifier: identifier)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [OnboardingState.self, OnboardingQuestion.self, OnboardingResponse.self, Profile.self], inMemory: true)
}
