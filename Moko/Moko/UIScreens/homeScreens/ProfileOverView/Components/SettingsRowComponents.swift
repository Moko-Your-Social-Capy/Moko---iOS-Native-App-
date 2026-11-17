//
//  SettingsRowComponents.swift
//  Moko
//
//  Small shared pieces for the Settings list: a coloured status row, the
//  reminder time sheet, and readable names for Apple notification settings.
//

import SwiftUI
import UserNotifications

/// One "label … value" row. Green means access is allowed, red means it is not.
struct SettingsStatusRow: View {
    let title: String
    let value: String
    let isGood: Bool

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .foregroundStyle(isGood ? MokoScreenTheme.Colors.forest : MokoScreenTheme.Colors.error)
        }
    }
}

/// The wheel sheet used to pick the daily reminder time.
struct SettingsReminderTimeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (Date) -> Void

    // The value the wheel is showing right now.
    @State private var time: Date

    init(initialTime: Date, onSave: @escaping (Date) -> Void) {
        _time = State(initialValue: initialTime)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxHeight: 200)

                Text("Moko will remind you every day at \(time.formatted(date: .omitted, time: .shortened)).")
                    .font(.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                Button {
                    onSave(time)
                    dismiss()
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
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }
}

extension UNNotificationSetting {
    /// Turns an Apple setting into "Banners on" or "Banners off".
    func title(_ name: String) -> String {
        switch self {
        case .enabled:
            return "\(name) on"
        case .disabled:
            return "\(name) off"
        case .notSupported:
            return "\(name) unavailable"
        @unknown default:
            return name
        }
    }
}
