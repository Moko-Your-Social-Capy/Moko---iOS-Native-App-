//
//  MainHomeContainerView.swift
//  Moko
//
//  Tab navigation using the native TabView (Search tab is separated on iOS 26).
//

import SwiftUI

struct MainHomeContainerView: View {
    @State private var selectedTab: MokoTab = .overview
    @State private var searchedTerm = ""
    var userEmail: String

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "square.grid.2x2.fill", value: MokoTab.overview) {
                Overview(selectedTab: $selectedTab)
            }

            Tab("Quests", systemImage: "clipboard.fill", value: MokoTab.quests) {
                QuestsScreen()
            }

            Tab("Relax", systemImage: "figure.mind.and.body", value: MokoTab.relax) {
                RelaxScreen(selectedTab: $selectedTab)
            }

            Tab("Search", systemImage: "magnifyingglass", value: MokoTab.search, role: .search) {
                NavigationStack {
                    SearchView(selectedTab: $selectedTab)
                        .searchable(text: $searchedTerm)
                }
            }
        }
        .tint(Color(red: 27/255, green: 66/255, blue: 47/255)) // #1B422F
    }
}

#Preview {
    MainHomeContainerView(userEmail: "test@user.com")
}
