//
//  AppearanceSettingsView.swift
//  Moko
//
//  Lets the user pick a visual theme, light/dark/system appearance, and font style.
//  Changes apply immediately and are saved on this device.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(MokoThemeManager.self) private var manager
    @Environment(\.mokoTheme) private var theme

    var body: some View {
        @Bindable var manager = manager
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                appearanceSection
                fontSection
                themesSection
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.vertical, 20)
        }
        .background(MokoBackdrop())
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(theme.colors.headingText)

            Picker("Appearance", selection: Bindable(manager).appearanceMode) {
                ForEach(MokoAppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Choose whether MOKO follows your device or uses light or dark.")
                .font(.footnote)
                .foregroundStyle(theme.colors.secondaryText)
        }
        .padding(16)
        .background(theme.colors.cardSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.colors.cardBorder, lineWidth: 1)
        )
    }

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Font")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(theme.colors.headingText)

            Picker("Font", selection: Bindable(manager).fontOption) {
                ForEach(MokoFontOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Text("Pick a text style for MOKO.")
                .font(.footnote)
                .foregroundStyle(theme.colors.secondaryText)
        }
        .padding(16)
        .background(theme.colors.cardSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.colors.cardBorder, lineWidth: 1)
        )
    }

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(theme.colors.headingText)

            VStack(spacing: 12) {
                ForEach(MokoThemeID.allCases) { id in
                    themeRow(for: id)
                }
            }
        }
    }

    private func themeRow(for id: MokoThemeID) -> some View {
        let isSelected = manager.selectedTheme == id
        let preview = MokoThemePalette.colors(for: id, dark: theme.isDark)

        return Button {
            withAnimation(MokoScreenTheme.Motion.tap) {
                manager.selectedTheme = id
            }
        } label: {
            HStack(spacing: 14) {
                // Mini preview swatches showing the theme identity.
                HStack(spacing: 6) {
                    Circle().fill(preview.primaryButton).frame(width: 18, height: 18)
                    Circle().fill(preview.ctaAccent).frame(width: 18, height: 18)
                    Circle().fill(preview.missionAccent).frame(width: 18, height: 18)
                }
                .padding(10)
                .background(preview.backgroundGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(id.displayName)
                        .font(.system(size: 17, weight: .semibold, design: manager.fontOption.design))
                        .foregroundStyle(theme.colors.primaryText)
                    Text(id.subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.colors.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.colors.ctaAccent)
                        .font(.system(size: 22))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.colors.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? theme.colors.ctaAccent : theme.colors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
