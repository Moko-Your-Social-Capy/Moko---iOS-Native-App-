import SwiftUI
import SwiftData

struct ProfileOverViewDeleteFinalConfirmation: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.endSession) private var endSession
    @State private var showConfirm = false
    @State private var isDeleting = false
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

    @MainActor private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await AuthService().deleteAccount()
            try modelContext.delete(model: Quest.self)
            try modelContext.delete(model: CalmDownModel.self)
            try modelContext.delete(model: InsightsModel.self)
            try modelContext.delete(model: Profile.self)
            try modelContext.delete(model: OnboardingResponse.self)
            try modelContext.delete(model: OnboardingQuestion.self)
            try modelContext.delete(model: OnboardingState.self)
            try modelContext.save()
            PendingDebriefStore.clear()
            CurrentUser.reset()
            ["userName", "userAge", "moko.selectedCostumeLevel", "notifyDaily", "notifyStreak", "notifyQuests", "notifyCooldown"]
                .forEach(UserDefaults.standard.removeObject(forKey:))
            endSession?(.deleteAccount)
        } catch {
            self.error = "We could not delete your account. Check your connection and try again. Your local data is still here."
        }
    }
}
