//
//  LiveActivityController.swift
//  Moko
//
//  Talks to ActivityKit. It reports whether the device can show Live
//  Activities, whether the user has turned them on, and it can start,
//  update and end a Moko activity for testing the real system integration.
//
//  The app can never switch Live Activities on by itself. Only iOS Settings
//  can do that, so the controller only reports the truth and points people
//  to Settings when the switch is off.
//

import Foundation
import Observation
import ActivityKit
import UIKit

@MainActor
@Observable
final class LiveActivityController {

    // True when the device family can show Live Activities at all.
    private(set) var isDeviceSupported: Bool = LiveActivityController.deviceSupportsLiveActivities
    // True when the person has Live Activities turned on in iOS Settings.
    private(set) var areActivitiesEnabled: Bool = false
    // True while a Moko Live Activity is running.
    private(set) var isActive: Bool = false
    // A short message shown in Settings when something needs explaining.
    private(set) var statusMessage: String?

    private var activity: Activity<MokoActivityAttributes>?
    private let authorizationInfo = ActivityAuthorizationInfo()

    init() {
        refresh()
    }

    /// Re-reads the system state. Call this when the app becomes active again.
    func refresh() {
        areActivitiesEnabled = authorizationInfo.areActivitiesEnabled
        activity = Activity<MokoActivityAttributes>.activities.first
        isActive = activity != nil
    }

    /// Starts a real Live Activity. The widget extension draws it.
    func start() {
        refresh()
        guard isDeviceSupported else {
            statusMessage = "This device cannot show Live Activities."
            return
        }
        guard areActivitiesEnabled else {
            statusMessage = "Live Activities are turned off in iOS Settings."
            return
        }
        guard activity == nil else { return }

        let now = Date()
        let content = ActivityContent(
            state: MokoActivityAttributes.ContentState(
                message: "Your Moko session is active.",
                startedAt: now,
                updatedAt: now
            ),
            staleDate: nil
        )

        do {
            activity = try Activity.request(
                attributes: MokoActivityAttributes(title: "Moko session"),
                content: content
            )
            isActive = true
            statusMessage = nil
        } catch {
            statusMessage = Self.readableMessage(for: error)
        }
    }

    /// Sends a fresh state to the running activity, as a real app would when progress changes.
    func update() async {
        guard let activity else { return }
        let now = Date()
        let state = MokoActivityAttributes.ContentState(
            message: "Updated at \(now.formatted(date: .omitted, time: .standard)).",
            startedAt: activity.contentState.startedAt,
            updatedAt: now
        )
        await activity.update(ActivityContent(state: state, staleDate: nil))
        statusMessage = "Live Activity updated."
    }

    /// Ends the activity and removes it from the Lock Screen and Dynamic Island.
    func end() async {
        guard let activity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
        isActive = false
        statusMessage = "Live Activity ended."
    }

    /// Live Activities need an iPhone or iPad running this version of iOS.
    private static var deviceSupportsLiveActivities: Bool {
        // Apps running on a Mac cannot show an iPhone Live Activity.
        guard !ProcessInfo.processInfo.isiOSAppOnMac else { return false }
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .pad:
            return true
        default:
            return false
        }
    }

    /// Turns ActivityKit's error codes into words a person can understand.
    private static func readableMessage(for error: Error) -> String {
        guard let activityError = error as? ActivityAuthorizationError else {
            return "The Live Activity could not start."
        }
        switch activityError {
        case .denied:
            return "Live Activities are turned off in iOS Settings."
        case .unsupported, .unsupportedTarget:
            return "This device cannot show Live Activities."
        case .globalMaximumExceeded, .targetMaximumExceeded:
            return "Too many Live Activities are already running."
        case .unentitled:
            return "The app is missing its Live Activities entitlement."
        default:
            return "The Live Activity could not start."
        }
    }
}
