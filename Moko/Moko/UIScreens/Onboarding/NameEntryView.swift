//
//  NameEntryView.swift
//  Moko
//
//  Intro step 2: the user types the name Moko should call them.
//  Continue stays disabled until the name has at least one non-space letter.
//

import SwiftUI

struct NameEntryView: View {
    /// How full the top progress bar is (0...1).
    var progress: CGFloat = 0.677
    /// Called with the cleaned-up name when the user continues.
    var onContinue: (String) -> Void = { _ in }

    /// What the user has typed so far.
    @State private var name = ""
    /// True while the keyboard is up for the name field.
    @FocusState private var isFocused: Bool

    private let placeholderColor = Color(hex: 0xD2C6B3)

    /// The name without leading/trailing spaces or new lines.
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canContinue: Bool { !trimmedName.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(progress: progress)
                .padding(.horizontal, 20)

            Text("What should we call you?")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            nameField
                .padding(.horizontal, 30)
                .padding(.top, 35)

            Spacer()

            OnboardingContinueButton(isEnabled: canContinue, action: submit)
                .padding(.horizontal, 20)
                .padding(.bottom, 38)
        }
        .background(MokoBackdrop())
        // Runs once when the screen appears: open the keyboard straight away.
        .task { isFocused = true }
    }

    // MARK: Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Name")
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)

            TextField(
                "",
                text: $name,
                prompt: Text("e.g. John").foregroundStyle(placeholderColor)
            )
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.ink)
            .tint(Color.forest)                          // cursor color
            .focused($isFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.continue)                      // keyboard's return key says "continue"
            .onSubmit(submit)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Make the whole area (not just the text) tappable to bring the keyboard back.
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    // MARK: Actions

    private func submit() {
        guard canContinue else { return }
        onContinue(trimmedName)
    }
}

#Preview {
    NameEntryView(onContinue: { _ in })
}
