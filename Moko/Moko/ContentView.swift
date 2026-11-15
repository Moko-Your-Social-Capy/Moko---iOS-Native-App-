//
//  ContentView.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//
//  The app's "traffic controller". It shows exactly one screen at a time,
//  chosen by `currentScreen`:
//
//    splash → intro → auth → onboardingInfo (carousel, name, age, welcome)
//           → onboardingQuestions → done → reflection → microphonePreprompt → home
//
//  A returning, fully registered user goes straight from splash to home.
//  Signing out or deleting the account comes back here through `endSession`.
//
//  Debug tip: to see why a screen appears, put a breakpoint wherever
//  `currentScreen` is set.
//

import SwiftUI
import SwiftData
import Auth

struct ContentView: View {
    // SwiftData's "save box" for inserting and saving records.
    @Environment(\.modelContext) private var modelContext

    // True when the user turned on Reduce Motion in Settings.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // `@Query` reads saved records and redraws this view when they change.
    @Query private var onboardingStates: [OnboardingState]
    @Query private var profiles: [Profile]
    @Query private var onboardingResponses: [OnboardingResponse]

    // MARK: - App Flow

    private enum AppScreen: Equatable {
        case splash
        case intro
        case auth
        case onboardingInfo      // Carousel -> Name -> Age -> Welcome
        case onboardingQuestions // Swipeable onboarding questions
        case done
        case reflection
        case microphonePreprompt
        case accountDeleted
        case home
    }

    /// The screen on display. Change it inside `withAnimation` to animate the switch.
    @State private var currentScreen: AppScreen = .splash

    /// Email (or a label like "Apple User") from sign-in. Used as a fallback name and user ID.
    @State private var signedInEmail: String = ""

    // `@AppStorage` is a value saved in UserDefaults, so it survives app restarts.
    @AppStorage("userName") private var storedUserName: String = ""
    @AppStorage("moko.isSignedOut") private var isSignedOut = false

    /// Answers from the onboarding questions, keyed by question ID.
    @State private var answers: [Int: OnboardingAnswer] = [:]

    private let auth = AuthService()

    /// The profile name, else the name typed during onboarding, else "".
    private var currentUserName: String {
        let profileName = profiles.first?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !profileName.isEmpty {
            return profileName
        }
        return storedUserName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True once there is a profile, saved answers and a completed onboarding.
    private var isUserFullyRegistered: Bool {
        !profiles.isEmpty && !onboardingResponses.isEmpty && (onboardingStates.first?.isCompleted == true)
    }

    /// Drives the auth screen as a pushed destination so it inherits the system back button.
    /// Tapping Back sets this to false, which returns to the intro.
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
                SplashScreenView(onFinished: checkInitialRegistrationAndNavigate)
                    .transition(.opacity)

            // MARK: Intro + Authentication

            case .intro, .auth:
                NavigationStack {
                    OnboardingIntroView(
                        onLetsBegin: { currentScreen = .auth }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(isPresented: isShowingAuth) {
                        authScreen
                    }
                }
                .tint(MokoTheme.forestGreen)
                // Slide in from the right, out to the left (or just fade with Reduce Motion).
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            // MARK: Onboarding Info (Carousel -> Name -> Age -> Welcome)

            case .onboardingInfo:
                OnboardingFlowContainer(onComplete: { name, age in
                    finishOnboardingInfo(name: name, age: age)
                })
                .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))

            // MARK: Onboarding Questions

            case .onboardingQuestions:
                NavigationStack {
                    OnboardingFlowView(
                        questions: OnboardingCardQuestion.all,
                        totalSteps: OnboardingCardQuestion.totalSteps,
                        onFinish: { result in
                            answers = result
                            saveOnboardingAnswers(result)
                            show(.done)
                        }
                    )
                }
                .transition(.opacity)

            // MARK: Onboarding Done

