//
//  Notifications.swift
//  Moko
//
//  Settings → Reminders and Notifications.
//  Reminders have no delivery service yet. Explain that without offering
//  switches that do nothing or asking for notification access.
//

import SwiftUI

struct ProfileOverViewNotifications: View {

    var body: some View {
        List {
            Section {
                Label("Reminders aren't available yet", systemImage: "bell.slash")
                    .labelStyle(MokoSettingsLabelStyle())

                Text("Moko doesn't currently schedule reminders. Notification access won't be requested until reminders can be delivered.")
                    .font(.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, MokoScreenTheme.Space.s2)
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 72)
        .tint(ProfilePalette.accent)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }

}

#Preview {
    NavigationStack {
        ProfileOverViewNotifications()
    }
}
