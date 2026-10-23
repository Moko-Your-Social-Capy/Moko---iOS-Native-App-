import SwiftUI

@main
struct OnboardingApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingFlow()
            }
        }
    }
}

// Placeholder: replace with your real home screen
struct HomeView: View {
    @AppStorage("userName") private var userName = ""

    var body: some View {
        Text("Welcome, \(userName)!")
            .font(.title)
    }
}
