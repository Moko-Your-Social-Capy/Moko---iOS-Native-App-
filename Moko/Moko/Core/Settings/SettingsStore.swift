//
//  SettingsStore.swift
//  Moko
//
//  One place for every Settings permission and preference. Screens read the
//  status from here instead of asking iOS themselves, so the wording and the
//  behaviour stay the same everywhere.
//
//  The store never asks for access when it is created. It only reads the
//  current status. A request happens when the person taps a button or uses a
//  feature that needs the permission.
//

import Foundation
import Observation
import UserNotifications
import AVFoundation
import UIKit
import OSLog

@MainActor
@Observable
final class SettingsStore {

    /// The whole app shares one store, so every Settings screen shows the same state.
    static let shared = SettingsStore()

    /// The identifier used for the daily reminder notification.
    static let reminderIdentifier = "moko.dailyReminder"

    // MARK: - Notification state

    private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var notificationSettings: UNNotificationSettings?
    private(set) var remindersEnabled: Bool
    private(set) var reminderHour: Int
    private(set) var reminderMinute: Int
    private(set) var hasPendingReminder = false

    // MARK: - Device permission state

    private(set) var microphoneStatus: AVAudioApplication.recordPermission = .undetermined
    private(set) var cameraStatus: AVAuthorizationStatus = .notDetermined

    // MARK: - Live Activities

    let liveActivities = LiveActivityController()

    /// Short messages shown under each permission section.
    private(set) var notificationMessage: String?
    private(set) var microphoneMessage: String?
    private(set) var cameraMessage: String?

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private init() {
        remindersEnabled = defaults.bool(forKey: "dailyRemindersEnabled")
        let storedHour = defaults.object(forKey: "reminderHour") as? Int
        let storedMinute = defaults.object(forKey: "reminderMinute") as? Int
        reminderHour = storedHour ?? 9
        reminderMinute = storedMinute ?? 0
        refreshDevicePermissions()
    }

    // MARK: - Refresh

    /// Reads every permission again. Safe to call when the app returns from iOS Settings.
    func refresh() async {
        refreshDevicePermissions()
        await loadNotificationState()
        liveActivities.refresh()
    }

    /// Reads microphone and camera state without ever showing a permission popup.
    func refreshDevicePermissions() {
        microphoneStatus = AVAudioApplication.shared.recordPermission
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)

        // A permission changed in iOS Settings may make an old warning untrue.
        if microphoneStatus == .granted { microphoneMessage = nil }
        if cameraStatus == .authorized { cameraMessage = nil }
    }

    /// Reads notification status and makes sure the reminder matches the current permission.
    private func loadNotificationState() async {
        let settings = await center.notificationSettings()
        notificationSettings = settings
        notificationStatus = settings.authorizationStatus

        let pending = await center.pendingNotificationRequests()
        hasPendingReminder = pending.contains { $0.identifier == Self.reminderIdentifier }

        if notificationStatus.allowsNotifications {
            if remindersEnabled {
                if !hasPendingReminder { await scheduleReminder() }
            } else if hasPendingReminder {
                // The preference is off, so no reminder should be waiting.
                cancelReminder()
            }
        } else {
            // If permission is gone, stop saying a reminder is scheduled.
            if hasPendingReminder {
                cancelReminder()
            }
            if remindersEnabled {
                saveRemindersEnabled(false)
            }
        }
    }

    // MARK: - Notifications

    /// Asks iOS for notification permission. Only call this after a tap.
    @discardableResult
    func requestNotificationPermission() async -> Bool {
        if notificationStatus == .notDetermined {
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                Logger.settings.error("Notification permission request failed: \(error.localizedDescription, privacy: .public)")
                notificationMessage = "Notifications could not be turned on. Try again in iOS Settings."
            }
        }

        await loadNotificationState()

        if notificationStatus.allowsNotifications {
            notificationMessage = nil
            return true
        } else {
            notificationMessage = "Notifications are off for Moko. You can turn them on in iOS Settings."
            return false
        }
    }

    /// Turns the daily reminder on. Asks for permission if needed.
    @discardableResult
    func enableReminders() async -> Bool {
        if notificationStatus == .notDetermined {
            let granted = await requestNotificationPermission()
            guard granted else { return false }
        }

        guard notificationStatus.allowsNotifications else {
            notificationMessage = "Allow notifications in iOS Settings before turning on a reminder."
            return false
        }

        saveRemindersEnabled(true)
        await scheduleReminder()
        notificationMessage = nil
        return true
    }

    /// Turns the daily reminder off and removes its pending notification.
    func disableReminders() {
        saveRemindersEnabled(false)
        cancelReminder()
        notificationMessage = nil
    }

    /// Stores a new time and replaces the old pending reminder.
    func setReminderTime(hour: Int, minute: Int) async {
        reminderHour = hour
        reminderMinute = minute
        defaults.set(hour, forKey: "reminderHour")
        defaults.set(minute, forKey: "reminderMinute")

        guard remindersEnabled, notificationStatus.allowsNotifications else { return }
        await scheduleReminder()
    }

    /// Creates (or replaces) the repeating calendar notification.
    private func scheduleReminder() async {
        guard remindersEnabled, notificationStatus.allowsNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = "A small moment for you"
        content.body = "Your daily Moko moment is ready. One tiny step is enough."
        content.sound = .default

        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.reminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
        do {
            try await center.add(request)
            hasPendingReminder = true
        } catch {
            Logger.settings.error("Reminder scheduling failed: \(error.localizedDescription, privacy: .public)")
            hasPendingReminder = false
            notificationMessage = "The reminder could not be scheduled. Check notification access in iOS Settings."
        }
    }

    /// Removes the reminder without changing the saved preference.
    private func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
        hasPendingReminder = false
    }

    private func saveRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        defaults.set(enabled, forKey: "dailyRemindersEnabled")
    }

    // MARK: - Microphone

    /// Shows Apple's microphone popup. Only call this after a tap.
    func requestMicrophonePermission() async {
        guard microphoneStatus == .undetermined else {
            refreshDevicePermissions()
            return
        }

        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        refreshDevicePermissions()

        if granted {
            microphoneMessage = nil
        } else {
            microphoneMessage = "Microphone access is off. You can turn it on in iOS Settings."
        }
    }

    // MARK: - Camera

    /// Shows Apple's camera popup. Only call this after a tap.
    func requestCameraPermission() async {
        guard cameraStatus == .notDetermined else {
            refreshDevicePermissions()
            return
        }

        _ = await AVCaptureDevice.requestAccess(for: .video)
        refreshDevicePermissions()

        if cameraStatus == .authorized {
            cameraMessage = nil
        } else {
            cameraMessage = "Camera access is off. You can turn it on in iOS Settings."
        }
    }
}
