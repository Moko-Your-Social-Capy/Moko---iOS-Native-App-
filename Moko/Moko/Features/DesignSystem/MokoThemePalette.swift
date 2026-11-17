import SwiftUI

/// Centralized MOKO theme palettes.
///
/// MOKO theme IDs (unchanged): Default, Lavender, Ocean, Blossom, Midnight, Batman.
/// daisyUI 5 is used as a semantic color-role reference only (no runtime dependency).
/// Source: https://colorvio.com/daisyui-colors (extracted semantic hex values).
///
/// daisyUI reference pairs mapped to MOKO identities:
/// - Default: preserved as original MOKO palette (not changed).
/// - Lavender: cupcake (light) + dracula (dark) — violet adaptation.
/// - Ocean: nord (light) + dim (dark).
/// - Blossom: winter (light) + night (dark).
/// - Midnight: corporate (light) + business (dark) — deep indigo adaptation.
/// - Batman: emerald (light) + forest (dark) references for neutrals/status only — Batman identity preserved.
/// MOKO overrides: Light cards are always pure white (#FFFFFF); Dark cards are raised dark surfaces.
/// Quest/mission accents remain semantic and readable (purple/teal/blue per theme identity), separate from Profile where applicable.
enum MokoThemePalette {

    static func colors(for theme: MokoThemeID, dark: Bool) -> MokoThemeColors {
        dark ? darkColors(for: theme) : lightColors(for: theme)
    }

    // MARK: - Light

