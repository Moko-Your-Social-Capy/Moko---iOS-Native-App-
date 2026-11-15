//
//  SettingsOverview.swift
//  Moko
//
//  Profile → "Settings & privacy": the list that links to account, reminders,
//  legal pages, phone permissions, delete-my-data and support.
//

import SwiftUI
import UIKit

struct ProfileOverViewSettingsOverview: View {
    // SwiftUI's way to open a link (a website or the Settings app).
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("Account") {
                NavigationLink {
                    ProfileOverViewAccountAndData()
                } label: {
                    Label("Account Info", systemImage: "person.crop.circle")
                }
            }

            Section("Reminders") {
                NavigationLink {
                    ProfileOverViewNotifications()
                } label: {
                    Label("Reminders and Notifications", systemImage: "bell")
                }
            }

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
                Button {
                    // Jumps to Moko's page in the iPhone Settings app (camera, microphone, notifications).
                    if let url = mokoOpenAppSettingsURL() { openURL(url) }
                } label: {
                    Label("Manage permissions", systemImage: "lock")
                        .foregroundStyle(ProfilePalette.text)
                        .frame(minHeight: 44)
                }
                NavigationLink {
                    ProfileOverViewDeleteAccountConfirm()
                } label: {
                    Label("Delete my data", systemImage: "trash")
                        .foregroundStyle(ProfilePalette.error)
                        .frame(minHeight: 44)
                }
            }

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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ProfilePalette.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .tint(ProfilePalette.accent)
    }
}

#Preview {
    NavigationStack { ProfileOverViewSettingsOverview() }
}
