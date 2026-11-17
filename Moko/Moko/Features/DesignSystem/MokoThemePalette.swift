import SwiftUI

/// Seven MOKO palettes with independent light and dark variants.
/// This is the centralized palette backing the semantic theme tokens.
enum MokoThemePalette {

    static func colors(for theme: MokoThemeID, dark: Bool) -> MokoThemeColors {
        dark ? darkColors(for: theme) : lightColors(for: theme)
    }

    // MARK: - Light

    static func lightColors(for theme: MokoThemeID) -> MokoThemeColors {
        switch theme {
        case .default:
            // User-provided Default palette (light).
            return MokoThemeColors(
                screenBackground: Color(hex: 0xCBE6D3),
                primaryBackground: Color(hex: 0xCBE6D3),
                secondaryBackground: Color(hex: 0xE8F5EB),
                cardBackground: Color(hex: 0xFFFFFF),
                elevatedCardBackground: Color(hex: 0xE8F5EB),
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
                chartPrimary: Color(hex: 0x5F7E68),
                chartSecondary: Color(hex: 0x2F6E4A),
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
                completionBackground: Color(hex: 0xE8F5EB)
            )
        case .lavender:
            return make(
                screenBackground: 0xF7F4FB, primaryBackground: 0xF7F4FB, secondaryBackground: 0xF1ECF8,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xF3EEFA, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xF7F4FB, tabBarBackground: 0xFFFFFF,
                primaryText: 0x241F33, secondaryText: 0x5E5873, tertiaryText: 0x8E88A3, disabledText: 0xAEA8BF, inverseText: 0xFFFFFF,
                headingText: 0x241F33, buttonText: 0xFFFFFF, captionText: 0x5E5873,
                primaryButton: 0x5B3FA3, primaryButtonText: 0xFFFFFF, secondaryButton: 0xEEE8FA, secondaryButtonText: 0x5B3FA3,
                destructiveButton: 0xB9583F, disabledButton: 0xDDD7EA, selectedControl: 0x5B3FA3, unselectedControl: 0x8E88A3, focusColor: 0x7C5CFF,
                ctaAccent: 0x7C5CFF, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xE2DDF0, cardShadow: 0x241F33, cardGlow: 0x7C5CFF, divider: 0xEAE6F3, separator: 0xE2DDF0,
                chartPrimary: 0x5B3FA3, chartSecondary: 0xC7A6FF, chartTertiary: 0x9C8BC6, chartQuaternary: 0x7A6BB5, chartGrid: 0xDDD7EA, chartLabel: 0x5E5873, chartPositive: 0x4E9A7A, chartNegative: 0xB9583F,
                success: 0x4E9A7A, warning: 0xD97706, error: 0xB9583F, information: 0x5B3FA3,
                mokoMascotBackground: 0xEDE7FA, mokoMascotAccent: 0x5B3FA3, missionAccent: 0xC7A6FF, questAccent: 0x5B3FA3, growthAccent: 0x9C8BC6, relaxAccent: 0x7A6BB5, debriefAccent: 0x4E9A7A, profileAccent: 0x5B3FA3,
                inputBackground: 0xF6F3FB, placeholder: 0x8E88A3, icon: 0x5B3FA3, selectedTab: 0x5B3FA3, unselectedTab: 0x8E88A3, glow: 0x7C5CFF,
                loadingBackground: 0xF7F4FB, completionBackground: 0xF1ECF8, dark: false
            )
        case .ocean:
            return make(
                screenBackground: 0xF3F8FB, primaryBackground: 0xF3F8FB, secondaryBackground: 0xEAF3F8,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xEEF6FA, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xF3F8FB, tabBarBackground: 0xFFFFFF,
                primaryText: 0x132433, secondaryText: 0x4A6072, tertiaryText: 0x7E93A3, disabledText: 0xA5B6C3, inverseText: 0xFFFFFF,
                headingText: 0x132433, buttonText: 0xFFFFFF, captionText: 0x4A6072,
                primaryButton: 0x0F5C8C, primaryButtonText: 0xFFFFFF, secondaryButton: 0xE2EEF5, secondaryButtonText: 0x0F5C8C,
                destructiveButton: 0xB9583F, disabledButton: 0xD4E1EA, selectedControl: 0x0F5C8C, unselectedControl: 0x7E93A3, focusColor: 0x2E8C8A,
                ctaAccent: 0x2E8C8A, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xD7E6EE, cardShadow: 0x132433, cardGlow: 0x2E8C8A, divider: 0xE3EDF3, separator: 0xD7E6EE,
                chartPrimary: 0x0F5C8C, chartSecondary: 0x2E8C8A, chartTertiary: 0x4FD1C5, chartQuaternary: 0x3A7CA5, chartGrid: 0xD4E1EA, chartLabel: 0x4A6072, chartPositive: 0x2E8C6A, chartNegative: 0xB9583F,
                success: 0x2E8C6A, warning: 0xD97706, error: 0xB9583F, information: 0x0F5C8C,
                mokoMascotBackground: 0xDFF0F6, mokoMascotAccent: 0x0F5C8C, missionAccent: 0x4FD1C5, questAccent: 0x0F5C8C, growthAccent: 0x2E8C8A, relaxAccent: 0x3A7CA5, debriefAccent: 0x2E8C6A, profileAccent: 0x0F5C8C,
                inputBackground: 0xF2F7FA, placeholder: 0x7E93A3, icon: 0x0F5C8C, selectedTab: 0x0F5C8C, unselectedTab: 0x7E93A3, glow: 0x2E8C8A,
                loadingBackground: 0xF3F8FB, completionBackground: 0xEAF3F8, dark: false
            )
        case .sunset:
            return make(
                screenBackground: 0xFFF7F0, primaryBackground: 0xFFF7F0, secondaryBackground: 0xFFF0E6,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFF3EB, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xFFF7F0, tabBarBackground: 0xFFFFFF,
                primaryText: 0x3A2720, secondaryText: 0x6E5246, tertiaryText: 0xA0887C, disabledText: 0xBFAAA0, inverseText: 0xFFFFFF,
                headingText: 0x3A2720, buttonText: 0xFFFFFF, captionText: 0x6E5246,
                primaryButton: 0xD45A4A, primaryButtonText: 0xFFFFFF, secondaryButton: 0xF7E4D8, secondaryButtonText: 0xC47A4A,
                destructiveButton: 0xB9583F, disabledButton: 0xE8D9CE, selectedControl: 0xD45A4A, unselectedControl: 0xA0887C, focusColor: 0xFF7A5C,
                ctaAccent: 0xF2A93B, ctaAccentText: 0x3A2720,
                cardSurface: 0xFFFFFF, cardBorder: 0xF0DDD1, cardShadow: 0x3A2720, cardGlow: 0xFF7A5C, divider: 0xF5E6DC, separator: 0xF0DDD1,
                chartPrimary: 0xD45A4A, chartSecondary: 0xF2A93B, chartTertiary: 0xC47A4A, chartQuaternary: 0xE07A5F, chartGrid: 0xEEDDD1, chartLabel: 0x6E5246, chartPositive: 0x3D8B5A, chartNegative: 0xB9583F,
                success: 0x3D8B5A, warning: 0xD97706, error: 0xB9583F, information: 0xD45A4A,
                mokoMascotBackground: 0xFCE8DC, mokoMascotAccent: 0xD45A4A, missionAccent: 0xF2A93B, questAccent: 0xD45A4A, growthAccent: 0xC47A4A, relaxAccent: 0xE07A5F, debriefAccent: 0x3D8B5A, profileAccent: 0xD45A4A,
                inputBackground: 0xFFF6F0, placeholder: 0xA0887C, icon: 0xD45A4A, selectedTab: 0xD45A4A, unselectedTab: 0xA0887C, glow: 0xFF7A5C,
                loadingBackground: 0xFFF7F0, completionBackground: 0xFFF0E6, dark: false
            )
        case .blossom:
            return make(
                screenBackground: 0xFFF5F7, primaryBackground: 0xFFF5F7, secondaryBackground: 0xFDEEF2,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xFFF1F4, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xFFF5F7, tabBarBackground: 0xFFFFFF,
                primaryText: 0x35212A, secondaryText: 0x6B4E59, tertiaryText: 0xA48793, disabledText: 0xBDA8B1, inverseText: 0xFFFFFF,
                headingText: 0x35212A, buttonText: 0xFFFFFF, captionText: 0x6B4E59,
                primaryButton: 0xC04A6B, primaryButtonText: 0xFFFFFF, secondaryButton: 0xF7E3EA, secondaryButtonText: 0xC04A6B,
                destructiveButton: 0xB9583F, disabledButton: 0xE8D9DF, selectedControl: 0xC04A6B, unselectedControl: 0xA48793, focusColor: 0xFF7AA2,
                ctaAccent: 0xFF7AA2, ctaAccentText: 0x35212A,
                cardSurface: 0xFFFFFF, cardBorder: 0xF0DDE3, cardShadow: 0x35212A, cardGlow: 0xFF7AA2, divider: 0xF6E7EC, separator: 0xF0DDE3,
                chartPrimary: 0xC04A6B, chartSecondary: 0xF4B6C2, chartTertiary: 0xD98AA3, chartQuaternary: 0xB85C7A, chartGrid: 0xECDDE4, chartLabel: 0x6B4E59, chartPositive: 0x3D8B5A, chartNegative: 0xB9583F,
                success: 0x3D8B5A, warning: 0xD97706, error: 0xB9583F, information: 0xC04A6B,
                mokoMascotBackground: 0xFCE6EC, mokoMascotAccent: 0xC04A6B, missionAccent: 0xF4B6C2, questAccent: 0xC04A6B, growthAccent: 0xD98AA3, relaxAccent: 0xB85C7A, debriefAccent: 0x3D8B5A, profileAccent: 0xC04A6B,
                inputBackground: 0xFFF4F6, placeholder: 0xA48793, icon: 0xC04A6B, selectedTab: 0xC04A6B, unselectedTab: 0xA48793, glow: 0xFF7AA2,
                loadingBackground: 0xFFF5F7, completionBackground: 0xFDEEF2, dark: false
            )
        case .midnight:
            return make(
                screenBackground: 0xF4F6FB, primaryBackground: 0xF4F6FB, secondaryBackground: 0xEDF0F8,
                cardBackground: 0xFFFFFF, elevatedCardBackground: 0xF0F3FB, modalBackground: 0xFFFFFF, sheetBackground: 0xFFFFFF,
                navigationBackground: 0xF4F6FB, tabBarBackground: 0xFFFFFF,
                primaryText: 0x1A2238, secondaryText: 0x4A5678, tertiaryText: 0x8590AD, disabledText: 0xA8B0C7, inverseText: 0xFFFFFF,
                headingText: 0x1A2238, buttonText: 0xFFFFFF, captionText: 0x4A5678,
                primaryButton: 0x3949AB, primaryButtonText: 0xFFFFFF, secondaryButton: 0xE6EBF8, secondaryButtonText: 0x3949AB,
                destructiveButton: 0xB9583F, disabledButton: 0xD8DEEE, selectedControl: 0x3949AB, unselectedControl: 0x8590AD, focusColor: 0x5B7CFF,
                ctaAccent: 0x5B7CFF, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xFFFFFF, cardBorder: 0xDDE2F0, cardShadow: 0x1A2238, cardGlow: 0x5B7CFF, divider: 0xE6EAF5, separator: 0xDDE2F0,
                chartPrimary: 0x3949AB, chartSecondary: 0x5B8CFF, chartTertiary: 0x5C6BC0, chartQuaternary: 0x7986CB, chartGrid: 0xDDE2F0, chartLabel: 0x4A5678, chartPositive: 0x3D8B5A, chartNegative: 0xB9583F,
                success: 0x3D8B5A, warning: 0xD97706, error: 0xB9583F, information: 0x3949AB,
                mokoMascotBackground: 0xE4EAFB, mokoMascotAccent: 0x3949AB, missionAccent: 0x5B8CFF, questAccent: 0x3949AB, growthAccent: 0x5C6BC0, relaxAccent: 0x7986CB, debriefAccent: 0x3D8B5A, profileAccent: 0x3949AB,
                inputBackground: 0xF3F5FB, placeholder: 0x8590AD, icon: 0x3949AB, selectedTab: 0x3949AB, unselectedTab: 0x8590AD, glow: 0x5B7CFF,
                loadingBackground: 0xF4F6FB, completionBackground: 0xEDF0F8, dark: false
            )
        case .batman:
            // Light counterpart: warm ivory/beige surfaces, deep brown/near-black text, teal/coral accents.
            return make(
                screenBackground: 0xE6DDD6, primaryBackground: 0xF3EEE8, secondaryBackground: 0xDDD2C8,
                cardBackground: 0xF8F4EF, elevatedCardBackground: 0xEFE7DF, modalBackground: 0xF8F4EF, sheetBackground: 0xF3EEE8,
                navigationBackground: 0xE6DDD6, tabBarBackground: 0xF3EEE8,
                primaryText: 0x1C1713, secondaryText: 0x4A4138, tertiaryText: 0x6E6358, disabledText: 0x9A8F84, inverseText: 0xF2F2F2,
                headingText: 0x14110E, buttonText: 0xFFFFFF, captionText: 0x4A4138,
                primaryButton: 0x2D69E0, primaryButtonText: 0xFFFFFF, secondaryButton: 0xE7DED4, secondaryButtonText: 0x008F8A,
                destructiveButton: 0xEC6746, disabledButton: 0xD8CFC6, selectedControl: 0x008F8A, unselectedControl: 0x6E6358, focusColor: 0x00A39E,
                ctaAccent: 0x008F8A, ctaAccentText: 0xFFFFFF,
                cardSurface: 0xF8F4EF, cardBorder: 0xD2C6BC, cardShadow: 0x1C1713, cardGlow: 0x00A39E, divider: 0xD8CDC3, separator: 0xD2C6BC,
                chartPrimary: 0x008F8A, chartSecondary: 0x2D69E0, chartTertiary: 0xEC6746, chartQuaternary: 0x4A4138, chartGrid: 0xD8CDC3, chartLabel: 0x4A4138, chartPositive: 0x008F8A, chartNegative: 0xEC6746,
                success: 0x3D8B5A, warning: 0xC8871E, error: 0xEC6746, information: 0x2D69E0,
                mokoMascotBackground: 0xE9E1D8, mokoMascotAccent: 0x008F8A, missionAccent: 0x00A39E, questAccent: 0x2D69E0, growthAccent: 0x008F8A, relaxAccent: 0x6E6358, debriefAccent: 0xEC6746, profileAccent: 0x008F8A,
                inputBackground: 0xEFE7DF, placeholder: 0x7A6F64, icon: 0x1C1713, selectedTab: 0x008F8A, unselectedTab: 0x6E6358, glow: 0x00A39E,
                loadingBackground: 0xE6DDD6, completionBackground: 0xF3EEE8, dark: false
            )
        }
    }