    static func lightColors(for theme: MokoThemeID) -> MokoThemeColors {
        switch theme {
        case .default:
            // Default light: gradient from green to white, white cards, themed accents.
            return MokoThemeColors(
                screenBackground: Color(hex: 0xCBE6D3),
                primaryBackground: Color(hex: 0xCBE6D3),
                secondaryBackground: Color(hex: 0xFFFFFF),
                cardBackground: Color(hex: 0xFFFFFF),
                elevatedCardBackground: Color(hex: 0xFFFFFF),
                modalBackground: Color(hex: 0xFFFFFF),
                sheetBackground: Color(hex: 0xFFFFFF),
                navigationBackground: Color(hex: 0xCBE6D3),
                tabBarBackground: Color(hex: 0xFFFFFF),
                primaryText: Color(hex: 0x1E2D23),
                secondaryText: Color(hex: 0x5E6D63),
                tertiaryText: Color(hex: 0x4A5A50),
                disabledText: Color(hex: 0x8A9A90),
                inverseText: .white,
                headingText: Color(hex: 0x1E2D23),
                buttonText: .white,
                captionText: Color(hex: 0x5E6D63),
                primaryButton: Color(hex: 0x2F6E4A),
                primaryButtonText: .white,
                secondaryButton: Color(hex: 0xE8F5EB),
                secondaryButtonText: Color(hex: 0x2F6E4A),
                destructiveButton: Color(hex: 0xB9583F),
                disabledButton: Color(hex: 0xE8F5EB),
                selectedControl: Color(hex: 0x2F6E4A),
                unselectedControl: Color(hex: 0x5E6D63),
                focusColor: Color(hex: 0x2F6E4A),
                ctaAccent: Color(hex: 0x2F6E4A),
                ctaAccentText: .white,
                cardSurface: Color(hex: 0xFFFFFF),
                cardBorder: Color(hex: 0xD7E6DB),
                cardShadow: Color(hex: 0x1E2D23),
                cardGlow: Color(hex: 0x2F6E4A),
                divider: Color(hex: 0xDCE8DF),
                separator: Color(hex: 0xD7E6DB),
                chartPrimary: Color(hex: 0x2F6E4A),
                chartSecondary: Color(hex: 0x5F7E68),
                chartTertiary: Color(hex: 0xE3A72F),
                chartQuaternary: Color(hex: 0x3B9A8C),
                chartGrid: Color(hex: 0xD7E6DB),
                chartLabel: Color(hex: 0x5E6D63),
                chartPositive: Color(hex: 0x3D8B5A),
                chartNegative: Color(hex: 0xB9583F),
                success: Color(hex: 0x3D8B5A),
                warning: Color(hex: 0xD97706),
                error: Color(hex: 0xB9583F),
                information: Color(hex: 0x2F6E4A),
                mokoMascotBackground: Color(hex: 0xE8F5EB),
                mokoMascotAccent: Color(hex: 0x2F6E4A),
                missionAccent: Color(hex: 0xE3A72F),
                questAccent: Color(hex: 0x2F6E4A),
                growthAccent: Color(hex: 0x5F7E68),
                relaxAccent: Color(hex: 0x3B9A8C),
                debriefAccent: Color(hex: 0x3D8B5A),
                profileAccent: Color(hex: 0x2F6E4A),
                inputBackground: Color(hex: 0xF4FAF6),
                placeholder: Color(hex: 0x7A8A80),
                icon: Color(hex: 0x2F6E4A),
                selectedTab: Color(hex: 0x2F6E4A),
                unselectedTab: Color(hex: 0x5E6D63),
                glow: Color(hex: 0x2F6E4A),
                loadingBackground: Color(hex: 0xCBE6D3),
                completionBackground: Color(hex: 0xFFFFFF)
            )
        case .lavender:
            // daisyUI ref: cupcake (light) + dracula (dark) semantic roles, rendered as calm violet.
            return make(
                screenBackground: 0xFAF7F5, primaryBackground: 0xFAF7F5, secondaryBackground: 0xEFEAE6,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFFFFF, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xFAF7F5, tabBarBackground: 0xFFFFFF,
                primaryText: 0x291334, secondaryText: 0x5E5873, tertiaryText: 0x8E88A3, disabledText: 0xAEA8BF, inverseText: 0xFFFFFF,
                headingText: 0x291334, buttonText: 0xFFFFFF, captionText: 0x5E5873,
                primaryButton: 0x7C3AED, primaryButtonText: 0xFFFFFF, secondaryButton: 0xEFEAE6, secondaryButtonText: 0x7C3AED,
                destructiveButton: 0xFF5555, disabledButton: 0xE7E2DF, selectedControl: 0x7C3AED, unselectedControl: 0x8E88A3, focusColor: 0xBD93F9,
                ctaAccent: 0x7C3AED, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xE7E2DF, cardShadow: 0x291334, cardGlow: 0xBD93F9, divider: 0xEFEAE6, separator: 0xE7E2DF,
                chartPrimary: 0x7C3AED, chartSecondary: 0xBD93F9, chartTertiary: 0xFF79C6, chartQuaternary: 0x6272A4, chartGrid: 0xE7E2DF, chartLabel: 0x5E5873, chartPositive: 0x00BA7B, chartNegative: 0xFF5555,
                success: 0x00BA7B, warning: 0xEEAF00, error: 0xFF5555, information: 0x00A4F2,
                mokoMascotBackground: 0xEFEAE6, mokoMascotAccent: 0x7C3AED, missionAccent: 0xBD93F9, questAccent: 0x7C3AED, growthAccent: 0xBD93F9, relaxAccent: 0x6272A4, debriefAccent: 0x7C3AED, profileAccent: 0x7C3AED,
                inputBackground: 0xFAF7F5, placeholder: 0x8E88A3, icon: 0x7C3AED, selectedTab: 0x7C3AED, unselectedTab: 0x8E88A3, glow: 0xBD93F9,
                loadingBackground: 0xFAF7F5, completionBackground: 0xFFFFFF, dark: false
            )

        case .ocean:
            // daisyUI ref: nord (light). base-100 #ECEFF4, base-200 #E5E9F0, base-300 #D8DEE9, base-content #2E3440,
            // primary #5E81AC, secondary #81A1C1, accent #88C0D0, info #B48EAD, success #A3BE8D, warning #EBCB8B, error #BF616A.
            return make(
                screenBackground: 0xECEFF4, primaryBackground: 0xECEFF4, secondaryBackground: 0xE5E9F0,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFFFFF, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xECEFF4, tabBarBackground: 0xFFFFFF,
                primaryText: 0x2E3440, secondaryText: 0x4C566A, tertiaryText: 0x7B88A1, disabledText: 0xA3ABB8, inverseText: 0xECEFF4,
                headingText: 0x2E3440, buttonText: 0xECEFF4, captionText: 0x4C566A,
                primaryButton: 0x5E81AC, primaryButtonText: 0xECEFF4, secondaryButton: 0xE5E9F0, secondaryButtonText: 0x5E81AC,
                destructiveButton: 0xBF616A, disabledButton: 0xD8DEE9, selectedControl: 0x5E81AC, unselectedControl: 0x4C566A, focusColor: 0x88C0D0,
                ctaAccent: 0x5E81AC, ctaAccentText: 0xECEFF4,
                cardSurface: 0xFFFFFF, cardBorder: 0xD8DEE9, cardShadow: 0x2E3440, cardGlow: 0x88C0D0, divider: 0xE5E9F0, separator: 0xD8DEE9,
                chartPrimary: 0x5E81AC, chartSecondary: 0x88C0D0, chartTertiary: 0x81A1C1, chartQuaternary: 0xB48EAD, chartGrid: 0xD8DEE9, chartLabel: 0x4C566A, chartPositive: 0xA3BE8D, chartNegative: 0xBF616A,
                success: 0xA3BE8D, warning: 0xEBCB8B, error: 0xBF616A, information: 0xB48EAD,
                mokoMascotBackground: 0xE5E9F0, mokoMascotAccent: 0x5E81AC, missionAccent: 0x88C0D0, questAccent: 0x5E81AC, growthAccent: 0xA3BE8D, relaxAccent: 0x81A1C1, debriefAccent: 0x5E81AC, profileAccent: 0x5E81AC,
                inputBackground: 0xF5F7FA, placeholder: 0x7B88A1, icon: 0x5E81AC, selectedTab: 0x5E81AC, unselectedTab: 0x4C566A, glow: 0x88C0D0,
                loadingBackground: 0xECEFF4, completionBackground: 0xFFFFFF, dark: false
            )

        case .blossom:
            // daisyUI ref: winter (light). base-100 #FFFFFF, base-200 #F2F7FE, base-300 #E3E9F4, primary #0069FF,
            // secondary #463AA2, accent #C148AC, info #94E7FB, success #81CFD1, warning #EFD7BC, error #E58B8B.
            // Adapted to soft rose/blossom identity while keeping semantic contrast.
            return make(
                screenBackground: 0xFFF5F7, primaryBackground: 0xFFF5F7, secondaryBackground: 0xF2F7FE,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFFFFF, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xFFF5F7, tabBarBackground: 0xFFFFFF,
                primaryText: 0x021431, secondaryText: 0x463AA2, tertiaryText: 0x7A6FB3, disabledText: 0xA9A3C8, inverseText: 0xFFFFFF,
                headingText: 0x021431, buttonText: 0xFFFFFF, captionText: 0x463AA2,
                primaryButton: 0xC148AC, primaryButtonText: 0xFFFFFF, secondaryButton: 0xF2F7FE, secondaryButtonText: 0x463AA2,
                destructiveButton: 0xE58B8B, disabledButton: 0xE3E9F4, selectedControl: 0xC148AC, unselectedControl: 0x463AA2, focusColor: 0x0069FF,
                ctaAccent: 0xC148AC, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xE3E9F4, cardShadow: 0x021431, cardGlow: 0xC148AC, divider: 0xF2F7FE, separator: 0xE3E9F4,
                chartPrimary: 0xC148AC, chartSecondary: 0x0069FF, chartTertiary: 0x463AA2, chartQuaternary: 0x81CFD1, chartGrid: 0xE3E9F4, chartLabel: 0x463AA2, chartPositive: 0x81CFD1, chartNegative: 0xE58B8B,
                success: 0x81CFD1, warning: 0xEFD7BC, error: 0xE58B8B, information: 0x0069FF,
                mokoMascotBackground: 0xF2F7FE, mokoMascotAccent: 0xC148AC, missionAccent: 0x0069FF, questAccent: 0xC148AC, growthAccent: 0x81CFD1, relaxAccent: 0x463AA2, debriefAccent: 0xC148AC, profileAccent: 0xC148AC,
                inputBackground: 0xF7FAFF, placeholder: 0x7A6FB3, icon: 0xC148AC, selectedTab: 0xC148AC, unselectedTab: 0x463AA2, glow: 0xC148AC,
                loadingBackground: 0xFFF5F7, completionBackground: 0xFFFFFF, dark: false
            )

        case .midnight:
            // daisyUI ref: corporate (light). base-100 #FFFFFF, base-200 #E8E8E8, base-300 #D1D1D1, primary #0082CE,
            // secondary #61738D, accent #009689, info #0090B5, success #00A43B, warning #FDC700, error #FF6266.
            // Adapted to deep indigo "midnight" identity in light mode.
            return make(
                screenBackground: 0xF4F6FB, primaryBackground: 0xF4F6FB, secondaryBackground: 0xE8E8E8,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFFFFF, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xF4F6FB, tabBarBackground: 0xFFFFFF,
                primaryText: 0x18181B, secondaryText: 0x61738D, tertiaryText: 0x8590AD, disabledText: 0xA8B0C7, inverseText: 0xFFFFFF,
                headingText: 0x18181B, buttonText: 0xFFFFFF, captionText: 0x61738D,
                primaryButton: 0x3949AB, primaryButtonText: 0xFFFFFF, secondaryButton: 0xE8E8E8, secondaryButtonText: 0x3949AB,
                destructiveButton: 0xFF6266, disabledButton: 0xD1D1D1, selectedControl: 0x3949AB, unselectedControl: 0x61738D, focusColor: 0x0082CE,
                ctaAccent: 0x3949AB, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xD1D1D1, cardShadow: 0x18181B, cardGlow: 0x0082CE, divider: 0xE8E8E8, separator: 0xD1D1D1,
                chartPrimary: 0x3949AB, chartSecondary: 0x0082CE, chartTertiary: 0x009689, chartQuaternary: 0x61738D, chartGrid: 0xD1D1D1, chartLabel: 0x61738D, chartPositive: 0x00A43B, chartNegative: 0xFF6266,
                success: 0x00A43B, warning: 0xFDC700, error: 0xFF6266, information: 0x0090B5,
                mokoMascotBackground: 0xE8E8E8, mokoMascotAccent: 0x3949AB, missionAccent: 0x0082CE, questAccent: 0x3949AB, growthAccent: 0x009689, relaxAccent: 0x61738D, debriefAccent: 0x3949AB, profileAccent: 0x3949AB,
                inputBackground: 0xF7F8FC, placeholder: 0x8590AD, icon: 0x3949AB, selectedTab: 0x3949AB, unselectedTab: 0x61738D, glow: 0x0082CE,
                loadingBackground: 0xF4F6FB, completionBackground: 0xFFFFFF, dark: false
            )

        case .batman:
            // Batman identity preserved (existing approved palette), not replaced by daisyUI.
            // daisyUI emerald referenced only conceptually for light-neutral balance; cards remain white.
            return make(
                screenBackground: 0xE6DDD6, primaryBackground: 0xE6DDD6, secondaryBackground: 0xF2ECE6,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFFFFF, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xE6DDD6, tabBarBackground: 0xFFFFFF,
                primaryText: 0x1C1713, secondaryText: 0x4A4138, tertiaryText: 0x6E6358, disabledText: 0x9A8F84, inverseText: 0xF2F2F2,
                headingText: 0x14110E, buttonText: 0xFFFFFF, captionText: 0x4A4138,
                primaryButton: 0x2D69E0, primaryButtonText: 0xFFFFFF, secondaryButton: 0xE7DED4, secondaryButtonText: 0x008F8A,
                destructiveButton: 0xEC6746, disabledButton: 0xD8CFC6, selectedControl: 0x008F8A, unselectedControl: 0x6E6358, focusColor: 0x00A39E,
                ctaAccent: 0x008F8A, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xD2C6BC, cardShadow: 0x1C1713, cardGlow: 0x00A39E, divider: 0xD8CDC3, separator: 0xD2C6BC,
                chartPrimary: 0x008F8A, chartSecondary: 0x2D69E0, chartTertiary: 0xEC6746, chartQuaternary: 0x4A4138, chartGrid: 0xD8CDC3, chartLabel: 0x4A4138, chartPositive: 0x008F8A, chartNegative: 0xEC6746,
                success: 0x00A96E, warning: 0xFFBE00, error: 0xEC6746, information: 0x2D69E0,
                mokoMascotBackground: 0xE9E1D8, mokoMascotAccent: 0x008F8A, missionAccent: 0x00A39E, questAccent: 0x2D69E0, growthAccent: 0x008F8A, relaxAccent: 0x6E6358, debriefAccent: 0xEC6746, profileAccent: 0x008F8A,
                inputBackground: 0xF5F5F5, placeholder: 0x7A6F64, icon: 0x1C1713, selectedTab: 0x008F8A, unselectedTab: 0x6E6358, glow: 0x00A39E,
                loadingBackground: 0xE6DDD6, completionBackground: 0xFFFFFF, dark: false
            )
        }
    }

