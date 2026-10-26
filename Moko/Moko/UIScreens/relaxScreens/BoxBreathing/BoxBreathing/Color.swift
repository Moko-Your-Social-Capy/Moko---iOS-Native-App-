import SwiftUI

/// All colours used by the Box Breathing screens (taken from the Figma).
enum BBColor {
    static let background = Color(hex: 0xF2F2F7)   // screen background
    static let button     = Color(hex: 0x365948)   // buttons, check circle, "Not now"
    static let dark       = Color(hex: 0x1B422F)   // corner dots + filled box edges
    static let track      = Color(hex: 0xD9D9D9)   // empty box edges + timer arc
    static let title      = Color(hex: 0x292B26)
    static let subtitle   = Color(hex: 0x8A7B68)
    static let muted      = Color(hex: 0x6F6762)
    static let card       = Color(hex: 0xFCF8F0)   // cream icon circle
}

extension Color {
    /// Lets you write colours as hex numbers, e.g. Color(hex: 0x365948).
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
