//
//  AccountDeletedConfirmation.swift
//  Moko
//
//  Confirmation screen shown once after the user deletes their account.
//

import SwiftUI

// The screen shares the app's theme, like every other screen.
private typealias Theme = MokoScreenTheme

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

#Preview("Account deleted") {
    AccountDeletedConfirmation(onContinue: {})
}