    // MARK: - Dark

    static func darkColors(for theme: MokoThemeID) -> MokoThemeColors {
        switch theme {
        case .default:
            // Dark counterpart for Default palette (deep greens, readable surfaces).
            return MokoThemeColors(
                screenBackground: Color(hex: 0x121A15),
                primaryBackground: Color(hex: 0x121A15),
                secondaryBackground: Color(hex: 0x1C2A21),
                cardBackground: Color(hex: 0x1E2A22),
                elevatedCardBackground: Color(hex: 0x243228),
                modalBackground: Color(hex: 0x1E2A22),
                sheetBackground: Color(hex: 0x18221B),
                navigationBackground: Color(hex: 0x121A15),
                tabBarBackground: Color(hex: 0x18221B),
                primaryText: Color(hex: 0xEAF4EE),
                secondaryText: Color(hex: 0xB9C8BE),
                tertiaryText: Color(hex: 0x93A79A),
                disabledText: Color(hex: 0x6E8074),
                inverseText: Color(hex: 0x121A15),
                headingText: Color(hex: 0xF4FBF7),
                buttonText: Color(hex: 0x0F1712),
                captionText: Color(hex: 0xB9C8BE),
                primaryButton: Color(hex: 0x5FAF7A),
                primaryButtonText: Color(hex: 0x0F1712),
                secondaryButton: Color(hex: 0x243228),
                secondaryButtonText: Color(hex: 0x8FD1A6),
                destructiveButton: Color(hex: 0xD07A5E),
                disabledButton: Color(hex: 0x2A3830),
                selectedControl: Color(hex: 0x5FAF7A),
                unselectedControl: Color(hex: 0x7F9486),
                focusColor: Color(hex: 0x5FAF7A),
                ctaAccent: Color(hex: 0x3B9A8C),
                ctaAccentText: Color(hex: 0x0F1712),
                cardSurface: Color(hex: 0x1E2A22),
                cardBorder: Color(hex: 0x2D3C33),
                cardShadow: .black,
                cardGlow: Color(hex: 0x5FAF7A),
                divider: Color(hex: 0x2A3830),
                separator: Color(hex: 0x2D3C33),
                chartPrimary: Color(hex: 0x5FAF7A),
                chartSecondary: Color(hex: 0x3B9A8C),
                chartTertiary: Color(hex: 0xE3A72F),
                chartQuaternary: Color(hex: 0x8FD1A6),
                chartGrid: Color(hex: 0x2D3C33),
                chartLabel: Color(hex: 0xB9C8BE),
                chartPositive: Color(hex: 0x5FAF7A),
                chartNegative: Color(hex: 0xD07A5E),
                success: Color(hex: 0x5FAF7A),
                warning: Color(hex: 0xE3A72F),
                error: Color(hex: 0xD07A5E),
                information: Color(hex: 0x3B9A8C),
                mokoMascotBackground: Color(hex: 0x223027),
                mokoMascotAccent: Color(hex: 0x5FAF7A),
                missionAccent: Color(hex: 0xE3A72F),
                questAccent: Color(hex: 0x5FAF7A),
                growthAccent: Color(hex: 0x3B9A8C),
                relaxAccent: Color(hex: 0x8FD1A6),
                debriefAccent: Color(hex: 0x5FAF7A),
                profileAccent: Color(hex: 0x3B9A8C),
                inputBackground: Color(hex: 0x223027),
                placeholder: Color(hex: 0x7F9486),
                icon: Color(hex: 0x8FD1A6),
                selectedTab: Color(hex: 0x5FAF7A),
                unselectedTab: Color(hex: 0x7F9486),
                glow: Color(hex: 0x5FAF7A),
                loadingBackground: Color(hex: 0x121A15),
                completionBackground: Color(hex: 0x18221B)
            )
        case .lavender:
            // daisyUI ref: dracula (dark).
            return make(
                screenBackground: 0x1F202A, primaryBackground: 0x1F202A, secondaryBackground: 0x232530,
                cardBackground: 0x282A36, elevatedCardBackground: 0x303241, modalBackground: 0x282A36, sheetBackground: 0x232530,
                navigationBackground: 0x1F202A, tabBarBackground: 0x232530,
                primaryText: 0xF8F8F2, secondaryText: 0xC9CAD3, tertiaryText: 0x9AA0B4, disabledText: 0x6E748A, inverseText: 0x282A36,
                headingText: 0xF8F8F2, buttonText: 0x282A36, captionText: 0xC9CAD3,
                primaryButton: 0xBD93F9, primaryButtonText: 0x282A36, secondaryButton: 0x303241, secondaryButtonText: 0xFF79C6,
                destructiveButton: 0xFF5555, disabledButton: 0x343746, selectedControl: 0xBD93F9, unselectedControl: 0x9AA0B4, focusColor: 0x8BE9FD,
                ctaAccent: 0xBD93F9, ctaAccentText: 0x282A36,
                cardSurface: 0x282A36, cardBorder: 0x414558, cardShadow: 0x000000, cardGlow: 0xBD93F9, divider: 0x343746, separator: 0x414558,
                chartPrimary: 0xBD93F9, chartSecondary: 0xFF79C6, chartTertiary: 0xFFB86C, chartQuaternary: 0x8BE9FD, chartGrid: 0x414558, chartLabel: 0xC9CAD3, chartPositive: 0x51FA7B, chartNegative: 0xFF5555,
                success: 0x51FA7B, warning: 0xF1FA8C, error: 0xFF5555, information: 0x8BE9FD,
                mokoMascotBackground: 0x303241, mokoMascotAccent: 0xBD93F9, missionAccent: 0xFF79C6, questAccent: 0xBD93F9, growthAccent: 0x51FA7B, relaxAccent: 0x8BE9FD, debriefAccent: 0xBD93F9, profileAccent: 0xBD93F9,
                inputBackground: 0x303241, placeholder: 0x9AA0B4, icon: 0xF8F8F2, selectedTab: 0xBD93F9, unselectedTab: 0x9AA0B4, glow: 0xBD93F9,
                loadingBackground: 0x1F202A, completionBackground: 0x232530, dark: true
            )

        case .ocean:
            // daisyUI ref: dim (dark). base-100 #2A303C, base-200 #242933, base-300 #20252E, base-content #B5BFD9,
            // primary #9FE88D, secondary #FF7D5D, accent #C792E9, info #28EBFF, success #62EFBD, warning #EFD057, error #FFAE9B.
            // Adapted to ocean blues/teals with dim surfaces.
            return make(
                screenBackground: 0x20252E, primaryBackground: 0x20252E, secondaryBackground: 0x242933,
                cardBackground: 0x2A303C, elevatedCardBackground: 0x313846, modalBackground: 0x2A303C, sheetBackground: 0x242933,
                navigationBackground: 0x20252E, tabBarBackground: 0x242933,
                primaryText: 0xE8EEF9, secondaryText: 0xB5BFD9, tertiaryText: 0x8F9AB8, disabledText: 0x6B758F, inverseText: 0x20252E,
                headingText: 0xF4F7FF, buttonText: 0x20252E, captionText: 0xB5BFD9,
                primaryButton: 0x28EBFF, primaryButtonText: 0x20252E, secondaryButton: 0x313846, secondaryButtonText: 0x62EFBD,
                destructiveButton: 0xFFAE9B, disabledButton: 0x343B4A, selectedControl: 0x28EBFF, unselectedControl: 0x8F9AB8, focusColor: 0x28EBFF,
                ctaAccent: 0x28EBFF, ctaAccentText: 0x20252E,
                cardSurface: 0x2A303C, cardBorder: 0x3A4252, cardShadow: 0x000000, cardGlow: 0x28EBFF, divider: 0x343B4A, separator: 0x3A4252,
                chartPrimary: 0x28EBFF, chartSecondary: 0x62EFBD, chartTertiary: 0x9FE88D, chartQuaternary: 0xC792E9, chartGrid: 0x3A4252, chartLabel: 0xB5BFD9, chartPositive: 0x62EFBD, chartNegative: 0xFFAE9B,
                success: 0x62EFBD, warning: 0xEFD057, error: 0xFFAE9B, information: 0x28EBFF,
                mokoMascotBackground: 0x313846, mokoMascotAccent: 0x28EBFF, missionAccent: 0x62EFBD, questAccent: 0x28EBFF, growthAccent: 0x62EFBD, relaxAccent: 0x9FE88D, debriefAccent: 0x28EBFF, profileAccent: 0x28EBFF,
                inputBackground: 0x313846, placeholder: 0x8F9AB8, icon: 0xE8EEF9, selectedTab: 0x28EBFF, unselectedTab: 0x8F9AB8, glow: 0x28EBFF,
                loadingBackground: 0x20252E, completionBackground: 0x242933, dark: true
            )

        case .blossom:
            // daisyUI ref: night (dark). base-100 #0F172A, base-200 #0C1425, base-300 #0A1120, primary #3ABDF7,
            // secondary #818CF8, accent #F471B5, info #0CA5E9, success #2FD4BF, warning #F4BF51, error #FB7085.
            // Adapted to blossom rose on night surfaces.
            return make(
                screenBackground: 0x0A1120, primaryBackground: 0x0A1120, secondaryBackground: 0x0C1425,
                cardBackground: 0x0F172A, elevatedCardBackground: 0x162033, modalBackground: 0x0F172A, sheetBackground: 0x0C1425,
                navigationBackground: 0x0A1120, tabBarBackground: 0x0C1425,
                primaryText: 0xEAF2FF, secondaryText: 0xB8C4D9, tertiaryText: 0x8B97B0, disabledText: 0x667289, inverseText: 0x0A1120,
                headingText: 0xF5FAFF, buttonText: 0x0A1120, captionText: 0xB8C4D9,
                primaryButton: 0xF471B5, primaryButtonText: 0x0A1120, secondaryButton: 0x162033, secondaryButtonText: 0x818CF8,
                destructiveButton: 0xFB7085, disabledButton: 0x1C2740, selectedControl: 0xF471B5, unselectedControl: 0x8B97B0, focusColor: 0x3ABDF7,
                ctaAccent: 0xF471B5, ctaAccentText: 0x0A1120,
                cardSurface: 0x0F172A, cardBorder: 0x24324A, cardShadow: 0x000000, cardGlow: 0xF471B5, divider: 0x1C2740, separator: 0x24324A,
                chartPrimary: 0xF471B5, chartSecondary: 0x818CF8, chartTertiary: 0x3ABDF7, chartQuaternary: 0x2FD4BF, chartGrid: 0x24324A, chartLabel: 0xB8C4D9, chartPositive: 0x2FD4BF, chartNegative: 0xFB7085,
                success: 0x2FD4BF, warning: 0xF4BF51, error: 0xFB7085, information: 0x0CA5E9,
                mokoMascotBackground: 0x162033, mokoMascotAccent: 0xF471B5, missionAccent: 0x3ABDF7, questAccent: 0xF471B5, growthAccent: 0x2FD4BF, relaxAccent: 0x818CF8, debriefAccent: 0xF471B5, profileAccent: 0xF471B5,
                inputBackground: 0x162033, placeholder: 0x8B97B0, icon: 0xEAF2FF, selectedTab: 0xF471B5, unselectedTab: 0x8B97B0, glow: 0xF471B5,
                loadingBackground: 0x0A1120, completionBackground: 0x0C1425, dark: true
            )

        case .midnight:
            // daisyUI ref: business (dark). base-100 #202020, base-200 #1C1C1C, base-300 #181818, primary #1C4E80,
            // secondary #7C909A, accent #EA6947, info #0291D5, success #6BB187, warning #DBAE5A, error #AC3E31.
            // Adapted to midnight indigo with business neutrals.
            return make(
                screenBackground: 0x181818, primaryBackground: 0x181818, secondaryBackground: 0x1C1C1C,
                cardBackground: 0x202020, elevatedCardBackground: 0x262626, modalBackground: 0x202020, sheetBackground: 0x1C1C1C,
                navigationBackground: 0x181818, tabBarBackground: 0x1C1C1C,
                primaryText: 0xE6EAF0, secondaryText: 0xA7B4BD, tertiaryText: 0x87939C, disabledText: 0x626D75, inverseText: 0x181818,
                headingText: 0xF5F7FA, buttonText: 0xFFFFFF, captionText: 0xA7B4BD,
                primaryButton: 0x4C7DFF, primaryButtonText: 0x0E1118, secondaryButton: 0x262626, secondaryButtonText: 0x0291D5,
                destructiveButton: 0xAC3E31, disabledButton: 0x2C2C2C, selectedControl: 0x4C7DFF, unselectedControl: 0x7C909A, focusColor: 0x0291D5,
                ctaAccent: 0x4C7DFF, ctaAccentText: 0x0E1118,
                cardSurface: 0x202020, cardBorder: 0x333333, cardShadow: 0x000000, cardGlow: 0x0291D5, divider: 0x2C2C2C, separator: 0x333333,
                chartPrimary: 0x4C7DFF, chartSecondary: 0x0291D5, chartTertiary: 0x6BB187, chartQuaternary: 0xEA6947, chartGrid: 0x333333, chartLabel: 0xA7B4BD, chartPositive: 0x6BB187, chartNegative: 0xAC3E31,
                success: 0x6BB187, warning: 0xDBAE5A, error: 0xAC3E31, information: 0x0291D5,
                mokoMascotBackground: 0x262626, mokoMascotAccent: 0x4C7DFF, missionAccent: 0x0291D5, questAccent: 0x4C7DFF, growthAccent: 0x6BB187, relaxAccent: 0x7C909A, debriefAccent: 0x4C7DFF, profileAccent: 0x4C7DFF,
                inputBackground: 0x262626, placeholder: 0x87939C, icon: 0xE6EAF0, selectedTab: 0x4C7DFF, unselectedTab: 0x87939C, glow: 0x0291D5,
                loadingBackground: 0x181818, completionBackground: 0x1C1C1C, dark: true
            )

        case .batman:
            // Batman identity preserved (existing approved palette). daisyUI forest dark neutrals referenced only for contrast;
            // cards remain raised dark surfaces (not white).
            return make(
                screenBackground: 0x0D0D0D, primaryBackground: 0x0D0D0D, secondaryBackground: 0x161212,
                cardBackground: 0x1B1717, elevatedCardBackground: 0x222222, modalBackground: 0x1B1717, sheetBackground: 0x121212,
                navigationBackground: 0x0D0D0D, tabBarBackground: 0x121212,
                primaryText: 0xF5F5F5, secondaryText: 0xC4C4C4, tertiaryText: 0x999999, disabledText: 0x6B6B6B, inverseText: 0x0D0D0D,
                headingText: 0xF5F5F5, buttonText: 0xFFFFFF, captionText: 0xC4C4C4,
                primaryButton: 0x2D69E0, primaryButtonText: 0xFFFFFF, secondaryButton: 0x222222, secondaryButtonText: 0x00CEC8,
                destructiveButton: 0xEC6746, disabledButton: 0x333333, selectedControl: 0x00CEC8, unselectedControl: 0x7A7A7A, focusColor: 0x00CEC8,
                ctaAccent: 0x00CEC8, ctaAccentText: 0x0D0D0D,
                cardSurface: 0x1B1717, cardBorder: 0x383838, cardShadow: 0x000000, cardGlow: 0x00CEC8, divider: 0x2E2E2E, separator: 0x383838,
                chartPrimary: 0x00CEC8, chartSecondary: 0x2D69E0, chartTertiary: 0xEC6746, chartQuaternary: 0x1FB854, chartGrid: 0x383838, chartLabel: 0xC4C4C4, chartPositive: 0x1FB854, chartNegative: 0xEC6746,
                success: 0x00A96E, warning: 0xFFBE00, error: 0xEC6746, information: 0x2D69E0,
                mokoMascotBackground: 0x222222, mokoMascotAccent: 0x00CEC8, missionAccent: 0x00CEC8, questAccent: 0x2D69E0, growthAccent: 0x00CEC8, relaxAccent: 0x7A7A7A, debriefAccent: 0xEC6746, profileAccent: 0x00CEC8,
                inputBackground: 0x222222, placeholder: 0x999999, icon: 0xF5F5F5, selectedTab: 0x00CEC8, unselectedTab: 0x7A7A7A, glow: 0x00CEC8,
                loadingBackground: 0x0D0D0D, completionBackground: 0x121212, dark: true
            )
        }
    }

