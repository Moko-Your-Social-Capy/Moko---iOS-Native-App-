
import SwiftUI
import SwiftData

struct MokoRootView: View {

    @Environment(\.modelContext) private var modelContext
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
                systemImage: "list.bullet.clipboard",
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
        // iOS 27 otherwise keeps the .search tab glued to the other tabs.
        // This restores the default 3-tabs + detached search button.
        .tabViewSearchActivation(.searchTabSelection)
        .foregroundStyle(MocoScreenTheme.Colors.textTitle)

        // MOKO Forest Green
        .tint(MocoScreenTheme.Colors.tabActiveGlyph)

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
        .onChange(of: customQuestCount) { oldCount, newCount in
            // A new custom quest resets the Overview back to today's mission.
            // Library scenarios are started from Explore and must not affect it.
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
        .task {
            // Pre-populate today's daily mission via AFM or Mission Bank
            await DailyMissionService.ensureDailyMission(in: modelContext, existingQuests: quests)
        }
    }

    // MARK: - Overview versions

    @ViewBuilder
    private var overviewContent: some View {
        switch overviewMode {
        case .todo:
            Overview(
                selectedTab: $selectedTab,
                mission: todaysMission,
                onStartDebrief: { quest in
                    if quest.modelContext == nil {
                        modelContext.insert(quest)
                        try? modelContext.save()
                    }
                    debriefQuest = quest
                }
            )
        case .resume:
            OverviewResumeScreen(
                quest: pendingDebriefQuest,
                onSlideResume: presentPendingDebrief,
                onStartDebrief: presentPendingDebrief
            )
        case .debriefDone:
            OverviewDebriefDone()
        }
    }

    /// Custom quests only. Library scenarios live in Explore and never enter
    /// the Quests tab or the Overview mission.
    private var customQuestCount: Int {
        quests.filter { !$0.isFromLibrary }.count
    }

    /// The quest Overview shows as today's mission. Always guarantees a fresh daily mission.
    private var todaysMission: Quest? {
        if let mission = Quest.overviewMission(from: quests) {
            return mission
        }
        if let todayQuest = quests.first(where: { Calendar.current.isDateInToday($0.date) && !$0.isFromLibrary }) {
            return todayQuest
        }
        return DailyMissionService.todayFallbackQuest(existingQuests: quests)
    }

    /// The quest whose debrief was saved for later.
    private var pendingDebriefQuest: Quest? {
        guard let id = PendingDebriefStore.questID else { return nil }
        return quests.first(where: { $0.id == id })
    }

    /// Reopens the debrief for the quest that was left unfinished.
    private func presentPendingDebrief() {
        guard let quest = pendingDebriefQuest else { return }
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
