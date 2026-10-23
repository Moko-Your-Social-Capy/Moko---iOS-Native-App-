//
//  MokoRootView.swift
//  Moko
//
//  App root. Owns the selected tab and shows the matching screen.
//  Each screen still draws its own MokoTabBar; the bar reports taps
//  to this view through the environment so the screen switches.
//

import SwiftUI

struct MokoRootView: View {
    enum OverviewState {
        case todo
        case debriefDone
        case resume
    }

    @State private var tab: MokoTab = .overview

    /// Which Overview variant the Overview tab shows.
    var overviewState: OverviewState = .todo

    var body: some View {
        content
            .id(tab) // fresh screen (and bar selection) on every switch
            .environment(\.mokoTabSelect, { newTab in
                tab = newTab
            })
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .overview:
            switch overviewState {
            case .todo:        Overview()
            case .debriefDone: OverviewDebriefDone()
            case .resume:      OverviewResumeScreen()
            }
        case .quests:
            MokoPlaceholderScreen(title: "Quests", initialTab: .quests)
        case .relax:
            RelaxScreen()
        case .search:
            MokoPlaceholderScreen(title: "Search", initialTab: .search)
        }
    }
}

// Stand-in for tabs that don't have a screen yet
struct MokoPlaceholderScreen: View {
    let title: String
    @State private var selectedTab: MokoTab

    init(title: String, initialTab: MokoTab) {
        self.title = title
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 242/255, green: 242/255, blue: 247/255)
                .ignoresSafeArea()

            Text(title)
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            MokoTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
    }
}

#Preview {
    MokoRootView()
}