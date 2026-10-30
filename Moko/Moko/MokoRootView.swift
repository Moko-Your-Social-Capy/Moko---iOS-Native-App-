
import SwiftUI
import SwiftData

struct MokoRootView: View {

    @Query(sort: \Quest.date, order: .reverse) private var quests: [Quest]

    @State private var selectedTab: MokoTab = .overview
    @State private var overviewMode: OverviewMode = .todo
    @State private var debriefQuest: Quest?

    var body: some View {

        TabView(selection: $selectedTab) {

            // MARK: - Overview

            Tab(
                "Overview",
                systemImage: "square.grid.2x2.fill",
                value: .overview
            ) {
                overviewContent
            }

            // MARK: - Quests

            Tab(
                "Quests",
                systemImage: "clipboard.fill",
                value: .quests
            ) {
                QuestsScreen()
            }

            // MARK: - Relax

            Tab(
                "Relax",
                systemImage: "figure.mind.and.body",
                value: .relax
            ) {
                RelaxScreen()
            }

            // MARK: - Explore

            Tab(
                "Explore",
                systemImage: "magnifyingglass",
                value: .search,
                role: .search
            ) {
                QuestLibraryView()
            }
        }

        // Native iOS tab bar minimization
        .tabBarMinimizeBehavior(.onScrollDown)

        // MOKO Forest Green
        .tint(
            Color(
                red: 27.0 / 255.0,
                green: 66.0 / 255.0,
                blue: 47.0 / 255.0
            )
        )

        // Lets the quest debrief send the user back to a specific Overview state
        .environment(\.openOverview) { mode in
            selectedTab = .overview
            overviewMode = mode
        }
        .fullScreenCover(item: $debriefQuest) { quest in
            QuestDebriefScreen(quest: quest) { outcome in
                handleDebriefOutcome(outcome, for: quest)
            }
        }
        .onChange(of: quests.count) { oldCount, newCount in
            // A new quest resets the Overview back to today's mission
            if newCount > oldCount {
                overviewMode = .todo
            }
        }
        .onAppear {
            // Pick up a debrief that was left unfinished in an earlier session
            guard let id = PendingDebriefStore.questID else { return }
            if quests.contains(where: { $0.id == id }) {
                overviewMode = .resume
            } else {
                PendingDebriefStore.clear()
            }
        }
    }

    // MARK: - Overview versions

    @ViewBuilder
    private var overviewContent: some View {
        switch overviewMode {
        case .todo:
            Overview(selectedTab: $selectedTab)
        case .resume:
            OverviewResumeScreen(
                onSlideResume: presentPendingDebrief,
                onStartDebrief: presentPendingDebrief
            )
        case .debriefDone:
            OverviewDebriefDone()
        }
    }

    /// Reopens the debrief for the quest that was left unfinished.
    private func presentPendingDebrief() {
        guard let id = PendingDebriefStore.questID,
              let quest = quests.first(where: { $0.id == id }) else { return }
        debriefQuest = quest
    }

    /// A debrief opened from the Overview tab sends the user to the matching version.
    private func handleDebriefOutcome(_ outcome: DebriefOutcome, for quest: Quest) {
        switch outcome {
        case .completed:
            PendingDebriefStore.clear()
            overviewMode = .debriefDone
        case .finishLater:
            PendingDebriefStore.save(quest)
            overviewMode = .resume
        case .leave:
            PendingDebriefStore.clear()
            overviewMode = .todo
        }
        debriefQuest = nil
    }
}

// MARK: - Preview

#Preview {
    MokoRootView()
        .modelContainer(
            for: [
                OnboardingState.self,
                OnboardingQuestion.self,
                OnboardingResponse.self,
                Profile.self,
                CalmDownModel.self,
                Quest.self,
                InsightsModel.self
            ],
            inMemory: true
        )
}
