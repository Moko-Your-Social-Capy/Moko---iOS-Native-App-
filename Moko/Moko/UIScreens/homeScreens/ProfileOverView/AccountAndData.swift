//
//  ProfileOverViewAccountAndData.swift
//  Moko
//
//  Account & Data screen (matches the "Account & Data · Light" prototype).
//  Push it from Settings with:
//      NavigationLink("Account & Data") { ProfileOverViewAccountAndData() }
//  The NavigationStack gives the default back button, so none is drawn here.
//

import SwiftUI

struct ProfileOverViewAccountAndData: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)     // #1B422F

    @State private var showDeleteConfirm = false
    @State private var showFinalConfirm = false

    // Text that the share sheet exports. Replace with real data later.
    private let exportText = "Moko data export: reflections and progress."

    var body: some View {
        List {
            Section {
                ShareLink(item: exportText) {
                    Label("Export my data", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.primary)
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
            } footer: {
                Text("Export builds a file of your reflections and progress and opens the share sheet. Deleting your account removes your profile and history.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(screenBg)
        .navigationTitle("Account & Data")
        .navigationBarTitleDisplayMode(.large)
        .tint(deepGreen)
        // Step 1: first confirmation
        .confirmationDialog("Delete account?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Continue", role: .destructive) { showFinalConfirm = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes your profile and history.")
        }
        // Step 2: final confirmation
        .alert("Delete permanently?", isPresented: $showFinalConfirm) {
            Button("Delete", role: .destructive) {
                // TODO: delete the user's SwiftData records and sign out.
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewAccountAndData()
    }
}
