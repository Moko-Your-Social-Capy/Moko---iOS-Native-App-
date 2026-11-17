//
//  NameEntryView.swift
//  Moko
//
//  Intro step 2: the user types the name Moko should call them and picks their age.
//  Continue stays disabled until the name has at least one non-space letter.
//

import SwiftUI

struct NameEntryView: View {
    var initialName = ""
    var initialAge = 20
    var ageRange: ClosedRange<Int> = 13...100
    /// Called with the cleaned-up name and selected age when the user continues.
    var onContinue: (String, Int) -> Void = { _, _ in }

    @Environment(\.mokoTheme) private var theme

    // Tracks what the user is typing before it is saved to the Profile model.
    @State private var name = ""
    // The age chosen in the native picker below the username field.
    @State private var selectedAge = 20
    // Lets only the username field take keyboard focus.
    @FocusState private var isFocused: Bool

    init(
        initialName: String = "",
        initialAge: Int = 20,
        ageRange: ClosedRange<Int> = 13...100,
        onContinue: @escaping (String, Int) -> Void = { _, _ in }
    ) {
        self.initialName = initialName
        self.initialAge = initialAge
        self.ageRange = ageRange
        self.onContinue = onContinue
        _name = State(initialValue: initialName)
        _selectedAge = State(initialValue: initialAge)
    }

    /// The name without leading/trailing spaces or new lines.
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canContinue: Bool { !trimmedName.isEmpty }

    var body: some View {
        OnboardingJourneyScaffold(
            currentPage: 1,
            buttonTitle: "Continue",
            footer: "You can update your name and age anytime in Profile.",
            isEnabled: canContinue,
            action: submit
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Label("ABOUT YOU", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(theme.colors.ctaAccentText.opacity(0.75))

                Text("What should\nMoko call you?")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .tracking(-1.2)
                    .lineSpacing(-2)
                    .foregroundStyle(theme.colors.ctaAccentText)
                    .padding(.top, 16)

                Text("Tell us a little about yourself so Moko can personalize your daily practice.")
                    .font(.subheadline.weight(.medium))
                    .lineSpacing(3)
                    .foregroundStyle(theme.colors.ctaAccentText.opacity(0.82))
                    .padding(.top, 14)
                    .padding(.bottom, 30)

                usernameField

                agePicker
                    .padding(.top, 20)
            }
        }
        // Focuses the name field when this step opens, so the keyboard is ready immediately.
        .task {
            isFocused = true
        }
        .sensoryFeedback(.selection, trigger: selectedAge)
    }

    // MARK: Username field

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("USERNAME")
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(theme.colors.ctaAccentText.opacity(0.78))

            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canContinue ? theme.colors.ctaAccent : theme.colors.secondaryText)
                    .accessibilityHidden(true)

                TextField(
                    "",
                    text: $name,
                    prompt: Text("e.g. John")
                        .foregroundStyle(theme.colors.placeholder)
                )
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.colors.primaryText)
                .tint(theme.colors.ctaAccent)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .onSubmit(submit)
                .accessibilityLabel("Username")

                if canContinue {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.colors.success)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 72)
            .padding(.horizontal, 20)
            .background(theme.colors.cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        theme.colors.focusColor.opacity(isFocused ? 0.9 : 0.12),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
            .shadow(color: theme.colors.cardShadow.opacity(0.12), radius: 8, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            // Tapping anywhere in the field brings the keyboard back.
            .onTapGesture { isFocused = true }
        }
    }

    // MARK: Age picker

    private var agePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR AGE")
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(theme.colors.ctaAccentText.opacity(0.78))

            Picker("Age", selection: $selectedAge) {
                ForEach(Array(ageRange), id: \.self) { age in
                    Text("\(age)")
                        .font(.title3.weight(.semibold))
                        .tag(age)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 150)
            .background(theme.colors.cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(theme.colors.cardBorder.opacity(0.72), lineWidth: 1)
            }
            .accessibilityLabel("Your age")
            .accessibilityValue("\(selectedAge) years")
        }
    }

    // MARK: Actions

    private func submit() {
        guard canContinue else { return }
        onContinue(trimmedName, selectedAge)
    }
}

#Preview {
    NavigationStack {
        NameEntryView()
    }
    .mokoThemeRoot()
}
