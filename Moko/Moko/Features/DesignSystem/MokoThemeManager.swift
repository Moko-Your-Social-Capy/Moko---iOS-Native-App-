import SwiftUI
import UIKit
import Observation

/// Holds the selected theme and appearance, resolves colors, and persists choices.
@Observable
@MainActor
final class MokoThemeManager {
    static let shared = MokoThemeManager()

    private enum Keys {
        static let theme = "moko.theme.selected"
        static let appearance = "moko.theme.appearance"
        static let font = "moko.theme.font"
    }

    var selectedTheme: MokoThemeID {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Keys.theme)
            refreshCurrent()
        }
    }

    var appearanceMode: MokoAppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearance)
            refreshCurrent()
        }
    }

    // Selected font style applied across MOKO text styles.
    var fontOption: MokoFontOption {
        didSet {
            UserDefaults.standard.set(fontOption.rawValue, forKey: Keys.font)
        }
    }

    /// Last known system color scheme, updated by the root modifier.
    private(set) var systemScheme: ColorScheme = .light

    /// The currently resolved theme (used by legacy static tokens).
    private(set) var current: MokoResolvedTheme

    private init() {
        let storedRaw = UserDefaults.standard.string(forKey: Keys.theme) ?? MokoThemeID.default.rawValue
        let themeRaw: String
        // Back-compat: older builds saved "forest" for the original theme; removed "sunset" falls back to default.
        if storedRaw == "forest" || storedRaw == "sunset" {
            themeRaw = MokoThemeID.default.rawValue
        } else {
            themeRaw = storedRaw
        }
        let appearanceRaw = UserDefaults.standard.string(forKey: Keys.appearance) ?? MokoAppearanceMode.system.rawValue
        let fontRaw = UserDefaults.standard.string(forKey: Keys.font) ?? MokoFontOption.rounded.rawValue
        let theme = MokoThemeID(rawValue: themeRaw) ?? .default
        let appearance = MokoAppearanceMode(rawValue: appearanceRaw) ?? .system
        let font = MokoFontOption(rawValue: fontRaw) ?? .rounded
        self.selectedTheme = theme
        self.appearanceMode = appearance
        self.fontOption = font
        // Resolve immediately for the stored preference; system scheme synced by root.
        let isDark: Bool
        switch appearance {
        case .system: isDark = false
        case .light: isDark = false
        case .dark: isDark = true
        }
        self.current = MokoResolvedTheme(
            id: theme,
            appearance: appearance,
            isDark: isDark,
            colors: MokoThemePalette.colors(for: theme, dark: isDark)
        )
    }

    func updateSystemScheme(_ scheme: ColorScheme) {
        if systemScheme != scheme {
            systemScheme = scheme
        }
        refreshCurrent()
    }

    func sync(systemScheme: ColorScheme) -> MokoResolvedTheme {
        self.systemScheme = systemScheme
        let resolved = resolved(systemScheme: systemScheme)
        current = resolved
        applySystemControlAppearance(for: resolved)
        return resolved
    }

    private func refreshCurrent() {
        current = resolved(systemScheme: systemScheme)
        applySystemControlAppearance(for: current)
    }

    /// Keeps UIKit segmented pickers readable in light/dark and aligned to theme tokens.
    func applySystemControlAppearance(for theme: MokoResolvedTheme) {
        let appearance = UISegmentedControl.appearance()
        let selectedBG = UIColor(theme.colors.selectedControl)
        let normalText = UIColor(theme.colors.primaryText)
        let selectedText = UIColor(theme.colors.primaryButtonText)
        let unselectedBG = UIColor(theme.colors.elevatedCardBackground)

        appearance.selectedSegmentTintColor = selectedBG
        appearance.backgroundColor = unselectedBG
        appearance.setTitleTextAttributes([
            .foregroundColor: normalText,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .normal)
        appearance.setTitleTextAttributes([
            .foregroundColor: selectedText,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
    }

    func resolved(systemScheme: ColorScheme) -> MokoResolvedTheme {
        let isDark: Bool
        switch appearanceMode {
        case .system: isDark = (systemScheme == .dark)
        case .light: isDark = false
        case .dark: isDark = true
        }
        let colors = MokoThemePalette.colors(for: selectedTheme, dark: isDark)
        return MokoResolvedTheme(id: selectedTheme, appearance: appearanceMode, isDark: isDark, colors: colors)
    }
}

/// Applies the resolved MOKO theme to the view tree and keeps it in sync.
struct MokoThemeRootModifier: ViewModifier {
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let manager = MokoThemeManager.shared
        // Synchronously sync so legacy static tokens match the active appearance this render.
        let resolved = manager.sync(systemScheme: systemScheme)
        content
            .environment(\.mokoTheme, resolved)
            .environment(manager)
            .preferredColorScheme(resolved.preferredColorScheme)
            .tint(resolved.colors.primaryButton)
            .onChange(of: systemScheme) { _, newValue in
                manager.updateSystemScheme(newValue)
            }
    }
}

extension View {
    func mokoThemeRoot() -> some View { modifier(MokoThemeRootModifier()) }
}
