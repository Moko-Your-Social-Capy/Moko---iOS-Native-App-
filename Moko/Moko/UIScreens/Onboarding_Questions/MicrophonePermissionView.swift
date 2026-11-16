//
//  MicrophonePermissionView.swift
//  Moko
//
//  Two simple full-screen messages that share the same look:
//  - MicrophonePermissionView: explains why microphone access is not needed yet.
//  - AccountDeletedConfirmation: shown once after the user deletes their account.
//
//  Real recording is not available yet, so this screen never asks for access.
//

import SwiftUI

// Share the app's mint, white, forest, and readable text colors.
private typealias PermissionTheme = MokoScreenTheme

// MARK: - Microphone permission

struct MicrophonePermissionView: View {
    // Close this information screen without changing any permission.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PermissionTheme.Space.s4) {
                Image("profile_empty_moko")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "mic.slash")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(PermissionTheme.Colors.forest)
                            .padding(PermissionTheme.Space.s3)
                            .background(PermissionTheme.Colors.surfaceWhite, in: Circle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PermissionTheme.Space.s6)
                    .accessibilityHidden(true)

                Text("No microphone needed")
                    .font(.title.weight(.bold))
                    .foregroundStyle(PermissionTheme.Colors.textTitle)
                    .accessibilityAddTraits(.isHeader)

                Text("Voice recording isn't available yet. You can complete your reflections by typing, without microphone access.")
                    .font(.body)
                    .foregroundStyle(PermissionTheme.Colors.textBody)
                    .fixedSize(horizontal: false, vertical: true)

                Label("No audio is recorded", systemImage: "lock.shield")
                    .font(.headline)
                    .foregroundStyle(PermissionTheme.Colors.forest)
                    .padding(PermissionTheme.Space.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mokoCard()
            }
            .padding(PermissionTheme.Space.page)
        }
        .background(MokoBackdrop())
        // Keep Done within reach while larger text scrolls above it.
        .safeAreaInset(edge: .bottom) {
            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(PermissionTheme.Colors.forest)
            .buttonBorderShape(.capsule)
            .padding(.horizontal, PermissionTheme.Space.page)
            .padding(.vertical, PermissionTheme.Space.s3)
            .background(PermissionTheme.Colors.surfaceWhite.ignoresSafeArea(edges: .bottom))
        }
        .navigationTitle("Microphone")
        .navigationBarTitleDisplayMode(.inline)
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
