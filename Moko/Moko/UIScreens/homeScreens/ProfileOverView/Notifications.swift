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

struct ProfileOverViewNotifications: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)     // #1B422F

    // Saved on the device so the switches keep their state.
    @AppStorage("notifyDaily") private var dailyReminder = true
    @AppStorage("notifyStreak") private var streakAtRisk = true
    @AppStorage("notifyQuests") private var newQuests = false
    @AppStorage("notifyCooldown") private var cooldownBreathing = true

    var body: some View {
        List {
            Section {
                Toggle(isOn: $dailyReminder) {
                    Label("Daily practice reminder", systemImage: "bell")
                }
                Toggle(isOn: $streakAtRisk) {
                    Label("Streak at risk", systemImage: "flame")
                }
                Toggle(isOn: $newQuests) {
                    Label("New quests & scenarios", systemImage: "star")
                }
                Toggle(isOn: $cooldownBreathing) {
                    Label("Cooldown breathing", systemImage: "sparkle")
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("iOS asks for notification permission the first time you turn a reminder on. If you decline, the rest of MOKO keeps working and these switches stay off.")
            }
        }
        .tint(deepGreen)   // green switches
        .scrollContentBackground(.hidden)
        .background(screenBg)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        ProfileOverViewNotifications()
    }
}
