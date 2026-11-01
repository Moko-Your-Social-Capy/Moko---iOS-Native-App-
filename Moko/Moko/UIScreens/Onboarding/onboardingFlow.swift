import SwiftUI

enum OnboardingStep: Hashable {
    case nameEntry
    case ageEntry
    case welcome
}

struct OnboardingFlow: View {
    @State private var path: [OnboardingStep] = []
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = 20
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationStack(path: $path) {
            // Cards screen
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
                        onStart: { hasCompletedOnboarding = true }
                    )
                    .onboardingNavigationBar()
                }
            }
        }
        .tint(MokoTheme.forestGreen)
    }
}

extension View {
    /// Shows the system navigation bar (and its default back button) while keeping
    /// the onboarding background visible.
    func onboardingNavigationBar() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingFlow()
}
