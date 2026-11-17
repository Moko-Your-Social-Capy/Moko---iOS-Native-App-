//
//  SettingsLabels.swift
//  Moko
//
//  Readable words and small helpers for SettingsStore. Keeping them here
//  makes the store itself shorter and easy to scan.
//

import Foundation
import UserNotifications
import AVFoundation
import OSLog

extension SettingsStore {

    /// A readable name for the notification permission.
    var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Not allowed"
        case .provisional:
            return "Quiet delivery"
        case .ephemeral:
            return "Temporary"
        case .notDetermined:
            return "Not asked yet"
        @unknown default:
            return "Unknown"
        }
    }

    /// A readable name for the microphone permission.
    var microphoneStatusLabel: String {
        switch microphoneStatus {
        case .granted:
            return "Allowed"
        case .denied:
            return "Not allowed"
        case .undetermined:
            return "Not asked yet"
        @unknown default:
            return "Unknown"
        }
    }

    /// A readable name for the camera permission.
    var cameraStatusLabel: String {
        switch cameraStatus {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Not allowed"
        case .restricted:
            return "Restricted by iOS"
        case .notDetermined:
            return "Not asked yet"
        @unknown default:
            return "Unknown"
        }
    }

    /// True when iOS will show banners, sounds and badges for this app.
    var notificationsDeliverNormally: Bool {
        notificationStatus.allowsNotifications
            && notificationSettings?.alertSetting == .enabled
    }

    /// "9:00 AM" for the saved reminder time.
    var reminderTimeLabel: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

extension UNAuthorizationStatus {
    /// True when notifications may be shown in any form.
    var allowsNotifications: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
}

extension Logger {
    /// Messages about Settings, reminders and permissions.
    static let settings = Logger(subsystem: "com.mahik.MokoApp", category: "Settings")
}
