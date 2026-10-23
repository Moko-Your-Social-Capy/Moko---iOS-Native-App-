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
                        onStart: { hasCompletedOnboarding = true }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }
}

#Preview {
    OnboardingFlow()
}
