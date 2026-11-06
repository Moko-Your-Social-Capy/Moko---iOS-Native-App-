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
        case sudsCheckIn
        case done
        case reflection
        case microphonePreprompt
        case accountDeleted
        case home
    }

    @State private var currentScreen: AppScreen = .splash
    @State private var signedInEmail: String = ""
    @AppStorage("userName") private var storedUserName: String = ""
    @AppStorage("moko.isSignedOut") private var isSignedOut = false

    // Stores answers from the onboarding questions
    @State private var answers: [Int: OnboardingAnswer] = [:]

    private let auth = AuthService()

    private var currentUserName: String {
        if let profileName = profiles.first?.username, !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let stored = storedUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty {
            return stored
        }
        return ""
    }

    private var isUserFullyRegistered: Bool {
        return !profiles.isEmpty && !onboardingResponses.isEmpty && (onboardingStates.first?.isCompleted == true)
    }

    /// Drives the auth screen as a pushed destination so it inherits the system back button.
    private var isShowingAuth: Binding<Bool> {
        Binding(
            get: { currentScreen == .auth },
            set: { isShown in
                if !isShown, currentScreen == .auth {
                    currentScreen = .intro
                }
            }
        )
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
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            checkInitialRegistrationAndNavigate()
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.04))
                    )
                )

            // MARK: Intro + Authentication

            case .intro, .auth:
                NavigationStack {
                    OnboardingIntroView(
                        onLetsBegin: { currentScreen = .auth }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(isPresented: isShowingAuth) {
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
                                    } else {
                                        completeAuthentication(email: "Google User")
                                    }
                                }
                            }
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.visible, for: .navigationBar)
                        .toolbarBackground(.hidden, for: .navigationBar)
                    }
                }
                .tint(MokoTheme.forestGreen)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
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

                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentScreen = .sudsCheckIn
                            }
                        }
                    )
                }
                .transition(.opacity)

            case .sudsCheckIn:
                MokoSUDSCheckInView { score in
                    if let score {
                        MokoSUDSStore.save(score)
                    } else {
                        MokoSUDSStore.clear()
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .done
                    }
                }
                .transition(.opacity)

            // MARK: Onboarding Done

            case .done:
                OnboardingDoneView(completed: answers.count) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .reflection
                    }
                }
                .transition(.opacity)

            // MARK: Reflection

            case .reflection:
                ReflectionView(userName: currentUserName) {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                        currentScreen = .microphonePreprompt
                    }
                }
                .transition(.opacity)

            case .microphonePreprompt:
                MicrophonePermissionView {
                    withAnimation(.easeInOut(duration: 0.2)) { currentScreen = .home }
                }
                .transition(.opacity)

            case .accountDeleted:
                AccountDeletedConfirmation {
                    withAnimation(.easeInOut(duration: 0.2)) { currentScreen = .intro }
                }
                .transition(.opacity)

            // MARK: Home

            case .home:
                MokoRootView()
                    .environment(\.endSession) { reason in
                        finishSession(reason)
                    }
                    .transition(.opacity)
            }
        }
        .foregroundStyle(MokoTheme.titleBrown)
        .onOpenURL(perform: handleLiveActivityURL)
    }

    // MARK: - Navigation & Registration Logic

    private func checkInitialRegistrationAndNavigate() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            if !isSignedOut && isUserFullyRegistered {
                currentScreen = .home
            } else {
                currentScreen = .intro
            }
        }
    }

    private func handleLiveActivityURL(_ url: URL) {
        guard url.scheme == "moko" else { return }
        switch url.host {
        case "calm":
            if url.path == "/end" {
                Task { await MokoLiveActivityManager.endCalmSession(completed: false) }
            }
            currentScreen = .home
        case "quest":
            currentScreen = .home
            guard url.path == "/done",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  let id = UUID(uuidString: idString),
                  let quest = (try? modelContext.fetch(FetchDescriptor<Quest>()))?.first(where: { $0.id == id }) else { return }
            QuestProgress.complete(quest, in: modelContext)
        case "overview":
            currentScreen = .home
        default:
            break
        }
    }

    private func completeAuthentication(email: String) {
        signedInEmail = email
        isSignedOut = false

        // Re-authenticating on a device with local registration resumes at home;
        // otherwise the user starts (or resumes) onboarding.
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = isUserFullyRegistered ? .home : .onboardingInfo
        }
    }

    /// Clears in-memory session state and returns to the signed-out flow.
    private func finishSession(_ reason: SessionEndReason) {
        PendingDebriefStore.clear()
        signedInEmail = ""
        answers = [:]
        isSignedOut = true

        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            currentScreen = reason == .deleteAccount ? .accountDeleted : .intro
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
                    NameEntryView { name in
                        userName = name
                        path.append(.ageEntry)
                    }
                    .onboardingNavigationBar()

                case .ageEntry:
                    AgeEntryView(
                        initialAge: userAge,
                        onContinue: { age in
                            userAge = age
                            path.append(.welcome)
                        }
                    )
                    .onboardingNavigationBar()

                case .welcome:
                    WelcomeView(
                        name: userName,
                        onStart: {
                            onComplete(userName, userAge)
                        }
                    )
                    .onboardingNavigationBar()
                }
            }
        }
        .tint(MokoTheme.forestGreen)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [OnboardingState.self, OnboardingQuestion.self, OnboardingResponse.self, Profile.self], inMemory: true)
}
