import SwiftUI

/// The six MOKO visual identities.
enum MokoThemeID: String, CaseIterable, Codable, Identifiable {
    // This is the user's Default palette and the app's starting theme.
    case `default`
    case lavender
    case ocean
    case blossom
    case midnight
    case batman

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .lavender: return "Lavender"
        case .ocean: return "Ocean"
        case .blossom: return "Blossom"
        case .midnight: return "Midnight"
        case .batman: return "Batman"
        }
    }

    var subtitle: String {
        switch self {
        case .default: return "MOKO's original identity"
        case .lavender: return "Calm violet warmth"
        case .ocean: return "Cool and clear"
        case .blossom: return "Soft rose comfort"
        case .midnight: return "Deep indigo focus"
        case .batman: return "Dark minimal premium"
        }
    }
}

/// How the app should follow light/dark appearance.
enum MokoAppearanceMode: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// App-wide font style choice, stored with the theme settings.
enum MokoFontOption: String, CaseIterable, Codable, Identifiable {
    case rounded
    case standard
    case serif
    case monospaced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: return "Rounded"
        case .standard: return "Standard"
        case .serif: return "Serif"
        case .monospaced: return "Mono"
        }
    }

    var design: Font.Design {
        switch self {
        case .rounded: return .rounded
        case .standard: return .default
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}

/// A complete set of semantic colors for one theme + one appearance.
/// This is the single source of truth for app-owned UI colors.
struct MokoThemeColors {
    // Backgrounds
    let screenBackground: Color
    let primaryBackground: Color
    let secondaryBackground: Color
    let cardBackground: Color
    let elevatedCardBackground: Color
    let modalBackground: Color
    let sheetBackground: Color
    let navigationBackground: Color
    let tabBarBackground: Color

    // Typography
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let disabledText: Color
    let inverseText: Color
    let headingText: Color
    let buttonText: Color
    let captionText: Color

    // Interactive elements
    let primaryButton: Color
    let primaryButtonText: Color
    let secondaryButton: Color
    let secondaryButtonText: Color
    let destructiveButton: Color
    let disabledButton: Color
    let selectedControl: Color
    let unselectedControl: Color
    let focusColor: Color
    // Special accent for important CTA buttons and emphasis text (changes per theme).
    let ctaAccent: Color
    let ctaAccentText: Color

    // Cards and borders
    let cardSurface: Color
    let cardBorder: Color
    let cardShadow: Color
    let cardGlow: Color
    let divider: Color
    let separator: Color

    // Data visualization
    let chartPrimary: Color
    let chartSecondary: Color
    let chartTertiary: Color
    let chartQuaternary: Color
    let chartGrid: Color
    let chartLabel: Color
    let chartPositive: Color
    let chartNegative: Color

    // Status colors
    let success: Color
    let warning: Color
    let error: Color
    let information: Color

    // MOKO-specific colors
    let mokoMascotBackground: Color
    let mokoMascotAccent: Color
    let missionAccent: Color
    let questAccent: Color
    let growthAccent: Color
    let relaxAccent: Color
    let debriefAccent: Color
    let profileAccent: Color

    // Legacy/aux tokens kept for compatibility with existing V2 integrations
    let inputBackground: Color
    let placeholder: Color
    let icon: Color
    let selectedTab: Color
    let unselectedTab: Color
    let glow: Color
    let loadingBackground: Color
    let completionBackground: Color

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [screenBackground, secondaryBackground], startPoint: .top, endPoint: .bottom)
    }

    // Backward-compatible aliases
    var backgroundTop: Color { screenBackground }
    var backgroundBottom: Color { secondaryBackground }
    var surface: Color { cardSurface }
    var elevatedSurface: Color { elevatedCardBackground }
    var card: Color { cardSurface }
    var primary: Color { primaryButton }
    var secondary: Color { secondaryButtonText }
    var accent: Color { missionAccent }
    var textPrimary: Color { primaryText }
    var textSecondary: Color { secondaryText }
    var textOnPrimary: Color { primaryButtonText }
    var border: Color { cardBorder }
    var tabBar: Color { tabBarBackground }
    var navBar: Color { navigationBackground }
    var chart1: Color { chartPrimary }
    var chart2: Color { chartSecondary }
    var chart3: Color { chartTertiary }
    var chart4: Color { chartQuaternary }
    var questCard: Color { cardSurface }
    var shadow: Color { cardShadow }
}

/// The resolved theme: palette + appearance + semantic colors.
struct MokoResolvedTheme {
    let id: MokoThemeID
    let appearance: MokoAppearanceMode
    let isDark: Bool
    let colors: MokoThemeColors

    var preferredColorScheme: ColorScheme? { appearance.preferredColorScheme }
}

private struct MokoResolvedThemeKey: EnvironmentKey {
    static let defaultValue = MokoResolvedTheme(
        id: .default,
        appearance: .system,
        isDark: false,
        colors: MokoThemePalette.colors(for: .default, dark: false)
    )
}

extension EnvironmentValues {
    var mokoTheme: MokoResolvedTheme {
        get { self[MokoResolvedThemeKey.self] }
        set { self[MokoResolvedThemeKey.self] = newValue }
    }
}


// MARK: - Legacy compatibility (mapped to the active MOKO theme)

import UIKit

/// Backwards-compatible tokens used across existing screens.
/// Values are mapped to the active theme where possible so theme switching applies app-wide.
enum MokoTheme {
    @MainActor private static var c: MokoThemeColors { MokoThemeManager.shared.current.colors }

    // Core brand-ish colors mapped to semantic tokens
    static var forestGreen: Color { c.primaryButton }
    static var limeBackground: Color { c.screenBackground }
    static var limeSelected: Color { c.selectedControl.opacity(0.35) }
    static var titleBrown: Color { c.primaryText }
    static var bodyBrown: Color { c.secondaryText }

    static let white = Color.white
    static var warmNeutral: Color { c.elevatedCardBackground }
    static var dividerGray: Color { c.divider }

    static var primaryText: Color { c.primaryText }
    static var background: Color { c.screenBackground }
    static var cardBackground: Color { c.cardSurface }
    static var textPrimary: Color { c.primaryText }
    static var textSecondary: Color { c.secondaryText }
    static var textTertiary: Color { c.tertiaryText }
    static var borderLight: Color { c.cardBorder }

    // Haptic feedback helpers (kept for legacy call sites).
    static func playFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func playNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

/// Legacy primary button press style (kept for existing call sites).
struct MokoPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    MokoTheme.playFeedback(.light)
                }
            }
    }
}
