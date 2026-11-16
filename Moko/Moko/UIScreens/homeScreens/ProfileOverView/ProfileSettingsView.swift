//
//  ProfileSettingsView.swift
//  Moko
//
//  Settings view for profile preferences including haptics and reminders.
//  Follows MokoScreenTheme design system.
//

import SwiftUI
import UserNotifications

struct ProfileSettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("dailyRemindersEnabled") private var dailyRemindersEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("streakNotificationsEnabled") private var streakNotificationsEnabled = true
    @AppStorage("achievementNotificationsEnabled") private var achievementNotificationsEnabled = true
    
    @State private var showingReminderTimePicker = false
    @State private var tempReminderTime = Date()
    @State private var showingNotificationsHelp = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        List {
            Section {
                ToggleSettingRow(
                    icon: "hand.tap",
                    iconColor: MokoScreenTheme.Colors.dataVioletDeep,
                    title: "Haptic Feedback",
                    description: "Subtle vibrations for interactions and feedback",
                    isOn: $hapticsEnabled
                )
                
                ToggleSettingRow(
                    icon: "bell",
                    iconColor: MokoScreenTheme.Colors.dataMagenta,
                    title: "Daily Reminders",
                    description: "Get notified to practice mindfulness each day",
                    isOn: $dailyRemindersEnabled
                )
                .onChange(of: dailyRemindersEnabled) { oldValue, newValue in
                    if newValue {
                        requestNotificationPermission()
                    }
                }
                
                if dailyRemindersEnabled {
                    Button {
                        showingReminderTimePicker = true
                    } label: {
                        HSettingRow(
                            icon: "clock",
                            iconColor: MokoScreenTheme.Colors.dataTeal,
                            title: "Reminder Time",
                            value: formattedReminderTime,
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                }
            } header: {
                Text("Preferences")
                    .mokoText(MokoScreenTheme.Typeface.sectionHeader)
            } footer: {
                Text("Adjust how Moko interacts with you and reminds you to practice.")
                    .mokoText(MokoScreenTheme.Typeface.caption)
            }
            
            Section {
                ToggleSettingRow(
                    icon: "flame",
                    iconColor: MokoScreenTheme.Colors.dataGold,
                    title: "Streak Notifications",
                    description: "Celebrate when you reach new streak milestones",
                    isOn: $streakNotificationsEnabled
                )
                
                ToggleSettingRow(
                    icon: "trophy",
                    iconColor: MokoScreenTheme.Colors.dataMagenta,
                    title: "Achievement Notifications",
                    description: "Get notified when you unlock new achievements",
                    isOn: $achievementNotificationsEnabled
                )
            } header: {
                Text("Notifications")
                    .mokoText(MokoScreenTheme.Typeface.sectionHeader)
            } footer: {
                Button {
                    showingNotificationsHelp = true
                } label: {
                    Text("Need help with notifications?")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                }
            }
            
            Section {
                Button {
                    showingPrivacyPolicy = true
                } label: {
                    HSettingRow(
                        icon: "lock",
                        iconColor: MokoScreenTheme.Colors.dataVioletDeep,
                        title: "Privacy Policy",
                        value: nil,
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
                
                Button {
                    showingTermsOfService = true
                } label: {
                    HSettingRow(
                        icon: "doc.text",
                        iconColor: MokoScreenTheme.Colors.dataTeal,
                        title: "Terms of Service",
                        value: nil,
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
            } header: {
                Text("Legal")
                    .mokoText(MokoScreenTheme.Typeface.sectionHeader)
            }
            
            Section {
                HSettingRow(
                    icon: "info.circle",
                    iconColor: MokoScreenTheme.Colors.textMuted,
                    title: "App Version",
                    value: appVersion,
                    showChevron: false
                )
                
                HSettingRow(
                    icon: "hammer",
                    iconColor: MokoScreenTheme.Colors.textMuted,
                    title: "Build Number",
                    value: buildNumber,
                    showChevron: false
                )
            } header: {
                Text("About")
                    .mokoText(MokoScreenTheme.Typeface.sectionHeader)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReminderTimePicker) {
            reminderTimePickerSheet
        }
        .sheet(isPresented: $showingNotificationsHelp) {
            notificationsHelpSheet
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            privacyPolicySheet
        }
        .sheet(isPresented: $showingTermsOfService) {
            termsOfServiceSheet
        }
        .onAppear {
            updateTempReminderTime()
        }
    }
    
    // MARK: - Sheets
    
    private var reminderTimePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "Select Time",
                    selection: $tempReminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 200)
                
                Text("You'll receive your daily reminder at \(formattedTime(from: tempReminderTime)).")
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                PrimaryButton(title: "Save", action: saveReminderTime)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .padding(.top, 40)
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        showingReminderTimePicker = false
                    }
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }
    
    private var notificationsHelpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    helpSection(
                        icon: "bell",
                        title: "Enable Notifications",
                        description: "Go to Settings > Notifications > Moko and make sure notifications are turned on."
                    )
                    
                    helpSection(
                        icon: "moon",
                        title: "Do Not Disturb",
                        description: "Make sure Do Not Disturb or Focus modes aren't blocking Moko notifications."
                    )
                    
                    helpSection(
                        icon: "iphone",
                        title: "Device Settings",
                        description: "Check that your device's notification settings allow banners, sounds, and badges for Moko."
                    )
                    
                    helpSection(
                        icon: "arrow.clockwise",
                        title: "Restart the App",
                        description: "Sometimes restarting the app can help notifications work properly."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Notification Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) {
                        showingNotificationsHelp = false
                    }
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var privacyPolicySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        .padding(.bottom, 8)
                    
                    privacyPolicySection(
                        title: "Information We Collect",
                        content: "Moko collects minimal data necessary for app functionality, including your profile information, app usage statistics, and preferences. We never sell your personal data."
                    )
                    
                    privacyPolicySection(
                        title: "How We Use Your Data",
                        content: "Your data is used solely to provide and improve the Moko experience, including personalizing your mindfulness journey, tracking your progress, and sending relevant notifications."
                    )
                    
                    privacyPolicySection(
                        title: "Data Security",
                        content: "We implement industry-standard security measures to protect your data. All data is stored securely and transmitted using encryption."
                    )
                    
                    privacyPolicySection(
                        title: "Your Rights",
                        content: "You have the right to access, correct, or delete your personal data at any time through the Account & Data section in settings."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) {
                        showingPrivacyPolicy = false
                    }
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var termsOfServiceSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        .padding(.bottom, 8)
                    
                    termsSection(
                        title: "Acceptance of Terms",
                        content: "By using Moko, you agree to these terms. If you disagree with any part, you may not use our services."
                    )
                    
                    termsSection(
                        title: "Service Description",
                        content: "Moko provides mindfulness and meditation tools. We strive to provide accurate information but make no guarantees about specific outcomes."
                    )
                    
                    termsSection(
                        title: "User Responsibilities",
                        content: "You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account."
                    )
                    
                    termsSection(
                        title: "Limitation of Liability",
                        content: "Moko is not liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the app."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) {
                        showingTermsOfService = false
                    }
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Helper Views
    
    private func helpSection(icon: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                    .frame(width: 40, height: 40)
                    .background(MokoScreenTheme.Colors.dataVioletLight.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            }
            
            Text(description)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
                .padding(.leading, 52)
        }
    }
    
    private func privacyPolicySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            
            Text(content)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
        }
        .padding(.bottom, 16)
    }
    
    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            
            Text(content)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Methods
    
    private var formattedReminderTime: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        if let date = calendar.date(from: components) {
            return dateFormatter.string(from: date)
        }
        
        return "9:00 AM"
    }
    
    private func formattedTime(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private func updateTempReminderTime() {
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = reminderHour
        components.minute = reminderMinute
        tempReminderTime = calendar.date(from: components) ?? now
    }
    private func saveReminderTime() {
        let components = calendar.dateComponents([.hour, .minute], from: tempReminderTime)
        
        reminderHour = components.hour ?? 9
        reminderMinute = components.minute ?? 0
        
        showingReminderTimePicker = false
        
        // Schedule new reminder
        if dailyRemindersEnabled {
            scheduleDailyReminder()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
                scheduleDailyReminder()
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleDailyReminder() {
        guard dailyRemindersEnabled else {
            return
        }
        
        let hour = reminderHour
        let minute = reminderMinute
    

        
        let content = UNMutableNotificationContent()
        content.title = "Time for Mindfulness"
        content.body = "Don't forget to practice mindfulness today and keep your streak going!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyMindfulnessReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMindfulnessReminder"])
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// MARK: - Setting Row Components

struct ToggleSettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                
                Text(description)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(MokoScreenTheme.Colors.dataVioletDeep)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

struct HSettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            
            Spacer()
            
            if let value {
                Text(value)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
}
