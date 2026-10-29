//
//  ProfileOverViewDeleteAccountConfirm.swift
//  Moko
//
//  Delete account screen (matches the "Delete account · Confirm" prototype).
//  Pushed from Account & Data. Tapping "Delete my account" shows the final
//  alert from ProfileOverViewDeleteAccountFinalConfirm.swift.
//  The NavigationStack gives the default back button, so none is drawn here.
//

import SwiftUI
import SwiftData

struct ProfileOverViewDeleteAccountConfirm: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)     // #365948
    private let cream = Color(red: 246/255, green: 232/255, blue: 190/255)

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showFinalConfirm = false

    private let consequences = [
        "Your profile, quests and reflections are permanently removed.",
        "Your Insights and Calm Down history are deleted from our servers.",
        "You’ll be signed out on all devices and can’t get this back."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("This can’t be undone. If you delete your account:")
                    .foregroundStyle(.secondary)

                // What gets deleted
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(consequences, id: \.self) { text in
                        Label {
                            Text(text)
                        } icon: {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20))

                // Export first
                VStack(alignment: .leading, spacing: 6) {
                    Text("Want a copy first?").font(.headline)
                    Text("Export your reflections and progress before you go.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ShareLink("Export my data", item: "Moko data export: reflections and progress.")
                        .font(.subheadline.bold())
                        .foregroundStyle(cardGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(cream, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
        }
        .background(screenBg)
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Keep my account").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(cardGreen)

                Button {
                    showFinalConfirm = true
                } label: {
                    Text("Delete my account").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.primary)
            }
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .deleteAccountAlert(isPresented: $showFinalConfirm) {
            deleteAllData()
        }
    }
}

extension ProfileOverViewDeleteAccountConfirm {
    /// Removes the profile and all history from SwiftData.
    func deleteAllData() {
        do {
            try modelContext.delete(model: Profile.self)
            try modelContext.delete(model: Quest.self)
            try modelContext.delete(model: CalmDownModel.self)
            try modelContext.delete(model: InsightsModel.self)
            try modelContext.save()
        } catch {
            print("Delete failed:", error)
        }
        // TODO: sign out / return to the start screen here.
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewDeleteAccountConfirm()
    }
    .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self], inMemory: true)
}
