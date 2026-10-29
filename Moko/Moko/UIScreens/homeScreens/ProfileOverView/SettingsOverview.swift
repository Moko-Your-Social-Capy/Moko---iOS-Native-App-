//
//  ProfileOverViewSettingsOverview.swift
//  Moko
//
//  Settings screen (matches the "Settings · Overview · Light" prototype).
//  Push it from Profile with:
//      NavigationLink("Settings") { ProfileOverViewSettingsOverview() }
//  The NavigationStack gives the default back button, so none is drawn here.
//

import SwiftUI

struct ProfileOverViewSettingsOverview: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)     // #1B422F

    @State private var showEditProfile = false
    @State private var showSignOut = false

    var body: some View {
        List {
            Section("Account") {
                Button {
                    showEditProfile = true
                } label: {
                    row("Edit Profile", systemImage: "person")
                }

                NavigationLink {
                    ProfileOverViewNotifications()
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
            }

            Section("Privacy") {
                NavigationLink { Text("Privacy") } label: {
                    Label("Privacy", systemImage: "lock")
                }
                NavigationLink { Text("Privacy Policy") } label: {
                    Label("Privacy Policy", systemImage: "shield")
                }
                NavigationLink { Text("Terms of Service") } label: {
                    Label("Terms of Service", systemImage: "doc")
                }
            }

            Section("Support") {
                NavigationLink { Text("Help & Support") } label: {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                NavigationLink { Text("About MOKO") } label: {
                    Label("About MOKO", systemImage: "info.circle")
                }
            }

            Section {
                NavigationLink {
                    ProfileOverViewAccountAndData()
                } label: {
                    Label("Account & Data", systemImage: "person.crop.circle")
                }

                Button(role: .destructive) {
                    showSignOut = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("No appearance switch: MOKO follows the system Light/Dark setting.")
            }
        }
        .tint(deepGreen)
        .scrollContentBackground(.hidden)
        .background(screenBg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        // Edit Profile opens as a sheet
        .sheet(isPresented: $showEditProfile) {
            ProfileOverViewEditProfile()
        }
        .signOutAlert(isPresented: $showSignOut) {
            // TODO: clear the signed-in user and go back to the start screen.
        }
    }

    /// Button row that looks like a NavigationLink row (label + chevron).
    private func row(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewSettingsOverview()
    }
}
