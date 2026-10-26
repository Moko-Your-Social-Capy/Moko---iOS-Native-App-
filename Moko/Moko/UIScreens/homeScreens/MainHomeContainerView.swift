//
//  MainHomeContainerView.swift
//  Moko
//
//  Canonical tab navigation using native iOS TabView and .tabItem.
//

import SwiftUI

struct MainHomeContainerView: View {
    @State private var selectedTab: MokoTab = .overview
    var userEmail: String

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                Overview(selectedTab: $selectedTab)
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
                RelaxScreen(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Relax", systemImage: "figure.mind.and.body")
            }
            .tag(MokoTab.relax)

            NavigationStack {
                SearchView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(MokoTab.search)
        }
        .accentColor(Color(red: 54/255, green: 89/255, blue: 72/255))
    }
}

#Preview {
    MainHomeContainerView(userEmail: "test@user.com")
}
