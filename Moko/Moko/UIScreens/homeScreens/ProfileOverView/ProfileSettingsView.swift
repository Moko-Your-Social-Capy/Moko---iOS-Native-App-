//
//  ProfileSettingsView.swift
//  Moko
//
//  Profile → Settings. Every row here reads a real iOS permission or changes
//  a real preference. Nothing is a decorative switch.
//

import SwiftUI

struct ProfileSettingsView: View {

    // Tells us when the app comes back after the person changed a permission.
    @Environment(\.scenePhase) private var scenePhase

    // The one shared store for permission state and reminder settings.
    @State private var settings = SettingsStore.shared

    var body: some View {
        List {
            SettingsAccountSection()
            SettingsNotificationsSection()
            SettingsMicrophoneSection()
            SettingsCameraSection()
            SettingsLiveActivitySection()
            SettingsLegalSection()
            SettingsAboutSection()
        }
        .listStyle(.insetGrouped)
        .labelStyle(MokoSettingsLabelStyle())
        .environment(\.defaultMinListRowHeight, 60)
        .foregroundStyle(ProfilePalette.text)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .tint(ProfilePalette.accent)
        // Reading only: this never shows a permission popup.
        .task { await settings.refresh() }
        // When the person returns from iOS Settings, refresh every status.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await settings.refresh() }
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileSettingsView() }
}

#Preview("Settings — Larger Text") {
    NavigationStack { ProfileSettingsView() }
        .environment(\.dynamicTypeSize, .accessibility3)
}
