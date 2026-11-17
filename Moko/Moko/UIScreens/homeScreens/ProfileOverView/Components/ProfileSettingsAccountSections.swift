//
//  ProfileSettingsAccountSections.swift
//  Moko
//
//  Account, legal and about rows for the Settings screen. These all open
//  real screens or real account actions.
//

import SwiftUI

/// Account info, sign out and account deletion.
struct SettingsAccountSection: View {
    @Environment(\.endSession) private var endSession

    @State private var showSignOut = false

    var body: some View {
        Section("Account") {
            NavigationLink {
                ProfileOverViewAccountAndData()
            } label: {
                Label("Account & Data", systemImage: "person.crop.circle")
            }

            Button(role: .destructive) {
                showSignOut = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .labelStyle(MokoSettingsLabelStyle(isDestructive: true))
            }
            .alert("Sign out of Moko?", isPresented: $showSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { try? await AuthService().signOut() }
                    endSession?(.signOut)
                }
            } message: {
                Text("Your progress will stay on this device.")
            }

            NavigationLink {
                ProfileOverViewDeleteAccountConfirm()
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .labelStyle(MokoSettingsLabelStyle(isDestructive: true))
            }
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }
}

/// The project ships its legal text inside the app, so these open the local
/// pages instead of guessing at a website address.
struct SettingsLegalSection: View {
    var body: some View {
        Section("Terms & privacy") {
            NavigationLink {
                ProfileOverViewTerms()
            } label: {
                Label("Terms and Conditions", systemImage: "doc.text")
            }

            NavigationLink {
                ProfileOverViewPrivacyPolicy()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            NavigationLink {
                ProfileOverViewPrivacy()
            } label: {
                Label("App permissions & data", systemImage: "lock.shield")
            }
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }
}

struct SettingsAboutSection: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Section("About") {
            LabeledContent("App Version", value: appVersion)
            LabeledContent("Build Number", value: buildNumber)
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }
}
