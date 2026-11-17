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
        // Use theme-aware tint/text so labels stay readable in light and dark.
        List {
            // Appearance: pick one of six themes and light/dark/system mode.
            Section {
                Text("Appearance").foregroundStyle(MokoScreenTheme.Colors.textBody)
            } header: { EmptyView() }
            Section {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Theme & Appearance", systemImage: "paintpalette")
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

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
        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .tint(MokoScreenTheme.Colors.ctaAccent)
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
