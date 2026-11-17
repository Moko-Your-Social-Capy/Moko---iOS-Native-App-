//
//  ProfileSettingsLiveActivitySection.swift
//  Moko
//
//  Shows the real ActivityKit state and lets the person start, update and
//  end a Live Activity. iOS owns the permission; Moko only reports it.
//

import SwiftUI
import UIKit

struct SettingsLiveActivitySection: View {
    @Environment(\.openURL) private var openURL

    @State private var settings = SettingsStore.shared

    var body: some View {
        Section {
            SettingsStatusRow(
                title: "Device support",
                value: settings.liveActivities.isDeviceSupported ? "Supported" : "Not supported",
                isGood: settings.liveActivities.isDeviceSupported
            )

            SettingsStatusRow(
                title: "Live Activities",
                value: settings.liveActivities.areActivitiesEnabled ? "On" : "Off",
                isGood: settings.liveActivities.areActivitiesEnabled
            )

            if settings.liveActivities.isActive {
                SettingsStatusRow(title: "Current activity", value: "Running", isGood: true)

                Button("Update Live Activity") {
                    Task { await settings.liveActivities.update() }
                }
                Button("End Live Activity", role: .destructive) {
                    Task { await settings.liveActivities.end() }
                }
            } else if settings.liveActivities.areActivitiesEnabled && settings.liveActivities.isDeviceSupported {
                Button("Start Live Activity") {
                    settings.liveActivities.start()
                }
            }

            if settings.liveActivities.isDeviceSupported && !settings.liveActivities.areActivitiesEnabled {
                Button("Open iOS Settings") { openAppSettings() }
            }

            if let message = settings.liveActivities.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
            }
        } header: {
            Text("Live Activities")
        } footer: {
            Text("iOS controls this permission; Moko cannot switch it on. The Dynamic Island appears only on supported iPhone models and when iOS chooses to present the activity.")
        }
        .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
