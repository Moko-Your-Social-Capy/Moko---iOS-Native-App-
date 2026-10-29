//
//  MokoRootView.swift
//  Moko
//
//  App root using the native TabView (Search tab is separated on iOS 26).
//

import SwiftUI
import SwiftData

struct MokoRootView: View {
    @State private var tab: MokoTab = .overview

    var body: some View {
        TabView(selection: $tab) {
            Tab("Overview", systemImage: "square.grid.2x2.fill", value: MokoTab.overview) {
                Overview(selectedTab: $tab)
            }

            Tab("Quests", systemImage: "clipboard.fill", value: MokoTab.quests) {
                QuestsScreen()
            }

            Tab("Relax", systemImage: "figure.mind.and.body", value: MokoTab.relax) {
                RelaxScreen(selectedTab: $tab)
            }

            Tab("Search", systemImage: "magnifyingglass", value: MokoTab.search, role: .search) {
                QuestLibraryView()
            }
        }
        .tint(Color(red: 27/255, green: 66/255, blue: 47/255)) // #1B422F
        // No .modelContainer here: the whole app uses the container from MokoApp,
        // which already has every model (Quest, InsightsModel, CalmDownModel, ...).
    }
}

#Preview {
    MokoRootView()
        .modelContainer(for: [Quest.self, InsightsModel.self, CalmDownModel.self], inMemory: true)
}
