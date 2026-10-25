import SwiftUI

/// Colors sampled/approximated from the supplied MOKO copied-screen references.
/// Centralized here so every screen uses the same palette.
enum AppColors {
    static let canvas = Color(red: 243/255, green: 242/255, blue: 246/255)          // cool, near-white screen background
    static let card = Color.white
    static let cardMuted = Color(red: 248/255, green: 247/255, blue: 248/255)
    static let ink = Color(red: 23/255, green: 24/255, blue: 23/255)
    static let secondaryInk = Color(red: 119/255, green: 119/255, blue: 119/255)
    static let forest = Color(red: 52/255, green: 91/255, blue: 73/255)          // overview CTA / deep green text
    static let forestMuted = Color(red: 232/255, green: 239/255, blue: 235/255)
    static let amber = Color(red: 244/255, green: 165/255, blue: 28/255)           // charts, icons, radar fill
    static let amberSoft = Color(red: 255/255, green: 240/255, blue: 212/255)
    static let amberGrid = Color(red: 246/255, green: 209/255, blue: 141/255)
    static let divider = Color(red: 230/255, green: 227/255, blue: 224/255)
    static let inactivePill = Color(red: 228/255, green: 228/255, blue: 230/255)

    enum Light {
        static let background = Color(red: 242/255, green: 242/255, blue: 247/255)
        static let surface = Color.white
        static let primaryText = Color(red: 23/255, green: 24/255, blue: 23/255)
        static let secondaryText = Color(red: 98/255, green: 98/255, blue: 98/255)
        static let primaryAction = Color(red: 26/255, green: 26/255, blue: 26/255)
        static let separator = Color(red: 229/255, green: 229/255, blue: 229/255)
        static let cardShadow = Color.black.opacity(0.04)
    }

    enum Dark {
        static let background = Color(red: 16/255, green: 16/255, blue: 16/255)
        static let surface = Color(red: 28/255, green: 28/255, blue: 28/255)
        static let primaryText = Color(red: 245/255, green: 245/255, blue: 245/255)
        static let secondaryText = Color(red: 183/255, green: 183/255, blue: 183/255)
        static let primaryAction = Color(red: 242/255, green: 242/255, blue: 242/255)
        static let separator = Color(red: 46/255, green: 46/255, blue: 46/255)
        static let cardShadow = Color.black.opacity(0.4)
    }

    static func screenBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(uiColor: .systemBackground) : canvas
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(uiColor: .secondarySystemBackground) : card
    }
}
