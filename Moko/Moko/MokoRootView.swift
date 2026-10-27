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
    @State private var searchedTerm = ""
    var useInMemoryStore = false

    var body: some View {
        TabView(selection: $tab) {
            Tab("Overview", systemImage: "square.grid.2x2.fill", value: MokoTab.overview) {
                Overview(selectedTab: $tab)
            }

            Tab("Quests", systemImage: "clipboard.fill", value: MokoTab.quests) {
                QuestsScreen()
            }

            Tab("Relax", systemImage: "figure.mind.and.body", value: MokoTab.relax) {
                RelaxFlow(selectedTab: $tab)
            }

            Tab("Search", systemImage: "magnifyingglass", value: MokoTab.search, role: .search) {
                NavigationStack {
                    SearchView(selectedTab: $tab)
                        .searchable(text: $searchedTerm)
                }
            }
        }
        .tint(Color(red: 27/255, green: 66/255, blue: 47/255)) // #1B422F
        .modelContainer(useInMemoryStore ? MokoDatabase.preview : MokoDatabase.shared)
    }
}

#Preview {
    MokoRootView(useInMemoryStore: true)
}
