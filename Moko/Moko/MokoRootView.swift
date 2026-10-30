
import SwiftUI

struct MokoRootView: View {

    @State private var selectedTab: MokoTab = .overview

    var body: some View {

        TabView(selection: $selectedTab) {

            // MARK: - Overview

            Tab(
                "Overview",
                systemImage: "square.grid.2x2.fill",
                value: .overview
            ) {
                Overview(selectedTab: $selectedTab)
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
    }
}
