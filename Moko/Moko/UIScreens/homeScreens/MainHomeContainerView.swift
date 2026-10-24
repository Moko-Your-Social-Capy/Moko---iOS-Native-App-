//
//  MainHomeContainerView.swift
//  Moko
//
//  Orchestrates tab navigation between Overview, Quests, Relax, and Search.
//

import SwiftUI

struct MainHomeContainerView: View {
    @State private var selectedTab: MokoTab = .overview
    var userEmail: String

    var body: some View {
        ZStack(alignment: .bottom) {
            switch selectedTab {
            case .overview:
                Overview(selectedTab: $selectedTab)
            case .quests:
                OverviewDebriefDone()
            case .relax:
                RelaxView(selectedTab: $selectedTab)
            case .search:
                Overview(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    MainHomeContainerView(userEmail: "test@user.com")
}
