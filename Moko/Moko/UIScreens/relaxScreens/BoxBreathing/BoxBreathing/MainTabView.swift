import SwiftUI

/// The app's main screen: the four tab screens plus the custom tab bar at the bottom.
struct MainTabView: View {
    @State private var selection: AppTab = .relax     // starts on Relax
    @State private var tabBarHidden = false

    var body: some View {
        ZStack {
            screen(.overview) { PlaceholderScreen(title: "Overview") }
            screen(.quests)   { PlaceholderScreen(title: "Quests") }
            screen(.relax) {
                RelaxView(
                    onExerciseChange: { isOpen in
                        withAnimation(.easeInOut(duration: 0.25)) { tabBarHidden = isOpen }
                    }
                )
            }
            screen(.search)   { PlaceholderScreen(title: "Search") }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabBarHidden {
                AppTabBar(selection: $selection)
                    .padding(.bottom, -10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .tint(BBColor.button)
    }

    /// Shows one tab's screen and keeps the others alive but invisible, so each tab keeps its state.
    private func screen<Content: View>(_ tab: AppTab,
                                       @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selection == tab ? 1 : 0)
            .allowsHitTesting(selection == tab)
            .accessibilityHidden(selection != tab)
    }
}

/// Stand-in for screens you have not designed yet.
private struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
                .navigationTitle(title)
        }
    }
}

// MARK: - Relax tab

/// Relax tab: Relax page -> Box Breathing info (modal sheet) -> exercise (pushed).
struct RelaxView: View {
    var onExerciseChange: (Bool) -> Void = { _ in }

    @State private var showInfo = false          // the modal info sheet
    @State private var showExercise = false      // the breathing exercise
    @State private var continuePressed = false

    var body: some View {
        NavigationStack {
            RelaxMainPage(onBoxBreathing: { showInfo = true })
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showExercise) {
                    BoxBreathingView(onComplete: { showExercise = false })     // back to Relax page
                }
        }
        .sheet(isPresented: $showInfo, onDismiss: {
            // Only open the exercise if the user actually pressed "Continue"
            if continuePressed {
                continuePressed = false
                showExercise = true
            }
        }) {
            BoxBreathingInfoView(
                onContinue: {
                    continuePressed = true
                    showInfo = false
                },
                onNotNow: { showInfo = false }
            )
            .presentationDetents([.fraction(0.928)])   // leaves a gap at the top, like the Figma
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(50)
            .presentationBackground(.white)
        }
        // Tells MainTabView when to hide / show the tab bar (hidden only during the exercise)
        .onChange(of: showExercise) { _, isOpen in
            onExerciseChange(isOpen)
        }
    }
}

#Preview {
    MainTabView()
}