            case .done:
                OnboardingDoneView(completed: answers.count) {
                    show(.reflection)
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

            // MARK: Microphone permission

            case .microphonePreprompt:
                MicrophonePermissionView {
                    show(.home, duration: 0.2)
                }
                .transition(.opacity)

            // MARK: Account deleted

            case .accountDeleted:
                AccountDeletedConfirmation {
                    show(.intro, duration: 0.2)
                }
                .transition(.opacity)

            // MARK: Home

            case .home:
                MokoRootView()
                    // Lets any screen inside Home sign out or delete the account.
                    .environment(\.endSession) { reason in
                        finishSession(reason)
                    }
                    .transition(.opacity)
            }
        }
        .foregroundStyle(MokoTheme.titleBrown)
    }

    /// The sign-in screen. Every sign-in button ends up in `completeAuthentication`.
    private var authScreen: some View {
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
                // Google sign-in has already finished; ask Supabase who signed in.
                Task {
                    let user = try? await auth.getCurrentUser()
                    completeAuthentication(email: user?.email ?? "Google User")
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Navigation

    /// Cross-fades to `screen`.
    private func show(_ screen: AppScreen, duration: Double = 0.3) {
        withAnimation(.easeInOut(duration: duration)) {
            currentScreen = screen
        }
    }

    /// After the splash: registered and signed in → home, otherwise → intro.
    private func checkInitialRegistrationAndNavigate() {
        withAnimation(MokoScreenTheme.Motion.crossfade) {
            currentScreen = (!isSignedOut && isUserFullyRegistered) ? .home : .intro
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

    // MARK: - Saving onboarding

    /// Saves the name and age, then moves on to the questions.
    /// Reuses an existing profile (e.g. onboarding was restarted) instead of adding a second one.
    private func finishOnboardingInfo(name: String, age: Int) {
        let username = name.isEmpty ? (signedInEmail.isEmpty ? "Moko User" : signedInEmail) : name

        if let profile = profiles.first {
            profile.username = username
            profile.age = age
            profile.updatedAt = .now
        } else {
            modelContext.insert(Profile(username: username, age: age))
        }

        if onboardingStates.isEmpty {
            modelContext.insert(OnboardingState(currentStep: 1, isCompleted: false))
        }

        modelContext.saveOrLog("onboarding profile")

        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentScreen = .onboardingQuestions
        }
    }

    /// Saves every question and answer, the starting Insights scores, and marks onboarding complete.
    private func saveOnboardingAnswers(_ results: [Int: OnboardingAnswer]) {
        let userID = signedInEmail.isEmpty ? (profiles.first?.username ?? "User") : signedInEmail

        for cardQuestion in OnboardingCardQuestion.all {
            modelContext.insert(OnboardingQuestion(
                questionText: cardQuestion.text,
                options: ["Yes", "No"],
                isRequired: true
            ))

            // An unanswered question counts as "No".
            let answer = results[cardQuestion.id] ?? .no
            modelContext.insert(OnboardingResponse(
                userID: userID,
                questionID: "q_\(cardQuestion.id)",
                userResponse: answer == .yes ? "Yes" : "No"
            ))
        }

        // The first Insights record: plain-Swift scores from the answers (see OnboardingScoring).
        let baselineScores = OnboardingScoring.scores(from: results)
        modelContext.insert(baselineScores.makeInsightsModel(date: .now))

        if let state = onboardingStates.first {
            state.isCompleted = true
            state.currentStep = OnboardingCardQuestion.totalSteps
            state.updatedAt = .now
        } else {
            modelContext.insert(OnboardingState(currentStep: OnboardingCardQuestion.totalSteps, isCompleted: true))
        }

        modelContext.saveOrLog("onboarding answers")
    }
}

// OnboardingFlowContainer (Carousel → Name → Age → Welcome) lives in
// UIScreens/Onboarding/onboardingFlow.swift.

#Preview {
    ContentView()
        .modelContainer(
            for: [OnboardingState.self, OnboardingQuestion.self, OnboardingResponse.self,
                  Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}

