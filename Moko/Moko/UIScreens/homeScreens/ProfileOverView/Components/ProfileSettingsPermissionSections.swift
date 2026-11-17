//
//  ProfileSettingsPermissionSections.swift
//  Moko
//
//  Notification, microphone and camera sections. Each one reads the real
//  iOS status from SettingsStore and asks for access only after a tap.
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - Notifications

struct SettingsNotificationsSection: View {
    @Environment(\.openURL) private var openURL

    @State private var settings = SettingsStore.shared
    @State private var showingTimePicker = false
    @State private var tempTime = Date()
    @State private var showingDeniedAlert = false

    private let calendar = Calendar.current

    var body: some View {
        Section {
            SettingsStatusRow(
                title: "Permission",
                value: settings.notificationStatusLabel,
                isGood: settings.notificationStatus.allowsNotifications
            )

            if let delivery = deliveryLabel {
                SettingsStatusRow(
                    title: "Delivery",
                    value: delivery,
                    isGood: settings.notificationsDeliverNormally
                )
            }

            if settings.notificationStatus == .notDetermined {
                Button("Allow notifications") {
                    // Ask only because the person tapped this row.
                    Task { await settings.requestNotificationPermission() }
                }
            }

            if settings.notificationStatus == .denied || !settings.notificationsDeliverNormally {
                Button("Open notification settings") { openNotificationSettings() }
            }

            Toggle("Daily reminder", isOn: reminderBinding)
                .alert("Notifications are off", isPresented: $showingDeniedAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Open iOS Settings") { openNotificationSettings() }
                } message: {
                    Text("Turn on notifications for Moko in iOS Settings, then come back and enable the reminder.")
                }

            Button {
                tempTime = calendar.date(
                    bySettingHour: settings.reminderHour,
                    minute: settings.reminderMinute,
                    second: 0,
                    of: .now
                ) ?? .now
                showingTimePicker = true
            } label: {
                HStack {
                    Text("Reminder time")
                    Spacer()
                    Text(settings.reminderTimeLabel)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingTimePicker) {
                SettingsReminderTimeSheet(initialTime: tempTime) { date in
                    let parts = calendar.dateComponents([.hour, .minute], from: date)
                    Task {
                        await settings.setReminderTime(
                            hour: parts.hour ?? 9,
                            minute: parts.minute ?? 0
                        )
                    }
                }
            }

            if settings.hasPendingReminder {
                Label("Reminder scheduled", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(MokoScreenTheme.Colors.forest)
            }
        } header: {
            Text("Notifications")
        } footer: {
            if let message = settings.notificationMessage {
                Text(message)
            } else {
                Text("Moko asks for notification access only when you turn on a reminder or tap Allow.")
            }
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }

    /// Turning the switch on asks for permission; turning it off cancels the reminder.
    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { settings.remindersEnabled },
            set: { wantsReminder in
                if wantsReminder {
                    if settings.notificationStatus == .denied {
                        showingDeniedAlert = true
                    } else {
                        Task { await settings.enableReminders() }
                    }
                } else {
                    settings.disableReminders()
                }
            }
        )
    }

    /// "Banners on · Sounds on · Badges off" from the real notification settings.
    private var deliveryLabel: String? {
        guard settings.notificationStatus != .notDetermined,
              let notificationSettings = settings.notificationSettings else { return nil }
        return [
            notificationSettings.alertSetting.title("Banners"),
            notificationSettings.soundSetting.title("Sounds"),
            notificationSettings.badgeSetting.title("Badges")
        ].joined(separator: " · ")
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Microphone

struct SettingsMicrophoneSection: View {
    @Environment(\.openURL) private var openURL

    @State private var settings = SettingsStore.shared

    var body: some View {
        Section {
            SettingsStatusRow(
                title: "Status",
                value: settings.microphoneStatusLabel,
                isGood: settings.microphoneStatus == .granted
            )

            switch settings.microphoneStatus {
            case .undetermined:
                Button("Allow microphone") {
                    Task { await settings.requestMicrophonePermission() }
                }
            case .denied:
                Button("Open iOS Settings") { openAppSettings() }
            case .granted:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        } header: {
            Text("Microphone")
        } footer: {
            if let message = settings.microphoneMessage {
                Text(message)
            } else {
                Text("Used only when you record a voice reflection in a debrief. Text reflections never need it.")
            }
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }

    /// Opens Moko's page in the Settings app for this permission.
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Camera

struct SettingsCameraSection: View {
    @Environment(\.openURL) private var openURL

    @State private var settings = SettingsStore.shared

    var body: some View {
        Section {
            SettingsStatusRow(
                title: "Status",
                value: settings.cameraStatusLabel,
                isGood: settings.cameraStatus == .authorized
            )

            switch settings.cameraStatus {
            case .notDetermined:
                Button("Allow camera") {
                    Task { await settings.requestCameraPermission() }
                }
            case .denied, .restricted:
                Button("Open iOS Settings") { openAppSettings() }
            case .authorized:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        } header: {
            Text("Camera")
        } footer: {
            if let message = settings.cameraMessage {
                Text(message)
            } else {
                Text("Used only for the live front-camera preview in Mirror Reflection. Nothing is recorded or saved.")
            }
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
