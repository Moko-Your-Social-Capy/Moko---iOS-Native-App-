//
//  ProfileOverViewNotifications.swift
//  Moko
//
//  Notifications screen (matches the "Notifications · Light" prototype).
//  Push it from Settings with:
//      NavigationLink("Notifications") { ProfileOverViewNotifications() }
//  The NavigationStack gives the default back button, so none is drawn here.
//

import SwiftUI
import UserNotifications
import UIKit

struct ProfileOverViewNotifications: View {

    private let screenBg = MokoTheme.limeBackground   // #F6FAE8
    private let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)     // #1B422F

    // Saved on the device so the switches keep their state. Switches start off
    // until iOS has granted notification permission.
    @AppStorage("notifyDaily") private var dailyReminder = false
    @AppStorage("notifyStreak") private var streakAtRisk = false
    @AppStorage("notifyQuests") private var newQuests = false
    @AppStorage("notifyCooldown") private var cooldownBreathing = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    @State private var isRequestingPermission = false

    var body: some View {
        List {
            if authorizationStatus == .denied {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications are off for MOKO", systemImage: "bell.slash")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Allow notifications in iOS Settings to use reminders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Open Settings") {
                            openSystemSettings()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Toggle(isOn: permissionBinding($dailyReminder)) {
                    Label("Daily practice reminder", systemImage: "bell")
                }
                Toggle(isOn: permissionBinding($streakAtRisk)) {
                    Label("Streak at risk", systemImage: "flame")
                }
                Toggle(isOn: permissionBinding($newQuests)) {
                    Label("New quests & scenarios", systemImage: "star")
                }
                Toggle(isOn: permissionBinding($cooldownBreathing)) {
                    Label("Cooldown breathing", systemImage: "sparkle")
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("Turning on a reminder asks iOS for notification permission. If notifications are off for MOKO, these switches stay off until you allow them in Settings.")
            }
        }
        .tint(deepGreen)   // green switches
        .scrollContentBackground(.hidden)
        .background(screenBg)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await refreshAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await refreshAuthorizationStatus()
            }
        }
        .alert("Notifications are off", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openSystemSettings()
            }
            Button("Not now", role: .cancel) { }
        } message: {
            Text("Allow notifications for MOKO in iOS Settings to use reminders.")
        }
    }

    // MARK: - Permission-aware toggle

    private func permissionBinding(_ value: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { value.wrappedValue },
            set: { isOn in
                if isOn {
                    Task {
                        await enableReminder(value)
                    }
                } else {
                    value.wrappedValue = false
                }
            }
        )
    }

    @MainActor
    private func enableReminder(_ value: Binding<Bool>) async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            value.wrappedValue = true

        case .denied:
            value.wrappedValue = false
            showPermissionAlert = true

        case .notDetermined:
            value.wrappedValue = true
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                let updated = await center.notificationSettings()
                authorizationStatus = updated.authorizationStatus
                value.wrappedValue = granted
                if !granted {
                    showPermissionAlert = true
                }
            } catch {
                authorizationStatus = .denied
                value.wrappedValue = false
                showPermissionAlert = true
                print("Notification permission request failed:", error)
            }

        @unknown default:
            value.wrappedValue = false
        }
    }

    // MARK: - System status

    @MainActor
    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus

        guard !notificationsAllowed(settings.authorizationStatus) else { return }

        // Keep saved switches consistent with the system permission.
        dailyReminder = false
        streakAtRisk = false
        newQuests = false
        cooldownBreathing = false
    }

    private func notificationsAllowed(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewNotifications()
    }
}
