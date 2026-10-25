//
//  MainHomeContainerView.swift
//  Moko
//
//  Orchestrates tab navigation using OverviewCopiedView.
//

import SwiftUI

struct MainHomeContainerView: View {
    var userEmail: String

    var body: some View {
        NavigationStack {
            OverviewCopiedView()
        }
    }
}

#Preview {
    MainHomeContainerView(userEmail: "test@user.com")
}
