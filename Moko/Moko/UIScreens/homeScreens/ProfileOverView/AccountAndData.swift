import SwiftUI
import SwiftData
import Auth

struct ProfileOverViewAccountAndData: View {
    @Environment(\.endSession) private var endSession
    @Query private var profiles: [Profile]
    @Query private var quests: [Quest]
    @Query private var calmSessions: [CalmDownModel]
    @Query private var insights: [InsightsModel]
    @Query private var responses: [OnboardingResponse]

    @State private var email = "Loading account…"
    @State private var isLoadingAccount = true
    @State private var showSignOut = false
    @State private var showEditProfile = false

    private var exportJSON: String {
        let payload: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "profile": profiles.first.map {
                ["displayName": $0.username, "username": $0.handle ?? "", "ageRange": $0.ageRange ?? "",
                 "xp": $0.xp, "currentStreak": $0.currentStreak, "longestStreak": $0.longestStreak] as [String: Any]
            } ?? [:],
            "quests": quests.map {
                ["title": $0.title, "notes": $0.notes, "category": $0.category.rawValue,
                 "date": ISO8601DateFormatter().string(from: $0.date), "completed": $0.isCompleted,
                 "completedAt": $0.completedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
                 "xp": $0.awardedXP] as [String: Any]
            },
            "calmSessions": calmSessions.map {
                ["title": $0.exerciseTitle, "seconds": $0.exerciseTime,
                 "date": ISO8601DateFormatter().string(from: $0.date)] as [String: Any]
            },
            "scores": insights.map {
                ["courage": $0.courage, "clarity": $0.clarity, "presence": $0.presence,
                 "warmth": $0.warmth, "date": ISO8601DateFormatter().string(from: $0.date)] as [String: Any]
            },
            "onboardingResponses": responses.map { ["questionID": $0.questionID, "response": $0.userResponse] }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("Sign-in method") {
                    HStack(spacing: 8) {
                        if isLoadingAccount {
                            MokoFlossLoadingView(size: 28)
                                .frame(width: 28, height: 28)
                        }
                        Text(email)
                    }
                }
                Button {
                    showEditProfile = true
                } label: {
                    Label("Edit Profile", systemImage: "person")
                }
            }
            Section {
                ShareLink(item: exportJSON) {
                    Label("Export my data", systemImage: "square.and.arrow.up")
                }
            } footer: {
                Text("Your export contains your profile, quests, scores, calm sessions and onboarding answers.")
            }
            Section {
                Button(role: .destructive) { showSignOut = true } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(minHeight: 44)
                }
                NavigationLink {
                    ProfileOverViewDeleteAccountConfirm()
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .foregroundStyle(ProfilePalette.error)
                        .frame(minHeight: 44)
                }
            } footer: {
                Text("Deleting your account removes your data from the service and this device.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ProfilePalette.background)
        .navigationTitle("Account Info")
        .navigationBarTitleDisplayMode(.large)
        .task {
            defer { isLoadingAccount = false }
            if let user = try? await AuthService().getCurrentUser() {
                email = user.email ?? "Signed in"
            } else {
                email = profiles.first?.username ?? "On this device"
            }
        }
        .sheet(isPresented: $showEditProfile) {
            ProfileOverViewEditProfile()
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
        .tint(ProfilePalette.accent)
    }
}

#Preview {
    NavigationStack { ProfileOverViewAccountAndData() }
        .modelContainer(for: [Profile.self, Quest.self, CalmDownModel.self, InsightsModel.self, OnboardingResponse.self], inMemory: true)
}
