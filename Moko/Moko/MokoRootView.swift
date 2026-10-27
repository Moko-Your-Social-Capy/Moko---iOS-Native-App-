//
//  MokoRootView.swift
//  Moko
//
//  App root using the native TabView.
//

import SwiftUI
import SwiftData

struct MokoRootView: View {
    @State private var tab: MokoTab = .overview
    var useInMemoryStore = false

    var body: some View {
        TabView(selection: $tab) {
            Overview(selectedTab: $tab)
                .tabItem { Label("Overview", systemImage: "square.grid.2x2.fill") }
                .tag(MokoTab.overview)

            QuestsScreen()
                .tabItem { Label("Quests", systemImage: "clipboard.fill") }
                .tag(MokoTab.quests)

            RelaxScreen(selectedTab: $tab)
                .tabItem { Label("Relax", systemImage: "figure.mind.and.body") }
                .tag(MokoTab.relax)

            SearchView(selectedTab: $tab)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(MokoTab.search)
        }
        .tint(Color(red: 27/255, green: 66/255, blue: 47/255)) // #1B422F
        .modelContainer(useInMemoryStore ? MokoDatabase.preview : MokoDatabase.shared)
    }
}

#Preview {
    MokoRootView(useInMemoryStore: true)
}
