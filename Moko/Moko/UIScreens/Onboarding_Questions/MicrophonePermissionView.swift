//
//  MicrophonePermissionView.swift
//  Moko
//
//  Two simple full-screen messages that share the same look:
//  - MicrophonePermissionView: shows the real microphone permission.
//  - AccountDeletedConfirmation: shown once after the user deletes their account.
//
//  Opening this screen only reads the status. The permission popup appears
//  after a tap on "Allow microphone".
//

import SwiftUI
import UIKit
import AVFAudio

// Share the app's mint, white, forest, and readable text colors.
private typealias PermissionTheme = MokoScreenTheme

// MARK: - Microphone permission

struct MicrophonePermissionView: View {
    // Close this screen without changing any permission.
    @Environment(\.dismiss) private var dismiss
    // Opens the Settings app when microphone access was denied.
    @Environment(\.openURL) private var openURL
    // Refresh the status after the person returns from Settings.
    @Environment(\.scenePhase) private var scenePhase

    // The shared permission store. Reading it never shows a popup.
    @State private var settings = SettingsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PermissionTheme.Space.s4) {
                Image("profile_empty_moko")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: settings.microphoneStatus == .granted ? "mic.fill" : "mic.slash")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(PermissionTheme.Colors.forest)
                            .padding(PermissionTheme.Space.s3)
                            .background(PermissionTheme.Colors.surfaceWhite, in: Circle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PermissionTheme.Space.s6)
                    .accessibilityHidden(true)

                Text("Microphone")
                    .font(.title.weight(.bold))
                    .foregroundStyle(PermissionTheme.Colors.textTitle)
                    .accessibilityAddTraits(.isHeader)

                HStack {
                    Text("Status")
                    Spacer()
                    Text(settings.microphoneStatusLabel)
                        .fontWeight(.semibold)
                        .foregroundStyle(settings.microphoneStatus == .granted
                                         ? PermissionTheme.Colors.forest
                                         : PermissionTheme.Colors.error)
                }
                .font(.body)
                .padding(PermissionTheme.Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .mokoCard()

                Text("Moko uses the microphone only when you record a voice reflection in a debrief. You can always type instead.")
                    .font(.body)
                    .foregroundStyle(PermissionTheme.Colors.textBody)
                    .fixedSize(horizontal: false, vertical: true)

                if let message = settings.microphoneMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(PermissionTheme.Colors.error)
                }
            }
            .padding(PermissionTheme.Space.page)
        }
        .background(MokoBackdrop())
        // Keep the action within reach while larger text scrolls above it.
        .safeAreaInset(edge: .bottom) {
            actionButton
                .buttonStyle(.borderedProminent)
                .tint(PermissionTheme.Colors.forest)
                .buttonBorderShape(.capsule)
                .padding(.horizontal, PermissionTheme.Space.page)
                .padding(.vertical, PermissionTheme.Space.s3)
                .background(PermissionTheme.Colors.surfaceWhite.ignoresSafeArea(edges: .bottom))
        }
        .navigationTitle("Microphone")
        .navigationBarTitleDisplayMode(.inline)
        .task { await settings.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await settings.refresh() }
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch settings.microphoneStatus {
        case .undetermined:
            Button {
                Task { await settings.requestMicrophonePermission() }
            } label: {
                primaryLabel("Allow microphone")
            }
        case .denied:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                primaryLabel("Open iOS Settings")
            }
        default:
            Button { dismiss() } label: {
                primaryLabel("Done")
            }
        }
    }

    private func primaryLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
    }
}

// MARK: - Account deleted

struct AccountDeletedConfirmation: View {
    /// Called when the user taps Continue (goes back to the start of the app).
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(PermissionTheme.Colors.forest)
                .accessibilityHidden(true)

            Text("Your account was deleted")
                .font(.title.weight(.bold))
                .foregroundStyle(PermissionTheme.Colors.textTitle)

            Text("Your account and local Moko data have been removed.")
                .font(.body)
                .foregroundStyle(PermissionTheme.Colors.textBody)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(PermissionTheme.Colors.forest)
            .buttonBorderShape(.capsule)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MokoBackdrop())
    }
}

#Preview("Microphone") {
    NavigationStack { MicrophonePermissionView() }
}

#Preview("Microphone — Larger Text") {
    NavigationStack { MicrophonePermissionView() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Account deleted") {
    AccountDeletedConfirmation(onContinue: {})
}
