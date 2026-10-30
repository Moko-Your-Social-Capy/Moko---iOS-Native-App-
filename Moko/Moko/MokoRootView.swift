
//
//  MokoRootView.swift
//  Moko
//
//  App root using native SwiftUI TabView.
//

import SwiftUI
import SwiftData

struct MokoRootView: View {

    @State private var tab: MokoTab = .overview

    private let forestGreen = Color(
        red: 27.0 / 255.0,
        green: 66.0 / 255.0,
        blue: 47.0 / 255.0
    )

    var body: some View {

        TabView(selection: $tab) {

            // MARK: Overview

            Tab(
                "Overview",
                systemImage: "square.grid.2x2.fill",
                value: MokoTab.overview
            ) {
                Overview(selectedTab: $tab)
            }

            // MARK: Quests

            Tab(
                "Quests",
                systemImage: "clipboard.fill",
                value: MokoTab.quests
            ) {
                QuestsScreen()
            }

            // MARK: Relax

            Tab(
                "Relax",
                systemImage: "figure.mind.and.body",
                value: MokoTab.relax
            ) {
                RelaxScreen()
            }

            // MARK: Search

            Tab(
                "Search",
                systemImage: "magnifyingglass",
                value: MokoTab.search,
                role: .search
            ) {
                QuestLibraryView()
            }
        }
        .tint(forestGreen)
    }
}

// MARK: Preview

#Preview {
    MokoRootView()
        .modelContainer(
            for: [
                Quest.self,
                InsightsModel.self,
                CalmDownModel.self,
                Profile.self
            ],
            inMemory: true
        )
}