    // MARK: - Dark (independently designed)

    static func darkColors(for theme: MokoThemeID) -> MokoThemeColors {
        switch theme {
        case .default:
            // Dark counterpart for Default palette (deep greens, readable surfaces).
            return MokoThemeColors(
                screenBackground: Color(hex: 0x121A15),
                primaryBackground: Color(hex: 0x121A15),
                secondaryBackground: Color(hex: 0x18221B),
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
            return make(
                screenBackground: 0x14121A, primaryBackground: 0x14121A, secondaryBackground: 0x191622,
                cardBackground: 0x201C2B, elevatedCardBackground: 0x282337, modalBackground: 0x201C2B, sheetBackground: 0x191622,
                navigationBackground: 0x14121A, tabBarBackground: 0x1C1826,
                primaryText: 0xF4F1FA, secondaryText: 0xC0B8D6, tertiaryText: 0x958CAC, disabledText: 0x756C8C, inverseText: 0x14121A,
                headingText: 0xFBF9FF, buttonText: 0x14121A, captionText: 0xC0B8D6,
                primaryButton: 0xB69CFF, primaryButtonText: 0x14121A, secondaryButton: 0x282337, secondaryButtonText: 0xD8B4FF,
                destructiveButton: 0xD07A5E, disabledButton: 0x2D2740, selectedControl: 0xB69CFF, unselectedControl: 0x8A80A3, focusColor: 0xB69CFF,
                ctaAccent: 0xD8B4FF, ctaAccentText: 0x14121A,
                cardSurface: 0x201C2B, cardBorder: 0x332C45, cardShadow: 0x000000, cardGlow: 0xB69CFF, divider: 0x2D2740, separator: 0x332C45,
                chartPrimary: 0xB69CFF, chartSecondary: 0xD8B4FF, chartTertiary: 0x8F7BCF, chartQuaternary: 0x9E86E8, chartGrid: 0x332C45, chartLabel: 0xC0B8D6, chartPositive: 0x6FD1A3, chartNegative: 0xD07A5E,
                success: 0x6FD1A3, warning: 0xF2C14E, error: 0xD07A5E, information: 0xB69CFF,
                mokoMascotBackground: 0x262136, mokoMascotAccent: 0xB69CFF, missionAccent: 0xD8B4FF, questAccent: 0xB69CFF, growthAccent: 0x8F7BCF, relaxAccent: 0x9E86E8, debriefAccent: 0x6FD1A3, profileAccent: 0xD8B4FF,
                inputBackground: 0x262136, placeholder: 0x8A80A3, icon: 0xB69CFF, selectedTab: 0xB69CFF, unselectedTab: 0x8A80A3, glow: 0xB69CFF,
                loadingBackground: 0x14121A, completionBackground: 0x191622, dark: true
            )
        case .ocean:
            return make(
                screenBackground: 0x0F1418, primaryBackground: 0x0F1418, secondaryBackground: 0x131A20,
                cardBackground: 0x182229, elevatedCardBackground: 0x1F2B34, modalBackground: 0x182229, sheetBackground: 0x131A20,
                navigationBackground: 0x0F1418, tabBarBackground: 0x151D23,
                primaryText: 0xEEF6FA, secondaryText: 0xAFC4D1, tertiaryText: 0x8AA5B4, disabledText: 0x6C8593, inverseText: 0x0F1418,
                headingText: 0xF6FBFF, buttonText: 0x0B1216, captionText: 0xAFC4D1,
                primaryButton: 0x4FC3F7, primaryButtonText: 0x0B1216, secondaryButton: 0x1F2B34, secondaryButtonText: 0x6FE7DD,
                destructiveButton: 0xD07A5E, disabledButton: 0x22303A, selectedControl: 0x4FC3F7, unselectedControl: 0x7C94A3, focusColor: 0x4DB6AC,
                ctaAccent: 0x6FE7DD, ctaAccentText: 0x0B1216,
                cardSurface: 0x182229, cardBorder: 0x26343E, cardShadow: 0x000000, cardGlow: 0x4DB6AC, divider: 0x22303A, separator: 0x26343E,
                chartPrimary: 0x4FC3F7, chartSecondary: 0x4DB6AC, chartTertiary: 0x6FE7DD, chartQuaternary: 0x6AAFE6, chartGrid: 0x26343E, chartLabel: 0xAFC4D1, chartPositive: 0x4DB6AC, chartNegative: 0xD07A5E,
                success: 0x4DB6AC, warning: 0xF2C14E, error: 0xD07A5E, information: 0x4FC3F7,
                mokoMascotBackground: 0x1C2830, mokoMascotAccent: 0x4FC3F7, missionAccent: 0x6FE7DD, questAccent: 0x4FC3F7, growthAccent: 0x4DB6AC, relaxAccent: 0x6AAFE6, debriefAccent: 0x4DB6AC, profileAccent: 0x6FE7DD,
                inputBackground: 0x1C2830, placeholder: 0x7C94A3, icon: 0x4FC3F7, selectedTab: 0x4FC3F7, unselectedTab: 0x7C94A3, glow: 0x4DB6AC,
                loadingBackground: 0x0F1418, completionBackground: 0x131A20, dark: true
            )
        case .sunset:
            return make(
                screenBackground: 0x171312, primaryBackground: 0x171312, secondaryBackground: 0x1D1715,
                cardBackground: 0x241C19, elevatedCardBackground: 0x2C221E, modalBackground: 0x241C19, sheetBackground: 0x1D1715,
                navigationBackground: 0x171312, tabBarBackground: 0x1F1917,
                primaryText: 0xFFF3EC, secondaryText: 0xD4C0B6, tertiaryText: 0xA89085, disabledText: 0x806A60, inverseText: 0x171312,
                headingText: 0xFFF8F3, buttonText: 0x171312, captionText: 0xD4C0B6,
                primaryButton: 0xFF8A70, primaryButtonText: 0x171312, secondaryButton: 0x2C221E, secondaryButtonText: 0xFFB74D,
                destructiveButton: 0xD07A5E, disabledButton: 0x312622, selectedControl: 0xFF8A70, unselectedControl: 0x9C857A, focusColor: 0xFF8A70,
                ctaAccent: 0xFFB74D, ctaAccentText: 0x171312,
                cardSurface: 0x241C19, cardBorder: 0x372B27, cardShadow: 0x000000, cardGlow: 0xFF8A70, divider: 0x312622, separator: 0x372B27,
                chartPrimary: 0xFF8A70, chartSecondary: 0xFFB74D, chartTertiary: 0xE08A5A, chartQuaternary: 0xF29C85, chartGrid: 0x372B27, chartLabel: 0xD4C0B6, chartPositive: 0x6FD1A3, chartNegative: 0xD07A5E,
                success: 0x6FD1A3, warning: 0xFFB74D, error: 0xD07A5E, information: 0xFF8A70,
                mokoMascotBackground: 0x2A211D, mokoMascotAccent: 0xFF8A70, missionAccent: 0xFFB74D, questAccent: 0xFF8A70, growthAccent: 0xE08A5A, relaxAccent: 0xF29C85, debriefAccent: 0x6FD1A3, profileAccent: 0xFFB74D,
                inputBackground: 0x2A211D, placeholder: 0x9C857A, icon: 0xFF8A70, selectedTab: 0xFF8A70, unselectedTab: 0x9C857A, glow: 0xFF8A70,
                loadingBackground: 0x171312, completionBackground: 0x1D1715, dark: true
            )
        case .blossom:
            return make(
                screenBackground: 0x171316, primaryBackground: 0x171316, secondaryBackground: 0x1D181C,
                cardBackground: 0x241E23, elevatedCardBackground: 0x2C242B, modalBackground: 0x241E23, sheetBackground: 0x1D181C,
                navigationBackground: 0x171316, tabBarBackground: 0x201A1F,
                primaryText: 0xFFF2F6, secondaryText: 0xD8C0CA, tertiaryText: 0xAD93A0, disabledText: 0x846D78, inverseText: 0x171316,
                headingText: 0xFFF7FA, buttonText: 0x171316, captionText: 0xD8C0CA,
                primaryButton: 0xFF7FA8, primaryButtonText: 0x171316, secondaryButton: 0x2C242B, secondaryButtonText: 0xFFC1D6,
                destructiveButton: 0xD07A5E, disabledButton: 0x322730, selectedControl: 0xFF7FA8, unselectedControl: 0x9E8793, focusColor: 0xFF7FA8,
                ctaAccent: 0xFFC1D6, ctaAccentText: 0x171316,
                cardSurface: 0x241E23, cardBorder: 0x382C34, cardShadow: 0x000000, cardGlow: 0xFF7FA8, divider: 0x322730, separator: 0x382C34,
                chartPrimary: 0xFF7FA8, chartSecondary: 0xFFC1D6, chartTertiary: 0xE7A1B8, chartQuaternary: 0xF09BB8, chartGrid: 0x382C34, chartLabel: 0xD8C0CA, chartPositive: 0x6FD1A3, chartNegative: 0xD07A5E,
                success: 0x6FD1A3, warning: 0xFFB74D, error: 0xD07A5E, information: 0xFF7FA8,
                mokoMascotBackground: 0x2A2329, mokoMascotAccent: 0xFF7FA8, missionAccent: 0xFFC1D6, questAccent: 0xFF7FA8, growthAccent: 0xE7A1B8, relaxAccent: 0xF09BB8, debriefAccent: 0x6FD1A3, profileAccent: 0xFFC1D6,
                inputBackground: 0x2A2329, placeholder: 0x9E8793, icon: 0xFF7FA8, selectedTab: 0xFF7FA8, unselectedTab: 0x9E8793, glow: 0xFF7FA8,
                loadingBackground: 0x171316, completionBackground: 0x1D181C, dark: true
            )
        case .midnight:
            return make(
                screenBackground: 0x0E1118, primaryBackground: 0x0E1118, secondaryBackground: 0x121622,
                cardBackground: 0x171C2B, elevatedCardBackground: 0x1E2436, modalBackground: 0x171C2B, sheetBackground: 0x121622,
                navigationBackground: 0x0E1118, tabBarBackground: 0x141927,
                primaryText: 0xEEF2FF, secondaryText: 0xB7C0D9, tertiaryText: 0x919CB8, disabledText: 0x6F7994, inverseText: 0x0E1118,
                headingText: 0xF7F9FF, buttonText: 0x0E1118, captionText: 0xB7C0D9,
                primaryButton: 0x6C8CFF, primaryButtonText: 0x0E1118, secondaryButton: 0x1E2436, secondaryButtonText: 0x7FB0FF,
                destructiveButton: 0xD07A5E, disabledButton: 0x232B42, selectedControl: 0x6C8CFF, unselectedControl: 0x7E8AA8, focusColor: 0x6C8CFF,
                ctaAccent: 0x7FB0FF, ctaAccentText: 0x0E1118,
                cardSurface: 0x171C2B, cardBorder: 0x27304A, cardShadow: 0x000000, cardGlow: 0x6C8CFF, divider: 0x232B42, separator: 0x27304A,
                chartPrimary: 0x6C8CFF, chartSecondary: 0x7FB0FF, chartTertiary: 0x8EA2FF, chartQuaternary: 0x9AAEFF, chartGrid: 0x27304A, chartLabel: 0xB7C0D9, chartPositive: 0x6FD1A3, chartNegative: 0xD07A5E,
                success: 0x6FD1A3, warning: 0xF2C14E, error: 0xD07A5E, information: 0x7FB0FF,
                mokoMascotBackground: 0x1C2234, mokoMascotAccent: 0x6C8CFF, missionAccent: 0x7FB0FF, questAccent: 0x6C8CFF, growthAccent: 0x8EA2FF, relaxAccent: 0x9AAEFF, debriefAccent: 0x6FD1A3, profileAccent: 0x7FB0FF,
                inputBackground: 0x1C2234, placeholder: 0x7E8AA8, icon: 0x7FB0FF, selectedTab: 0x6C8CFF, unselectedTab: 0x7E8AA8, glow: 0x6C8CFF,
                loadingBackground: 0x0E1118, completionBackground: 0x121622, dark: true
            )
        case .batman:
            // Batman dark (spec): near-black bg, charcoal cards, teal/coral accents, blue action.
            return make(
                screenBackground: 0x0D0D0D, primaryBackground: 0x0D0D0D, secondaryBackground: 0x121212,
                cardBackground: 0x222222, elevatedCardBackground: 0x303030, modalBackground: 0x222222, sheetBackground: 0x121212,
                navigationBackground: 0x0D0D0D, tabBarBackground: 0x121212,
                primaryText: 0xF5F5F5, secondaryText: 0xC4C4C4, tertiaryText: 0x999999, disabledText: 0x6B6B6B, inverseText: 0x0D0D0D,
                headingText: 0xF5F5F5, buttonText: 0xFFFFFF, captionText: 0xC4C4C4,
                primaryButton: 0x2D69E0, primaryButtonText: 0xFFFFFF, secondaryButton: 0x292929, secondaryButtonText: 0x00CEC8,
                destructiveButton: 0xEC6746, disabledButton: 0x333333, selectedControl: 0x00CEC8, unselectedControl: 0x7A7A7A, focusColor: 0x00CEC8,
                ctaAccent: 0x00CEC8, ctaAccentText: 0x0D0D0D,
                cardSurface: 0x222222, cardBorder: 0x3A3A3A, cardShadow: 0x000000, cardGlow: 0x00CEC8, divider: 0x383838, separator: 0x3A3A3A,
                chartPrimary: 0x00CEC8, chartSecondary: 0xEC6746, chartTertiary: 0x2D69E0, chartQuaternary: 0xC9CFE6, chartGrid: 0x383838, chartLabel: 0xC4C4C4, chartPositive: 0x00CEC8, chartNegative: 0xEC6746,
                success: 0x7CDA8C, warning: 0xF2C14E, error: 0xEC6746, information: 0x2D69E0,
                mokoMascotBackground: 0x1A1A1A, mokoMascotAccent: 0x00CEC8, missionAccent: 0x00CEC8, questAccent: 0xEC6746, growthAccent: 0x2D69E0, relaxAccent: 0xC9CFE6, debriefAccent: 0xEC6746, profileAccent: 0x00CEC8,
                inputBackground: 0x292929, placeholder: 0x999999, icon: 0xF5F5F5, selectedTab: 0x00CEC8, unselectedTab: 0x7A7A7A, glow: 0x00CEC8,
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
