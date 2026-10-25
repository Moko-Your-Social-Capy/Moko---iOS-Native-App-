import SwiftUI

/// Central source of truth for MOKO's monochrome color system.
enum AppColors {
    enum Light {
        static let background = Color(hex: 0xF2F2F7)
        static let surface = Color(hex: 0xFFFFFF)
        static let primaryText = Color(hex: 0x171717)
        static let secondaryText = Color(hex: 0x626262)
        static let tertiaryText = Color(hex: 0x9E9E9E)
        static let primaryAction = Color(hex: 0x1A1A1A)
        static let primaryActionText = Color(hex: 0xFFFFFF)
        static let separator = Color(hex: 0xE5E5E5)
        static let cardShadow = Color.black.opacity(0.04)
        static let chartStroke = Color(hex: 0x262626)
        static let chartFill = Color(hex: 0x262626).opacity(0.15)
        static let chartGrid = Color(hex: 0xD4D4D4)
    }

    enum Dark {
        static let background = Color(hex: 0x101010)
        static let surface = Color(hex: 0x1C1C1C)
        static let primaryText = Color(hex: 0xF5F5F5)
        static let secondaryText = Color(hex: 0xB7B7B7)
        static let tertiaryText = Color(hex: 0x737373)
        static let primaryAction = Color(hex: 0xF2F2F2)
        static let primaryActionText = Color(hex: 0x101010)
        static let separator = Color(hex: 0x2E2E2E)
        static let cardShadow = Color.black.opacity(0.4)
        static let chartStroke = Color(hex: 0xE5E5E5)
        static let chartFill = Color(hex: 0xE5E5E5).opacity(0.2)
        static let chartGrid = Color(hex: 0x404040)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    static func adaptive(light: Color, dark: Color) -> Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        return light
        #endif
    }
}
