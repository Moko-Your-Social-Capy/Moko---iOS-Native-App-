//
//  ProfileSettingsView.swift
//  Moko
//
//  Profile → Settings. Top level is a short menu; each row navigates to a
//  screen that holds a group of related, real settings.
//

import SwiftUI
import AVFoundation
import UserNotifications
import ActivityKit

// MARK: - Shared styling for every settings screen

private struct MokoSettingsListStyle: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .labelStyle(MokoSettingsLabelStyle())
            .environment(\.defaultMinListRowHeight, 60)
            .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            .scrollContentBackground(.hidden)
            .background(MokoBackdrop())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.visible, for: .navigationBar)
            .tint(MokoScreenTheme.Colors.ctaAccent)
    }
}

private extension View {
    func mokoSettingsList(title: String) -> some View {
        modifier(MokoSettingsListStyle(title: title))
    }
}

// MARK: - Top level

struct ProfileSettingsView: View {

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Theme & Appearance", systemImage: "paintpalette")
                }

                NavigationLink {
                    AccountSettingsView()
                } label: {
                    Label("Account", systemImage: "person.crop.circle")
                }

                NavigationLink {
                    PermissionsSettingsView()
                } label: {
                    Label("Permissions", systemImage: "hand.raised")
                }

                NavigationLink {
                    AboutAndLegalSettingsView()
                } label: {
                    Label("About & Legal", systemImage: "info.circle")
                }
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
        }
        .mokoSettingsList(title: "Settings")
    }
}

// MARK: - Account (sign out + delete account live here now)

struct AccountSettingsView: View {

    var body: some View {
        List {
            SettingsAccountSection()
        }
        .mokoSettingsList(title: "Account")
    }
}

// MARK: - Permissions (toggles only)

enum PermissionState {
    case notDetermined, allowed, denied
}

@MainActor
@Observable
final class PermissionsModel {

    var notifications: PermissionState = .notDetermined
    var microphone: PermissionState = .notDetermined
    var camera: PermissionState = .notDetermined
    var liveActivities: PermissionState = .notDetermined

    // Reading only: this never shows a permission popup.
    func refresh() async {
        let notif = await UNUserNotificationCenter.current().notificationSettings()
        switch notif.authorizationStatus {
        case .notDetermined: notifications = .notDetermined
        case .denied: notifications = .denied
        default: notifications = .allowed   // authorized, provisional, ephemeral
        }

        switch AVAudioApplication.shared.recordPermission {
        case .undetermined: microphone = .notDetermined
        case .granted: microphone = .allowed
        default: microphone = .denied
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: camera = .notDetermined
        case .authorized: camera = .allowed
        default: camera = .denied
        }

        // Live Activities can't be requested, only enabled in iOS Settings.
        liveActivities = ActivityAuthorizationInfo().areActivitiesEnabled ? .allowed : .denied
    }

    func requestNotifications() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        await refresh()
    }

    func requestMicrophone() async {
        _ = await AVAudioApplication.requestRecordPermission()
        await refresh()
    }

    func requestCamera() async {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        await refresh()
    }
}

/// A real toggle for an iOS permission.
/// - Off → On, never asked: shows the system popup.
/// - Any other flip: iOS doesn't let apps grant or revoke on their own,
///   so it opens this app's page in iOS Settings.
private struct PermissionToggleRow: View {
    let title: String
    let icon: String
    let state: PermissionState
    var canRequest: Bool = true
    let request: () async -> Void

    var body: some View {
        Toggle(isOn: Binding(
            get: { state == .allowed },
            set: { _ in
                Task {
                    if state == .notDetermined && canRequest {
                        await request()
                    } else {
                        openAppSettings()
                    }
                }
            }
        )) {
            Label(title, systemImage: icon)
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct PermissionsSettingsView: View {

    // Tells us when the app comes back after the person changed a permission.
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = PermissionsModel()

    var body: some View {
        List {
            Section {
                PermissionToggleRow(
                    title: "Notifications",
                    icon: "bell",
                    state: model.notifications,
                    request: model.requestNotifications
                )
                PermissionToggleRow(
                    title: "Microphone",
                    icon: "mic",
                    state: model.microphone,
                    request: model.requestMicrophone
                )
                PermissionToggleRow(
                    title: "Camera",
                    icon: "camera",
                    state: model.camera,
                    request: model.requestCamera
                )
                PermissionToggleRow(
                    title: "Live Activities",
                    icon: "platter.filled.top.iphone",
                    state: model.liveActivities,
                    canRequest: false,
                    request: {}
                )
            } footer: {
                Text("If a permission was already answered, iOS only lets you change it in Settings, so the toggle opens it for you.")
            }
            .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
        }
        .mokoSettingsList(title: "Permissions")
        .task { await model.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refresh() } }
        }
    }
}

// MARK: - About & Legal

struct AboutAndLegalSettingsView: View {

    var body: some View {
        List {
            SettingsLegalSection()
            SettingsAboutSection()
        }
        .mokoSettingsList(title: "About & Legal")
    }
}

#Preview {
    NavigationStack { ProfileSettingsView() }
}

#Preview("Permissions") {
    NavigationStack { PermissionsSettingsView() }
}

#Preview("Account") {
    NavigationStack { AccountSettingsView() }
}
