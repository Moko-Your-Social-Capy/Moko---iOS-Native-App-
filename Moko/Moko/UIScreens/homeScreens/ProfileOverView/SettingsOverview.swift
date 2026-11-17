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
    @Environment(\.mokoTheme) private var theme

    var body: some View {
        List {
            // Appearance: pick theme and light/dark mode (saved on device).
            Section {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Theme & Appearance", systemImage: "paintpalette")
                }
            }
           

            Section {
                NavigationLink {
                    ProfileOverViewAccountAndData()
                } label: {
                    Label("Account & Data", systemImage: "person.crop.circle")
                }
            } header: {
                sectionTitle("Account")
            }
            .listRowBackground(theme.colors.cardSurface)

            Section {
                NavigationLink {
                    ProfileOverViewNotifications()
                } label: {
                    Label("Reminders & Notifications", systemImage: "bell")
                }
            } header: {
                sectionTitle("Reminders")
            }
            .listRowBackground(theme.colors.cardSurface)

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
                sectionTitle("Permissions")
            } footer: {
                Text("Access is requested only when a supported feature needs it.")
                    .foregroundStyle(theme.colors.secondaryText)
            }
            .listRowBackground(theme.colors.cardSurface)

            Section {
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
            } header: {
                sectionTitle("Privacy and legal")
            }
            .listRowBackground(theme.colors.cardSurface)

            Section {
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
            } header: {
                sectionTitle("Support")
            }
            .listRowBackground(theme.colors.cardSurface)
        }
        .listStyle(.insetGrouped)
        .labelStyle(MokoSettingsLabelStyle())
        .foregroundStyle(theme.colors.primaryText)
        // Larger rows stay easy to find and grow further when text needs to wrap.
        .environment(\.defaultMinListRowHeight, 72)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .tint(theme.colors.ctaAccent)
    }

    private func sectionTitle(_ text: String) -> some View {
        // Section titles must stay readable in dark mode.
        Text(text)
            .foregroundStyle(theme.colors.secondaryText)
    }
}

#Preview {
    NavigationStack { ProfileOverViewSettingsOverview() }
}

#Preview("Settings — Larger Text") {
    NavigationStack { ProfileOverViewSettingsOverview() }
        .environment(\.dynamicTypeSize, .accessibility3)
}
