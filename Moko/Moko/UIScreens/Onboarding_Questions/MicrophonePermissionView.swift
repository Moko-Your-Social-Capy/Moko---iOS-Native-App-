//
//  MicrophonePermissionView.swift
//  Moko
//
//  Two simple full-screen messages that share the same look:
//  - MicrophonePermissionView: explains why Moko wants the mic, then asks iOS for it.
//  - AccountDeletedConfirmation: shown once after the user deletes their account.
//
//  Debug tip: iOS only shows the mic popup once per install. To see it again,
//  delete the app (or reset the simulator), then reinstall.
//

import SwiftUI
import AVFoundation

// The two screens in this file share the app's theme, like every other screen.
private typealias Theme = MokoScreenTheme

// MARK: - Microphone permission

struct MicrophonePermissionView: View {
    /// Called when the mic is allowed, or when the user taps "Skip for now".
    let onContinue: () -> Void

    /// True while Apple's permission popup is on screen.
    @State private var isRequesting = false
    /// Shown under the text if the user says no.
    @State private var permissionMessage: String?

    private let reason = "Moko uses your mic only when you record a voice reflection. You choose when it starts and you can delete recordings any time."

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Image("profile_empty_moko")
                .resizable()
                .scaledToFit()
                .frame(width: 164, height: 164)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "headphones")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.Colors.dataVioletDeep)
                        .padding(12)
                        .background(Theme.Colors.surfaceWhite, in: Circle())
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Moko wearing headphones")

            Text("Let Moko listen")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textTitle)
                .padding(.top, 28)

            Text(reason)
                .font(.body)
                .foregroundStyle(Theme.Colors.textBody)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Text("You can also use text reflections. Moko works without microphone access.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
                .padding(.top, 14)

            if let permissionMessage {
                Text(permissionMessage)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.error)
                    .padding(.top, 10)
            }

            Spacer()

            Button(action: requestMicrophone) {
                // Show a small loader instead of the label while the popup is up.
                Group {
                    if isRequesting {
                        MokoFlossLoadingView(size: 30)
                            .frame(width: 30, height: 30)
                    } else {
                        Text("Allow microphone").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.dataVioletDeep)
            .buttonBorderShape(.capsule)
            .disabled(isRequesting)

            Button("Skip for now", action: onContinue)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.Colors.textBody)
                .frame(maxWidth: .infinity, minHeight: 50)
                .contentShape(Rectangle())
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MokoBackdrop())
    }

    private func requestMicrophone() {
        isRequesting = true
        Task {
            // Shows Apple's "Allow microphone?" popup and waits for the user's answer.
            // The popup text comes from NSMicrophoneUsageDescription (target → Info tab).
            // Without it, the app crashes here.
            let granted = await AVAudioApplication.requestRecordPermission()
            isRequesting = false
            if granted {
                onContinue()
            } else {
                permissionMessage = "Microphone access is off. You can continue with text reflections."
            }
        }
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
                .foregroundStyle(Theme.Colors.tabActiveGlyph)
                .accessibilityHidden(true)

            Text("Your account was deleted")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textTitle)

            Text("Your account and local Moko data have been removed.")
                .font(.body)
                .foregroundStyle(Theme.Colors.textBody)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.dataVioletDeep)
            .buttonBorderShape(.capsule)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MokoBackdrop())
    }
}

#Preview("Microphone") {
    MicrophonePermissionView(onContinue: {})
}

#Preview("Account deleted") {
    AccountDeletedConfirmation(onContinue: {})
}
