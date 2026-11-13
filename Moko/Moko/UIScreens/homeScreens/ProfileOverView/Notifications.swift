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

    private let screenBg = ProfilePalette.background
    private let deepGreen = ProfilePalette.accent

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
    @State private var showPreprompt = false
    @State private var pendingReminder: String?

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
                Toggle(isOn: permissionBinding($dailyReminder, key: "daily")) {
                    Label("Daily practice reminder", systemImage: "bell")
                }
                Toggle(isOn: permissionBinding($streakAtRisk, key: "streak")) {
                    Label("Streak at risk", systemImage: "flame")
                }
                Toggle(isOn: permissionBinding($newQuests, key: "quests")) {
                    Label("New quests & scenarios", systemImage: "star")
                }
                Toggle(isOn: permissionBinding($cooldownBreathing, key: "cooldown")) {
                    Label("Cooldown breathing", systemImage: "sparkle")
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("Turning on a reminder asks iOS for notification permission. If notifications are off for MOKO, these switches stay off until you allow them in Settings.")
            }
        }
        .tint(deepGreen)
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
        .sheet(isPresented: $showPreprompt) {
            NotificationPermissionPreprompt(
                onAllow: { Task { await requestPendingReminder() } },
                onNotNow: { pendingReminder = nil; showPreprompt = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Permission-aware toggle

    private func permissionBinding(_ value: Binding<Bool>, key: String) -> Binding<Bool> {
        Binding(
            get: { value.wrappedValue },
            set: { isOn in
                if isOn {
                    Task {
                        await enableReminder(value, key: key)
                    }
                } else {
                    value.wrappedValue = false
                }
            }
        )
    }

    @MainActor
    private func enableReminder(_ value: Binding<Bool>, key: String) async {
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
            pendingReminder = key
            showPreprompt = true

        @unknown default:
            value.wrappedValue = false
        }
    }

    @MainActor
    private func requestPendingReminder() async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        showPreprompt = false
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            if granted {
                switch pendingReminder {
                case "daily": dailyReminder = true
                case "streak": streakAtRisk = true
                case "quests": newQuests = true
                case "cooldown": cooldownBreathing = true
                default: break
                }
            } else {
                showPermissionAlert = true
            }
        } catch {
            showPermissionAlert = true
        }
        pendingReminder = nil
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

private struct NotificationPermissionPreprompt: View {
    let onAllow: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 4)
            Image(systemName: "bell.badge")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(ProfilePalette.accent)
            Text("Want a gentle nudge each day?")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(ProfilePalette.text)
            Text("Moko can remind you about a practice. You can change this any time in Settings.")
                .font(.body)
                .foregroundStyle(ProfilePalette.secondary)
            Spacer()
            Button("Allow reminders", action: onAllow)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 48)
                .buttonStyle(.borderedProminent)
                .tint(ProfilePalette.accent)
                .buttonBorderShape(.capsule)
            Button("Not now", action: onNotNow)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(ProfilePalette.background.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewNotifications()
    }
}
