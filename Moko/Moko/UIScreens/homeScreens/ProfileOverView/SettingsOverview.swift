//
//  SettingsOverview.swift
//  Moko
//
//  Profile → "Settings & privacy": the list that links to account, reminders,
//  legal pages, phone permissions, delete-my-data and support.
//

import SwiftUI

struct ProfileOverViewSettingsOverview: View {
    // SwiftUI's way to open a link (a website or the Settings app).
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            // Appearance: pick theme and light/dark mode (saved on device).
            Section("Appearance") {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Theme & Appearance", systemImage: "paintpalette")
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

            Section("Account") {
                NavigationLink {
                    ProfileOverViewAccountAndData()
                } label: {
                    Label("Account & Data", systemImage: "person.crop.circle")
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

            Section("Reminders") {
                NavigationLink {
                    ProfileOverViewNotifications()
                } label: {
                    Label("Reminders & Notifications", systemImage: "bell")
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

            Section {
                NavigationLink {
                    MicrophonePermissionView()
                } label: {
                    Label("Microphone", systemImage: "mic")
                }
                Button {
                    // Open existing permission choices without requesting any new access.
                    if let url = mokoOpenAppSettingsURL() { openURL(url) }
                } label: {
                    Label("Manage Permissions", systemImage: "lock")
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Access is requested only when a supported feature needs it.")
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

            Section("Privacy and legal") {
                NavigationLink {
                    ProfileOverViewPrivacyPolicy()
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                NavigationLink {
                    ProfileOverViewTerms()
                } label: {
                    Label("Terms of Use", systemImage: "doc.text")
                }
                NavigationLink {
                    ProfileOverViewPrivacy()
                } label: {
                    Label("Data we collect", systemImage: "list.bullet.rectangle")
                }
                NavigationLink {
                    ProfileOverViewDeleteAccountConfirm()
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .labelStyle(MokoSettingsLabelStyle(isDestructive: true))
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

            Section("Support") {
                NavigationLink {
                    ProfileOverViewHelpSupport()
                } label: {
                    Label("Help and Support", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    ProfileOverViewAboutMoko()
                } label: {
                    Label("About Moko", systemImage: "info.circle")
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
        }
        .listStyle(.insetGrouped)
        .labelStyle(MokoSettingsLabelStyle())
        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
        // Larger rows stay easy to find and grow further when text needs to wrap.
        .environment(\.defaultMinListRowHeight, 72)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .tint(MokoScreenTheme.Colors.ctaAccent)
    }
}

#Preview {
    NavigationStack { ProfileOverViewSettingsOverview() }
}

#Preview("Settings — Larger Text") {
    NavigationStack { ProfileOverViewSettingsOverview() }
        .environment(\.dynamicTypeSize, .accessibility3)
}
