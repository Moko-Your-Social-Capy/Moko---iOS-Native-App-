//
//  MokoRootView.swift
//  Moko
//
//  App root using native iOS TabView.
//

import SwiftUI
import SwiftData

struct MokoRootView: View {
    @State private var tab: MokoTab = .overview
    var useInMemoryStore = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                Overview(selectedTab: $tab)
            }
            .tabItem {
                Label("Overview", systemImage: "square.grid.2x2.fill")
            }
            .tag(MokoTab.overview)

            NavigationStack {
                QuestsScreen()
            }
            .tabItem {
                Label("Quests", systemImage: "list.clipboard")
            }
            .tag(MokoTab.quests)

            NavigationStack {
                RelaxScreen(selectedTab: $tab)
            }
            .tabItem {
                Label("Relax", systemImage: "figure.mind.and.body")
            }
            .tag(MokoTab.relax)

            NavigationStack {
                SearchView(selectedTab: $tab)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(MokoTab.search)
        }
        .accentColor(Color(red: 54/255, green: 89/255, blue: 72/255))
        .modelContainer(useInMemoryStore ? MokoDatabase.preview : MokoDatabase.shared)
    }
}

#Preview {
    MokoRootView(useInMemoryStore: true)
}
