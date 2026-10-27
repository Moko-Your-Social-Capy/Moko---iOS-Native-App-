//
//  RelaxScreen.swift
//  Moko
//
//  Relax tab integrating the new Imagery Guide relax flow.
//

import SwiftUI

struct RelaxScreen: View {
    @Binding var selectedTab: MokoTab

    init(selectedTab: Binding<MokoTab> = .constant(.relax), onStartBreathing: ((Int) -> Void)? = nil, onStartSession: ((RelaxSession) -> Void)? = nil) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        RelaxFlow()
    }
}

#Preview {
    RelaxScreen(selectedTab: .constant(.relax))
}