    private static func make(
        screenBackground: UInt32, primaryBackground: UInt32, secondaryBackground: UInt32,
        cardBackground: UInt32, elevatedCardBackground: UInt32, modalBackground: UInt32, sheetBackground: UInt32,
        navigationBackground: UInt32, tabBarBackground: UInt32,
        primaryText: UInt32, secondaryText: UInt32, tertiaryText: UInt32, disabledText: UInt32, inverseText: UInt32,
        headingText: UInt32, buttonText: UInt32, captionText: UInt32,
        primaryButton: UInt32, primaryButtonText: UInt32, secondaryButton: UInt32, secondaryButtonText: UInt32,
        destructiveButton: UInt32, disabledButton: UInt32, selectedControl: UInt32, unselectedControl: UInt32, focusColor: UInt32,
        ctaAccent: UInt32, ctaAccentText: UInt32,
        cardSurface: UInt32, cardBorder: UInt32, cardShadow: UInt32, cardGlow: UInt32, divider: UInt32, separator: UInt32,
        chartPrimary: UInt32, chartSecondary: UInt32, chartTertiary: UInt32, chartQuaternary: UInt32, chartGrid: UInt32, chartLabel: UInt32, chartPositive: UInt32, chartNegative: UInt32,
        success: UInt32, warning: UInt32, error: UInt32, information: UInt32,
        mokoMascotBackground: UInt32, mokoMascotAccent: UInt32, missionAccent: UInt32, questAccent: UInt32, growthAccent: UInt32, relaxAccent: UInt32, debriefAccent: UInt32, profileAccent: UInt32,
        inputBackground: UInt32, placeholder: UInt32, icon: UInt32, selectedTab: UInt32, unselectedTab: UInt32, glow: UInt32,
        loadingBackground: UInt32, completionBackground: UInt32,
        dark: Bool
    ) -> MokoThemeColors {
        MokoThemeColors(
            screenBackground: Color(hex: screenBackground),
            primaryBackground: Color(hex: primaryBackground),
            secondaryBackground: Color(hex: secondaryBackground),
            cardBackground: Color(hex: cardBackground),
            elevatedCardBackground: Color(hex: elevatedCardBackground),
            modalBackground: Color(hex: modalBackground),
            sheetBackground: Color(hex: sheetBackground),
            navigationBackground: Color(hex: navigationBackground),
            tabBarBackground: Color(hex: tabBarBackground),
            primaryText: Color(hex: primaryText),
            secondaryText: Color(hex: secondaryText),
            tertiaryText: Color(hex: tertiaryText),
            disabledText: Color(hex: disabledText),
            inverseText: Color(hex: inverseText),
            headingText: Color(hex: headingText),
            buttonText: Color(hex: buttonText),
            captionText: Color(hex: captionText),
            primaryButton: Color(hex: primaryButton),
            primaryButtonText: Color(hex: primaryButtonText),
            secondaryButton: Color(hex: secondaryButton),
            secondaryButtonText: Color(hex: secondaryButtonText),
            destructiveButton: Color(hex: destructiveButton),
            disabledButton: Color(hex: disabledButton),
            selectedControl: Color(hex: selectedControl),
            unselectedControl: Color(hex: unselectedControl),
            focusColor: Color(hex: focusColor),
            ctaAccent: Color(hex: ctaAccent),
            ctaAccentText: Color(hex: ctaAccentText),
            cardSurface: Color(hex: cardSurface),
            cardBorder: Color(hex: cardBorder),
            cardShadow: Color(hex: cardShadow),
            cardGlow: Color(hex: cardGlow),
            divider: Color(hex: divider),
            separator: Color(hex: separator),
            chartPrimary: Color(hex: chartPrimary),
            chartSecondary: Color(hex: chartSecondary),
            chartTertiary: Color(hex: chartTertiary),
            chartQuaternary: Color(hex: chartQuaternary),
            chartGrid: Color(hex: chartGrid),
            chartLabel: Color(hex: chartLabel),
            chartPositive: Color(hex: chartPositive),
            chartNegative: Color(hex: chartNegative),
            success: Color(hex: success),
            warning: Color(hex: warning),
            error: Color(hex: error),
            information: Color(hex: information),
            mokoMascotBackground: Color(hex: mokoMascotBackground),
            mokoMascotAccent: Color(hex: mokoMascotAccent),
            missionAccent: Color(hex: missionAccent),
            questAccent: Color(hex: questAccent),
            growthAccent: Color(hex: growthAccent),
            relaxAccent: Color(hex: relaxAccent),
            debriefAccent: Color(hex: debriefAccent),
            profileAccent: Color(hex: profileAccent),
            inputBackground: Color(hex: inputBackground),
            placeholder: Color(hex: placeholder),
            icon: Color(hex: icon),
            selectedTab: Color(hex: selectedTab),
            unselectedTab: Color(hex: unselectedTab),
            glow: Color(hex: glow),
            loadingBackground: Color(hex: loadingBackground),
            completionBackground: Color(hex: completionBackground)
        )
    }
}
