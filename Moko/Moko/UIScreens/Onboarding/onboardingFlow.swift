//
//  onboardingFlow.swift
//  Moko
//
//  The onboarding screens shown right after sign-in:
//
//      FamiliarIntroView (5 pages) → NameEntryView (name + age) → WelcomeView
//
//  Also holds the small pieces those screens share (progress bar, continue
//  button, nav-bar style) so each screen file only contains its own content.
//
//  Debug tip: if a screen does not push, check that its `onContinue` closure
//  appends the next `OnboardingStep` to `path`.
//

import SwiftUI
import SwiftData

// MARK: - Steps

/// One pushed screen in the intro flow. The first familiar page is the root, so it has no case.
enum OnboardingStep: Hashable {
    /// A familiar situation page, by its place in the list (1...4).
    case familiar(Int)
    case nameEntry
    case welcome
}

/// Hosts the intro screens in a NavigationStack and reports name + age when done.
struct OnboardingFlowContainer: View {
    /// Called with the name and age when the user taps Start on the welcome screen.
    var onComplete: (String, Int) -> Void

    /// The pushed screens. Appending a step pushes it; the Back button pops it.
    @State private var path: [OnboardingStep] = []

    // @AppStorage = a value saved in UserDefaults, so it survives app restarts.
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = 20

    // SwiftData is Apple’s storage. It saves the Profile on the phone.
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    var body: some View {
        NavigationStack(path: $path) {
            FamiliarIntroView(
                onAdvance: { advance(from: $0) },
                onSkip: { path.append(.nameEntry) }
            )
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

    /// The arrow pushes the next familiar page, or the name step after the last one.
    private func advance(from index: Int) {
        if index + 1 < FamiliarSituation.all.count {
            path.append(.familiar(index + 1))
        } else {
            path.append(.nameEntry)
        }
    }

    @ViewBuilder
    private func destination(for step: OnboardingStep) -> some View {
        switch step {
        case .familiar(let index):
            // Each page is pushed, so it gets the system back button and edge swipe.
            FamiliarScreen(
                situation: FamiliarSituation.all[index],
                step: index,
                total: FamiliarSituation.all.count,
                isLast: index == FamiliarSituation.all.count - 1,
                onAdvance: { advance(from: index) },
                onSkip: { path.append(.nameEntry) }
            )
                .onboardingNavigationBar()

        case .nameEntry:
            NameEntryView(initialName: userName, initialAge: userAge) { name, age in
                userName = name
                userAge = age

                // Keep one saved Profile, so onboarding edits the same model the Profile tab uses.
                if let profile = profiles.first {
                    profile.username = name
                    profile.age = age
                    profile.updatedAt = .now
                } else {
                    modelContext.insert(Profile(username: name, age: age))
                }
                modelContext.saveOrLog("onboarding name and age")

                path.append(.welcome)
            }
        case .welcome:
            WelcomeView(name: userName) {
                onComplete(userName, userAge)
            }
        }
    }
}

// MARK: - Shared screen scaffold

/// Rounded hero card used by both personalized onboarding screens.
struct OnboardingJourneyCard<Content: View>: View {
    @Environment(\.mokoTheme) private var theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Soft decorative glow behind the card content.
            Circle()
                .fill(theme.colors.inverseText.opacity(0.10))
                .frame(width: 220, height: 220)
                .offset(x: -110, y: -130)

            Circle()
                .fill(theme.colors.inverseText.opacity(0.08))
                .frame(width: 170, height: 170)
                .offset(x: 120, y: 150)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.colors.profileAccent, theme.colors.ctaAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.colors.inverseText.opacity(0.28), lineWidth: 2)
        }
        .shadow(color: theme.colors.cardShadow.opacity(0.18), radius: 18, y: 10)
    }
}

/// Small two-dot indicator shown below the card.
struct OnboardingJourneyDots: View {
    let currentPage: Int
    @Environment(\.mokoTheme) private var theme

    var body: some View {
        HStack(spacing: 7) {
            ForEach(1...2, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? theme.colors.ctaAccent : theme.colors.separator.opacity(0.7))
                    .frame(width: page == currentPage ? 8 : 6, height: page == currentPage ? 8 : 6)
            }
        }
        .accessibilityLabel("Step \(currentPage) of 2")
    }
}

/// Card, dots, primary CTA and quiet footer assembled in one shared layout.
struct OnboardingJourneyScaffold<Content: View>: View {
    let currentPage: Int
    let buttonTitle: String
    let footer: String
    var isEnabled = true
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.mokoTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                OnboardingJourneyCard(content: content)
                    .frame(minHeight: 500)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)

                OnboardingJourneyDots(currentPage: currentPage)
                    .padding(.top, 18)

                Button(action: action) {
                    Text(buttonTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.colors.primaryButtonText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(theme.colors.primaryButton, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1 : 0.45)
                .padding(.horizontal, 22)
                .padding(.top, 22)

                Text(footer)
                    .font(.caption)
                    .foregroundStyle(theme.colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        // A themed completion gradient keeps the screen consistent in Light and Dark mode.
        .background {
            LinearGradient(
                colors: [theme.colors.completionBackground, theme.colors.screenBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
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
