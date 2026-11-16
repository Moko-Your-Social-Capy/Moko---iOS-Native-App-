//
//  Notifications.swift
//  Moko
//
//  Settings → Reminders and Notifications.
//  Each switch is saved on the phone, but it can only be ON if iOS allows
//  notifications for Moko. The first time, we show a friendly explanation
//  sheet before iOS shows its own permission pop-up.
//

import SwiftUI
import UserNotifications

struct ProfileOverViewNotifications: View {

    private let screenBg = ProfilePalette.background
    private let deepGreen = ProfilePalette.accent

    // Saved on the device so the switches keep their state. Switches start off
    // until iOS has granted notification permission.
    @AppStorage("notifyDaily") private var dailyReminder = false
    @AppStorage("notifyStreak") private var streakAtRisk = false
    @AppStorage("notifyQuests") private var newQuests = false
    @AppStorage("notifyCooldown") private var cooldownBreathing = false

    // Tells us if the app is on screen (`.active`) or in the background.
    @Environment(\.scenePhase) private var scenePhase
    // Opens the iPhone Settings app.
    @Environment(\.openURL) private var openURL

    // What iOS currently allows: not asked yet, allowed, or denied.
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    // The "Notifications are off" alert.
    @State private var showPermissionAlert = false
    // Stops a second permission request while the first one is still running.
    @State private var isRequestingPermission = false
    // Our explanation sheet, shown before the iOS pop-up.
    @State private var showPreprompt = false
    // Which switch the user tapped while we were asking permission ("daily", "streak", ...).
    @State private var pendingReminder: String?

    var body: some View {
        List {
            if authorizationStatus == .denied {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications are off for Moko", systemImage: "bell.slash")
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
                Text("Turning on a reminder asks iOS for notification permission. If notifications are off for Moko, these switches stay off until you allow them in Settings.")
            }
        }
        .tint(deepGreen)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        // `.task(id:)` runs when the screen opens and again whenever `scenePhase` changes.
        // So if the user comes back from the Settings app, we re-check the permission.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await refreshAuthorizationStatus()
        }
        .alert("Notifications are off", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openSystemSettings()
            }
            Button("Not now", role: .cancel) { }
        } message: {
            Text("Allow notifications for Moko in iOS Settings to use reminders.")
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

    /// A custom binding for a Toggle. Turning OFF works straight away.
    /// Turning ON first checks the iOS permission (that is async, so it runs in a Task).
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

    /// Decides what happens when a switch is turned on, based on the iOS permission.
    @MainActor
    private func enableReminder(_ value: Binding<Bool>, key: String) async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        // `defer` runs when the function ends, whichever way it ends.
        defer { isRequestingPermission = false }

        // Ask iOS what the user has allowed for this app.
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            // Already allowed: just turn the switch on.
            value.wrappedValue = true

        case .denied:
            // The user said no before. Only the Settings app can change that.
            value.wrappedValue = false
            showPermissionAlert = true

        case .notDetermined:
            // Never asked: show our explanation first, and remember which switch it was.
            pendingReminder = key
            showPreprompt = true

        @unknown default:
            value.wrappedValue = false
        }
    }

    /// Called from "Allow reminders" on our sheet: shows the real iOS permission pop-up.
    @MainActor
    private func requestPendingReminder() async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        showPreprompt = false
        do {
            // iOS shows its pop-up here. `granted` is true if the user taps Allow.
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            if granted {
                // Turn on the switch the user originally tapped.
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

    /// Reads the current permission. If notifications are not allowed, turns every switch off.
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

    /// Opens Moko's page in the iPhone Settings app.
    private func openSystemSettings() {
        guard let url = mokoOpenAppSettingsURL() else { return }
        openURL(url)
    }
}

/// Our own explanation sheet, shown before the iOS permission pop-up.
/// iOS only lets an app ask once, so we explain why first.
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
        .background(MokoBackdrop())
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewNotifications()
    }
}
