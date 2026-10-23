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
    @Query private var profiles: [Profile]
    @Query private var onboardingResponses: [OnboardingResponse]
    @Query private var onboardingQuestions: [OnboardingQuestion]
    
    enum AppScreen: Equatable {
        case splash
        case intro
        case auth
        case onboardingFlow
        case home(userEmail: String)
    }
    
    @State private var currentScreen: AppScreen = .splash
    @State private var signedInEmail: String = ""
    
    private let auth = AuthService()
    
    private var isUserFullyRegistered: Bool {
        return !profiles.isEmpty && !onboardingResponses.isEmpty && (onboardingStates.first?.isCompleted == true)
    }
    
    var body: some View {
        ZStack {
            MokoTheme.background
                .ignoresSafeArea()
            
            switch currentScreen {
            case .splash:
                SplashScreenView(autoAdvance: true, onFinished: {
                    checkInitialRegistrationAndNavigate()
                })
                .transition(.opacity)
                
            case .intro:
                OnboardingIntroView(onLetsBegin: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                        currentScreen = .auth
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
                
            case .auth:
                OnboardingAuthView(
                    onAuthenticated: { user in
                        handleAuthSuccess(email: user.email ?? "User")
                    },
                    onContinueWithEmail: { email in
                        handleAuthSuccess(email: email)
                    },
                    onContinueWithApple: {
                        handleAuthSuccess(email: "Apple User")
                    },
                    onContinueWithGoogle: {
                        Task {
                            if let user = try? await auth.getCurrentUser() {
                                handleAuthSuccess(email: user.email ?? "Google User")
                            } else {
                                handleAuthSuccess(email: "Google User")
                            }
                        }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            currentScreen = .intro
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                
            case .onboardingFlow:
                OnboardingFlowContainer(onComplete: { name, age in
                    finishOnboarding(name: name, age: age)
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
                
            case .home(let email):
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack(spacing: 16) {
                            Image("moko_splash_icon_raw")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: MokoTheme.primaryText.opacity(0.08), radius: 8, x: 0, y: 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome, \(email)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(MokoTheme.textPrimary)
                                Text("SwiftData Inspector & Home")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(MokoTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // SwiftData Tables Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SwiftData Database Records")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(MokoTheme.textPrimary)
                                .padding(.horizontal, 20)
                            
                            // 1. Profiles Table Card
                            SwiftDataTableCard(
                                title: "Profiles Table",
                                systemImage: "person.crop.circle.fill",
                                count: profiles.count
                            ) {
                                if profiles.isEmpty {
                                    Text("No profile records found.")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(MokoTheme.textSecondary)
                                        .padding(.vertical, 8)
                                } else {
                                    ForEach(profiles, id: \.id) { profile in
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text("Username:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(profile.username)
                                                    .foregroundColor(MokoTheme.forestGreen)
                                            }
                                            HStack {
                                                Text("Age:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text("\(profile.age)")
                                            }
                                            HStack {
                                                Text("Updated:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(profile.updatedAt.formatted(date: .abbreviated, time: .standard))
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        .font(.system(size: 14, design: .rounded))
                                        .padding(12)
                                        .background(Color.cardFill)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            
                            // 2. Onboarding Responses Table Card
                            SwiftDataTableCard(
                                title: "Onboarding Responses Table",
                                systemImage: "text.document.fill",
                                count: onboardingResponses.count
                            ) {
                                if onboardingResponses.isEmpty {
                                    Text("No onboarding responses recorded yet.")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(MokoTheme.textSecondary)
                                        .padding(.vertical, 8)
                                } else {
                                    ForEach(onboardingResponses, id: \.id) { resp in
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text("User ID:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(resp.userID)
                                                    .foregroundColor(MokoTheme.forestGreen)
                                            }
                                            HStack {
                                                Text("Question ID:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(resp.questionID)
                                            }
                                            HStack {
                                                Text("Response:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(resp.userResponse)
                                                    .multilineTextAlignment(.trailing)
                                            }
                                            HStack {
                                                Text("Updated:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(resp.updatedAt.formatted(date: .abbreviated, time: .standard))
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        .font(.system(size: 14, design: .rounded))
                                        .padding(12)
                                        .background(Color.cardFill)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            
                            // 3. Onboarding States Table Card
                            SwiftDataTableCard(
                                title: "Onboarding States Table",
                                systemImage: "checklist",
                                count: onboardingStates.count
                            ) {
                                if onboardingStates.isEmpty {
                                    Text("No onboarding state records found.")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(MokoTheme.textSecondary)
                                        .padding(.vertical, 8)
                                } else {
                                    ForEach(onboardingStates, id: \.id) { state in
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text("Is Completed:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(state.isCompleted ? "True" : "False")
                                                    .foregroundColor(state.isCompleted ? .green : .orange)
                                            }
                                            HStack {
                                                Text("Current Step:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text("\(state.currentStep)")
                                            }
                                            HStack {
                                                Text("Updated:")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Text(state.updatedAt.formatted(date: .abbreviated, time: .standard))
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        .font(.system(size: 14, design: .rounded))
                                        .padding(12)
                                        .background(Color.cardFill)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 24)
                        
                        // Actions
                        VStack(spacing: 12) {
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
                                    .background(Capsule().fill(MokoTheme.forestGreen))
                            }
                            
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .onAppear {
            if isUserFullyRegistered {
                let email = profiles.first?.username.isEmpty == false ? profiles.first!.username : "User"
                currentScreen = .home(userEmail: email)
            } else {
                currentScreen = .splash
            }
        }
    }
    
    // MARK: - Registration & Authentication Logic
    
    private func checkInitialRegistrationAndNavigate() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            if isUserFullyRegistered {
                let email = profiles.first?.username.isEmpty == false ? profiles.first!.username : "User"
                currentScreen = .home(userEmail: email)
            } else {
                currentScreen = .intro
            }
        }
    }
    
    private func handleAuthSuccess(email: String) {
        signedInEmail = email
        
        // By default after sign in, show the onboarding screens so user completes the onboarding flow
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = .onboardingFlow
        }
    }
    
    private func finishOnboarding(name: String, age: Int) {
        let username = name.isEmpty ? (signedInEmail.isEmpty ? "Moko User" : signedInEmail) : name
        
        // Properly store Profile in SwiftData
        let newProfile = Profile(username: username, age: age)
        modelContext.insert(newProfile)
        
        // Properly store OnboardingState in SwiftData
        let newState = OnboardingState(isCompleted: true)
        modelContext.insert(newState)
        
        // Properly store OnboardingResponse in SwiftData
        let response = OnboardingResponse(
            userID: signedInEmail.isEmpty ? username : signedInEmail,
            questionID: "onboarding_completed",
            userResponse: "Completed onboarding successfully. Name: \(username), Age: \(age)"
        )
        modelContext.insert(response)
        
        try? modelContext.save()
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = .home(userEmail: username)
        }
    }
}

// MARK: - SwiftData Table Card Helper

struct SwiftDataTableCard<Content: View>: View {
    let title: String
    let systemImage: String
    let count: Int
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundColor(MokoTheme.forestGreen)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(MokoTheme.textPrimary)
                Spacer()
                Text("\(count) items")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(MokoTheme.forestGreen.opacity(0.1))
                    .foregroundColor(MokoTheme.forestGreen)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            content
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cardStroke, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

// MARK: - OnboardingFlow Container helper

struct OnboardingFlowContainer: View {
    var onComplete: (String, Int) -> Void
    
    @State private var path: [OnboardingStep] = []
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = 20

    var body: some View {
        NavigationStack(path: $path) {
            FamiliarCarouselView(
                onContinue: { path.append(.nameEntry) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .nameEntry:
                    NameEntryView(
                        onBack: { path.removeLast() },
                        onContinue: { name in
                            userName = name
                            path.append(.ageEntry)
                        }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .ageEntry:
                    AgeEntryView(
                        initialAge: userAge,
                        onBack: { path.removeLast() },
                        onContinue: { age in
                            userAge = age
                            path.append(.welcome)
                        }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .welcome:
                    WelcomeView(
                        name: userName,
                        onBack: { path.removeLast() },
                        onStart: {
                            onComplete(userName, userAge)
                        }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [OnboardingState.self, OnboardingQuestion.self, OnboardingResponse.self, Profile.self], inMemory: true)
}
