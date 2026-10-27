//
//  RootTabView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

enum AppTab: Hashable {
    case overview, quests, relax, search
}

struct RootTabView: View {
    @State private var selection: AppTab = .relax
    @State private var searchText = ""

    private let sage = Color(hex: 0x365948)

    var body: some View {
        TabView(selection: $selection) {
            Tab("Overview", systemImage: "square.grid.2x2.fill", value: AppTab.overview) {
                PlaceholderScreen(title: "Overview")
            }

            Tab("Quests", systemImage: "list.clipboard.fill", value: AppTab.quests) {
                PlaceholderScreen(title: "Quests")
            }

            Tab("Relax", systemImage: "figure.mind.and.body", value: AppTab.relax) {
                RelaxFlow()
            }

            // On iOS 26 this becomes the separate round search button
            Tab(value: AppTab.search, role: .search) {
                NavigationStack {
                    PlaceholderScreen(title: "Search")
                        .navigationTitle("Search")
                }
                .searchable(text: $searchText)
            }
        }
        .tint(sage)
    }
}

private struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2)
    }
}

#Preview {
    RootTabView()
}
