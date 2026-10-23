import SwiftUI
import SwiftData
import Auth

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var onboardingStates: [OnboardingState]

    // MARK: - App Flow

    private enum AppScreen: Equatable {
        case splash
        case intro
        case auth
        case onboarding
        case done
        case reflection
        case home(userEmail: String)
    }

    @State private var currentScreen: AppScreen = .splash
    @State private var signedInEmail: String = ""

    // Stores answers from the onboarding questions
    @State private var answers: [Int: OnboardingAnswer] = [:]

    private let auth = AuthService()

    // MARK: - Body

    var body: some View {
        ZStack {
            // Theme background prevents screen flashes during transitions
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
                            currentScreen = .intro
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

            // MARK: Onboarding Questions

            case .onboarding:
                NavigationStack {
                    OnboardingFlowView(
                        onFinish: { result in
                            answers = result

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
                            userEmail: signedInEmail
                        )
                    }
                }
                .transition(.opacity)

            // MARK: Home

            case .home(let email):
                VStack(spacing: 24) {
                    Spacer()

                    Image("moko_splash_icon_raw")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: 120,
                            height: 120
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 28,
                                style: .continuous
                            )
                        )
                        .shadow(
                            color: MokoTheme.primaryText
                                .opacity(0.08),
                            radius: 16,
                            x: 0,
                            y: 8
                        )

                    Text("Welcome to Moko!")
                        .font(
                            .system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundColor(
                            MokoTheme.textPrimary
                        )

                    Text("Signed in as \(email)")
                        .font(
                            .system(
                                size: 16,
                                weight: .medium,
                                design: .rounded
                            )
                        )
                        .foregroundColor(
                            MokoTheme.textSecondary
                        )

                    Spacer()

                    // Sign Out Button
                    Button(action: {
                        Task {
                            try? await auth.signOut()

                            withAnimation(
                                .spring(
                                    response: 0.5,
                                    dampingFraction: 0.8
                                )
                            ) {
                                currentScreen = .auth
                            }
                        }
                    }) {
                        Text("Sign Out")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(
                                MokoTheme.white
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Capsule()
                                    .fill(
                                        MokoTheme.forestGreen
                                    )
                            )
                    }
                    .padding(.horizontal, 32)

                    // Replay Start Screens Button
                    Button(action: {
                        MokoTheme.playFeedback(.light)

                        withAnimation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.8
                            )
                        ) {
                            currentScreen = .splash
                        }
                    }) {
                        Text("Replay Onboarding")
                            .font(
                                .system(
                                    size: 15,
                                    weight: .medium,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(
                                MokoTheme.textSecondary
                            )
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .transition(
                    .opacity
                        .combined(
                            with: .scale(scale: 0.96)
                        )
                )
            }
        }
    }

    // MARK: - Authentication Completion

    private func completeAuthentication(email: String) {
        signedInEmail = email

        // Update SwiftData onboarding state
        if let state = onboardingStates.first {
            state.isCompleted = true
            state.updatedAt = .now
        } else {
            let newState = OnboardingState(
                isCompleted: true
            )
            modelContext.insert(newState)
        }

        // After authentication, start the questionnaire.
        withAnimation(
            .spring(
                response: 0.55,
                dampingFraction: 0.8
            )
        ) {
            currentScreen = .onboarding
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(
            for: [
                OnboardingState.self,
                OnboardingQuestion.self,
                OnboardingResponse.self,
                Profile.self
            ],
            inMemory: true
        )
}
