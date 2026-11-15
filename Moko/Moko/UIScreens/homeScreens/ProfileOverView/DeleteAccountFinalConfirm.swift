//
//  DeleteAccountFinalConfirm.swift
//  Moko
//
//  Delete account, step 3: one last "are you sure?" and then the real delete.
//  The server account is deleted first; local data is wiped only if that worked.
//

import SwiftUI
import SwiftData

struct ProfileOverViewDeleteFinalConfirmation: View {
    // SwiftData's "save box" on the phone. We empty it after the server delete succeeds.
    @Environment(\.modelContext) private var modelContext
    // A shortcut from the app's root to leave the signed-in area.
    @Environment(\.endSession) private var endSession
    // Opens the last "Delete your account?" alert.
    @State private var showConfirm = false
    // True while deleting, so the button shows a spinner and cannot be pressed twice.
    @State private var isDeleting = false
    // A red message if something went wrong. `nil` means no message.
    @State private var error: String?

    var body: some View {
        List {
            Section {
                Text("This is the final step. Your account and its data will be permanently deleted.")
                    .foregroundStyle(ProfilePalette.text)
                if let error {
                    Text(error).foregroundStyle(ProfilePalette.error)
                }
            } footer: {
                Text("This action cannot be undone.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ProfilePalette.background)
        .navigationTitle("Delete permanently")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) { showConfirm = true } label: {
                HStack {
                    Spacer()
                    if isDeleting {
                        MokoFlossLoadingView(size: 34)
                            .frame(width: 34, height: 34)
                    }
                    else { Text("Delete permanently").fontWeight(.semibold) }
                    Spacer()
                }.frame(minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(ProfilePalette.error)
            .disabled(isDeleting)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .alert("Delete your account?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete permanently", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("Your account data will be deleted from the service and this device.")
        }
    }

    /// Deletes the account on the server, then everything stored on this phone.
    @MainActor private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            // 1. Server first. If this throws we jump to `catch` and keep the local data.
            try await AuthService().deleteAccount()

            // 2. Remove every kind of SwiftData record from the phone.
            try modelContext.delete(model: Quest.self)
            try modelContext.delete(model: CalmDownModel.self)
            try modelContext.delete(model: InsightsModel.self)
            try modelContext.delete(model: Profile.self)
            try modelContext.delete(model: OnboardingResponse.self)
            try modelContext.delete(model: OnboardingQuestion.self)
            try modelContext.delete(model: OnboardingState.self)
            try modelContext.save()

            // 3. Clear the small things saved outside SwiftData (drafts and settings).
            PendingDebriefStore.clear()
            DebriefDraftStore.clearAll()
            CurrentUser.reset()
            ["userName", "userAge", "moko.selectedCostumeLevel", "notifyDaily", "notifyStreak", "notifyQuests", "notifyCooldown"]
                .forEach(UserDefaults.standard.removeObject(forKey:))

            // 4. Go back to the welcome screen.
            endSession?(.deleteAccount)
        } catch {
            self.error = "We could not delete your account. Check your connection and try again. Your local data is still here."
        }
    }
}
