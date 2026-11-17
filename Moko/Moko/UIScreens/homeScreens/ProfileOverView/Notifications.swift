//
//  Notifications.swift
//  Moko
//
//  Settings → Reminders & Notifications. Shows the real iOS permission,
//  lets the person ask for access, and schedules or cancels the daily
//  reminder through UNUserNotificationCenter.
//

import SwiftUI
import UIKit

struct ProfileOverViewNotifications: View {

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var settings = SettingsStore.shared
    @State private var showingTimePicker = false
    @State private var tempTime = Date()
    @State private var showingDeniedAlert = false

    private let calendar = Calendar.current

    var body: some View {
        List {
            Section {
                LabeledContent("Permission") {
                    Text(settings.notificationStatusLabel)
                        .foregroundStyle(settings.notificationStatus.allowsNotifications
                                         ? MokoScreenTheme.Colors.forest
                                         : MokoScreenTheme.Colors.error)
                }

                if let delivery = deliveryLabel {
                    LabeledContent("Delivery") {
                        Text(delivery)
                            .foregroundStyle(settings.notificationsDeliverNormally
                                             ? MokoScreenTheme.Colors.forest
                                             : MokoScreenTheme.Colors.error)
                    }
                }

                if settings.notificationStatus == .notDetermined {
                    Button("Allow notifications") {
                        Task { await settings.requestNotificationPermission() }
                    }
                }

                if settings.notificationStatus == .denied || !settings.notificationsDeliverNormally {
                    Button("Open notification settings") { openNotificationSettings() }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if let message = settings.notificationMessage {
                    Text(message)
                }
            }

            Section {
                Toggle("Daily reminder", isOn: reminderBinding)

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

                if settings.hasPendingReminder {
                    Label("Reminder scheduled", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(MokoScreenTheme.Colors.forest)
                }
            } header: {
                Text("Daily reminder")
            } footer: {
                Text("Moko asks for notification access only when you turn on a reminder or tap Allow.")
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 60)
        .tint(MokoScreenTheme.Colors.ctaAccent)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .task { await settings.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await settings.refresh() }
            }
        }
        .sheet(isPresented: $showingTimePicker) { timePickerSheet }
        .alert("Notifications are off", isPresented: $showingDeniedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Open iOS Settings") { openNotificationSettings() }
        } message: {
            Text("Turn on notifications for Moko in iOS Settings, then come back and enable the reminder.")
        }
    }

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

    private var deliveryLabel: String? {
        guard settings.notificationStatus != .notDetermined,
              let notificationSettings = settings.notificationSettings else { return nil }
        return [
            notificationSettings.alertSetting.title("Banners"),
            notificationSettings.soundSetting.title("Sounds"),
            notificationSettings.badgeSetting.title("Badges")
        ].joined(separator: " · ")
    }

    private var timePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker("Reminder time", selection: $tempTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxHeight: 200)

                Text("Moko will remind you every day at \(tempTime.formatted(date: .omitted, time: .shortened)).")
                    .font(.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                Button {
                    let parts = calendar.dateComponents([.hour, .minute], from: tempTime)
                    showingTimePicker = false
                    Task {
                        await settings.setReminderTime(
                            hour: parts.hour ?? 9,
                            minute: parts.minute ?? 0
                        )
                    }
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(MokoScreenTheme.Colors.ctaAccent)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.top, 32)
            .background(MokoBackdrop())
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { showingTimePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview {
    NavigationStack { ProfileOverViewNotifications() }
}

#Preview("Notifications — Larger Text") {
    NavigationStack { ProfileOverViewNotifications() }
        .environment(\.dynamicTypeSize, .accessibility3)
}
