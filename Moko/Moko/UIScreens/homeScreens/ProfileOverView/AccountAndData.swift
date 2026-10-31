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

    // Text that the share sheet exports. Replace with real data later.
    private let exportText = "Moko data export: reflections and progress."

    var body: some View {
        List {
            Section {
                ShareLink(item: exportText) {
                    Label("Export my data", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.primary)
                }

                NavigationLink {
                    ProfileOverViewDeleteAccountConfirm()
                } label: {
                    Label("Delete account", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .tint(.red)
            } footer: {
                Text("Export builds a file of your reflections and progress and opens the share sheet. Deleting your account removes your profile and history.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(screenBg)
        .navigationTitle("Account & Data")
        .navigationBarTitleDisplayMode(.large)
        .tint(deepGreen)
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewAccountAndData()
    }
}
