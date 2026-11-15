//
//  onboardingFlow.swift
//  Moko
//
//  The four intro screens shown right after sign-in:
//
//      FamiliarCarouselView → NameEntryView → AgeEntryView → WelcomeView
//
//  Also holds the small pieces those screens share (progress bar, continue
//  button, nav-bar style) so each screen file only contains its own content.
//
//  Debug tip: if a screen does not push, check that its `onContinue` closure
//  appends the next `OnboardingStep` to `path`.
//

import SwiftUI

// MARK: - Steps

/// One pushed screen in the intro flow. The carousel is the root, so it has no case.
enum OnboardingStep: Hashable {
    case nameEntry
    case ageEntry
    case welcome
}

// MARK: - Flow container

/// Hosts the intro screens in a NavigationStack and reports name + age when done.
struct OnboardingFlowContainer: View {
    /// Called with the name and age when the user taps Start on the welcome screen.
    var onComplete: (String, Int) -> Void

    /// The pushed screens. Appending a step pushes it; the Back button pops it.
    @State private var path: [OnboardingStep] = []

    // @AppStorage = a value saved in UserDefaults, so it survives app restarts.
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = 20

    var body: some View {
        NavigationStack(path: $path) {
            FamiliarCarouselView(onContinue: { path.append(.nameEntry) })
                // The first screen has no Back button, so hide the bar entirely.
                .toolbar(.hidden, for: .navigationBar)
                // Which view to show for each step pushed onto `path`.
                .navigationDestination(for: OnboardingStep.self) { step in
                    destination(for: step)
                        .onboardingNavigationBar()
                }
        }
        // Colors the system Back arrow.
        .tint(MokoTheme.forestGreen)
    }

    @ViewBuilder
    private func destination(for step: OnboardingStep) -> some View {
        switch step {
        case .nameEntry:
            NameEntryView { name in
                userName = name
                path.append(.ageEntry)
            }
        case .ageEntry:
            AgeEntryView(initialAge: userAge) { age in
                userAge = age
                path.append(.welcome)
            }
        case .welcome:
            WelcomeView(name: userName) {
                onComplete(userName, userAge)
            }
        }
    }
}

// MARK: - Shared progress bar

/// Thin bar at the top of each intro screen. `progress` goes from 0 (empty) to 1 (full).
struct OnboardingProgressBar: View {
    var progress: CGFloat

    var body: some View {
        // GeometryReader tells us how wide the bar is, so we can fill a fraction of it.
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.track)
                Capsule().fill(Color.forestLight)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 3)
        .accessibilityElement()
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Shared continue button

/// Full-width green pill button used at the bottom of every intro screen.
struct OnboardingContinueButton: View {
    var title: String = "Continue"
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.cream)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.forest, in: Capsule())
                // Dim the button while it can't be tapped.
                .opacity(isEnabled ? 1 : 0.4)
        }
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.15), value: isEnabled)
    }
}

// MARK: - Nav bar style

extension View {
    /// Shows the system navigation bar (and its default back button) while keeping
    /// the onboarding background visible behind it.
    func onboardingNavigationBar() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingFlowContainer(onComplete: { _, _ in })
}
