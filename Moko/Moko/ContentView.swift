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

    // MARK: - App Flow

    private enum AppScreen: Equatable {
        case splash
        case intro
        case auth
        case onboardingInfo      // Carousel -> Name -> Age -> Welcome
        case onboardingQuestions // Swipeable Onboarding Questions
        case done
        case reflection
        case home(userEmail: String)
    }

    @State private var currentScreen: AppScreen = .splash
    @State private var signedInEmail: String = ""

    // Stores answers from the onboarding questions
    @State private var answers: [Int: OnboardingAnswer] = [:]

    private let auth = AuthService()

    private var isUserFullyRegistered: Bool {
        return !profiles.isEmpty && !onboardingResponses.isEmpty && (onboardingStates.first?.isCompleted == true)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MokoTheme.background
                .ignoresSafeArea()

            switch currentScreen {

            // MARK: Splash

            case .splash:
                SplashScreenView(
                    autoAdvance: true,
                    onFinished: {
                        withAnimation(
                            .spring(
                                response: 0.55,
                                dampingFraction: 0.82
                            )
                        ) {
                            checkInitialRegistrationAndNavigate()
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                            .combined(with: .scale(scale: 1.04))
                    )
                )

            // MARK: Intro

            case .intro:
                OnboardingIntroView(
                    onLetsBegin: {
                        withAnimation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.82
                            )
                        ) {
                            currentScreen = .auth
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing)
                            .combined(with: .opacity),
                        removal: .move(edge: .leading)
                            .combined(with: .opacity)
                    )
                )

            // MARK: Authentication

            case .auth:
                OnboardingAuthView(
                    onAuthenticated: { user in
                        completeAuthentication(
                            email: user.email ?? "User"
                        )
                    },

                    onContinueWithEmail: { email in
                        completeAuthentication(email: email)
                    },

                    onContinueWithApple: {
                        completeAuthentication(
                            email: "Apple User"
                        )
                    },

                    onContinueWithGoogle: {
                        Task {
                            if let user = try? await auth.getCurrentUser() {
                                completeAuthentication(
                                    email: user.email ?? "Google User"
                                )
                            } else {
                                completeAuthentication(
                                    email: "Google User"
                                )
                            }
                        }
                    },

                    onBack: {
                        withAnimation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.82
                            )
                        ) {
                            currentScreen = .intro
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing)
                            .combined(with: .opacity),
                        removal: .move(edge: .trailing)
                            .combined(with: .opacity)
                    )
                )

            // MARK: Onboarding Info Screens (Carousel -> Name -> Age -> Welcome)

            case .onboardingInfo:
                OnboardingFlowContainer(onComplete: { name, age in
                    finishOnboardingInfo(name: name, age: age)
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))

            // MARK: Onboarding Questions (Mapped to SwiftData OnboardingResponse & OnboardingQuestion)

            case .onboardingQuestions:
                NavigationStack {
                    OnboardingFlowView(
                        questions: OnboardingCardQuestion.all,
                        totalSteps: OnboardingCardQuestion.totalSteps,
                        onFinish: { result in
                            answers = result
                            mapAndSaveQuestionsToSwiftData(results: result)

                            withAnimation(
                                .easeInOut(duration: 0.3)
                            ) {
                                currentScreen = .done
                            }
                        }
                    )
                }
                .transition(.opacity)

            // MARK: Onboarding Done

            case .done:
                OnboardingDoneView(
                    completed: answers.count
                ) {
                    withAnimation(
                        .easeInOut(duration: 0.3)
                    ) {
                        currentScreen = .reflection
                    }
                }
                .transition(.opacity)

            // MARK: Reflection

            case .reflection:
                ReflectionView {
                    withAnimation(
                        .spring(
                            response: 0.55,
                            dampingFraction: 0.8
                        )
                    ) {
                        currentScreen = .home(
                            userEmail: signedInEmail.isEmpty ? (profiles.first?.username ?? "User") : signedInEmail
                        )
                    }
                }
                .transition(.opacity)

            // MARK: Home

            case .home(let email):
                HomeScreenView(
                    userEmail: email,
                    onSignOut: {
                        Task {
                            try? await auth.signOut()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentScreen = .auth
                            }
                        }
                    },
                    onReplayOnboarding: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentScreen = .splash
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .onAppear {
            if isUserFullyRegistered {
                let email = profiles.first?.username.isEmpty == false ? profiles.first!.username : "User"
                currentScreen = .home(userEmail: email)
            }
        }
    }

    // MARK: - Navigation & Registration Logic

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

    private func completeAuthentication(email: String) {
        signedInEmail = email

        // After authentication, start onboarding info screens
        withAnimation(
            .spring(
                response: 0.55,
                dampingFraction: 0.8
            )
        ) {
            currentScreen = .onboardingInfo
        }
    }

    private func finishOnboardingInfo(name: String, age: Int) {
        let username = name.isEmpty ? (signedInEmail.isEmpty ? "Moko User" : signedInEmail) : name

        // Store Profile in SwiftData
        let newProfile = Profile(username: username, age: age)
        modelContext.insert(newProfile)

        // Store OnboardingState in SwiftData
        let newState = OnboardingState(currentStep: 1, isCompleted: false)
        modelContext.insert(newState)

        try? modelContext.save()

        // After finishing onboarding info screens, transition to onboarding questions flow
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = .onboardingQuestions
        }
    }

    private func mapAndSaveQuestionsToSwiftData(results: [Int: OnboardingAnswer]) {
        let userID = signedInEmail.isEmpty ? (profiles.first?.username ?? "User") : signedInEmail

        // Map and insert OnboardingQuestion and OnboardingResponse records into SwiftData
        for cardQ in OnboardingCardQuestion.all {
            let qModel = OnboardingQuestion(
                questionText: cardQ.text,
                options: ["Yes", "No"],
                isRequired: true
            )
            modelContext.insert(qModel)

            let answer = results[cardQ.id] ?? .no
            let responseStr = answer == .yes ? "Yes" : "No"

            let respModel = OnboardingResponse(
                userID: userID,
                questionID: "q_\(cardQ.id)",
                userResponse: responseStr
            )
            modelContext.insert(respModel)
        }

        // Update OnboardingState to completed
        if let state = onboardingStates.first {
            state.isCompleted = true
            state.currentStep = OnboardingCardQuestion.totalSteps
            state.updatedAt = .now
        } else {
            let newState = OnboardingState(currentStep: OnboardingCardQuestion.totalSteps, isCompleted: true)
            modelContext.insert(newState)
        }

        try? modelContext.save()
    }
}

// MARK: - OnboardingFlow Container helper (Carousel -> Name -> Age -> Welcome)

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
