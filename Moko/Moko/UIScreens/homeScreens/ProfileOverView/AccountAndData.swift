//
//  AccountAndData.swift
//  Moko
//
//  Profile → "Account & data": shows how the user signed in, lets them edit
//  their profile, export everything as JSON, sign out or delete the account.
//

import SwiftUI
import SwiftData
import Auth

struct ProfileOverViewAccountAndData: View {
    // A shortcut from the app's root to log the user out and go back to the start.
    @Environment(\.endSession) private var endSession

    // @Query reads saved SwiftData records and keeps the list up to date by itself.
    // We need every kind of record so the export contains all of the user's data.
    @Query private var profiles: [Profile]
    @Query private var quests: [Quest]
    @Query private var calmSessions: [CalmDownModel]
    @Query private var insights: [InsightsModel]
    @Query private var responses: [OnboardingResponse]

    // The sign-in email shown at the top. Starts as a placeholder until we ask Supabase.
    @State private var email = "Loading account…"
    // True while we wait for Supabase, so a small spinner shows.
    @State private var isLoadingAccount = true
    // Opens the "Sign out?" alert.
    @State private var showSignOut = false
    // Opens the Edit Profile sheet.
    @State private var showEditProfile = false

    /// All of the user's data as pretty JSON text, ready to share.
    private var exportJSON: String {
        // Turns a date into standard text like "2026-11-14T09:30:00Z".
        let iso = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "exportedAt": iso.string(from: .now),
            "profile": profiles.first.map {
                ["displayName": $0.username, "username": $0.handle ?? "", "ageRange": $0.ageRange ?? "",
                 "xp": $0.xp, "currentStreak": $0.currentStreak, "longestStreak": $0.longestStreak] as [String: Any]
            } ?? [:],
            "quests": quests.map {
                ["title": $0.title, "notes": $0.notes, "category": $0.category.rawValue,
                 "date": iso.string(from: $0.date), "completed": $0.isCompleted,
                 "completedAt": $0.completedAt.map { iso.string(from: $0) } ?? "",
                 "xp": $0.awardedXP] as [String: Any]
            },
            "calmSessions": calmSessions.map {
                ["title": $0.exerciseTitle, "seconds": $0.exerciseTime,
                 "date": iso.string(from: $0.date)] as [String: Any]
            },
            "scores": insights.map {
                ["courage": $0.courage, "clarity": $0.clarity, "presence": $0.presence,
                 "warmth": $0.warmth, "date": iso.string(from: $0.date)] as [String: Any]
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
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
            Section {
                // ShareLink opens Apple's share sheet (AirDrop, Files, Mail…) with the JSON text.
                ShareLink(item: exportJSON) {
                    Label("Export my data", systemImage: "square.and.arrow.up")
                }
            } footer: {
                Text("Your export contains your profile, quests, scores, calm sessions and onboarding answers.")
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
            Section {
                Button(role: .destructive) { showSignOut = true } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .labelStyle(MokoSettingsLabelStyle(isDestructive: true))
                }
                NavigationLink {
                    ProfileOverViewDeleteAccountConfirm()
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .labelStyle(MokoSettingsLabelStyle(isDestructive: true))
                }
            } footer: {
                Text("Deleting your account removes your data from the service and this device.")
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
        }
        .listStyle(.insetGrouped)
        .labelStyle(MokoSettingsLabelStyle())
        // Keep account actions as easy to read and tap as the main Settings rows.
        .environment(\.defaultMinListRowHeight, 72)
        .foregroundStyle(ProfilePalette.text)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Account & Data")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        // `.task` runs when the screen appears: ask Supabase who is signed in.
        .task {
            // `defer` runs at the very end, even if the lookup fails, so the spinner always stops.
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
                // Sign out on the server in the background, and leave this screen right away.
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
