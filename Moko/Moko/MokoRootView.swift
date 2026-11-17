//
//  MokoRootView.swift
//  Moko
//
//  The main app after onboarding: the four tabs (Overview, Quests, Relax, Explore)
//  and the full-screen quest debrief.
//
//  The Overview tab has three versions (`OverviewMode`):
//  - .todo        today's mission card
//  - .resume      "finish your debrief" (a debrief was saved for later)
//  - .debriefDone the celebration after a finished debrief
//

import SwiftUI
import SwiftData

struct MokoRootView: View {

    // SwiftData's "save box", passed to the daily mission service.
    @Environment(\.modelContext) private var modelContext
    // Every saved quest, newest first. Redraws when a quest is added or changed.
    @Query(sort: \Quest.date, order: .reverse) private var quests: [Quest]

    // Which tab is showing.
    @State private var selectedTab: MokoTab = .overview
    // Which version of the Overview tab is showing.
    @State private var overviewMode: OverviewMode = .todo
    // Setting this opens the debrief full screen; nil closes it.
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
        .foregroundStyle(MokoScreenTheme.Colors.textTitle)

        // Colour of the selected tab icon.
        .tint(MokoScreenTheme.Colors.tabActiveGlyph)

        // Lets the quest debrief send the user back to a specific Overview state
        .environment(\.openOverview) { mode in
            selectedTab = .overview
            overviewMode = mode
        }
        // Opens the debrief over everything whenever `debriefQuest` is set.
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
        // `.task` runs once when the tabs first appear.
        .task {
            // 1. Pick up a debrief that was left unfinished in an earlier session.
            if let id = PendingDebriefStore.questID {
                if quests.contains(where: { $0.id == id }) {
                    overviewMode = .resume
                } else {
                    PendingDebriefStore.clear()   // that quest no longer exists
                }
            } else if quests.contains(where: { Calendar.current.isDateInToday($0.date) && $0.isCompleted }) &&
                      !quests.contains(where: { Calendar.current.isDateInToday($0.date) && !$0.isCompleted }) {
                // If all of today's missions are completed, show the countdown to tomorrow's quest.
                overviewMode = .debriefDone
            }

            // 2. Create today's daily mission (Apple Intelligence or the Mission Bank).
            await DailyMissionService.ensureDailyMission(in: modelContext, existingQuests: quests)
        }
    }

    // MARK: - Overview versions

    @ViewBuilder
    private var overviewContent: some View {
        switch overviewMode {
        case .todo:
            Overview(
                mission: Quest.todaysMission(from: quests),
                // Overview has already saved the quest, so this only opens the debrief.
                onStartDebrief: { quest in
                    debriefQuest = quest
                }
            )
        case .resume:
            OverviewResumeScreen(
                quest: pendingDebriefQuest,
                onSlideResume: presentPendingDebrief
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
