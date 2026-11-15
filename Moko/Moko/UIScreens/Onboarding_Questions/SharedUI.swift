//
//  SharedUI.swift
//  Moko
//
//  Small pieces shared by the Done and Reflection screens after the swipe questions.
//  `Color(hex:)` lives in MokoScreenTheme.swift.
//

import SwiftUI

/// Colors from the Done / Reflection Figma screens.
enum RColor {
    /// Headings and row titles.
    static let text    = Color(hex: 0x201A18)
    /// Longer body text (expanded row details).
    static let body    = Color(hex: 0x414943)
    /// Pill button fill and "strength" icons.
    static let green   = Color(hex: 0x28523B)
    /// The expand/collapse arrow on reflection rows.
    static let chevron = Color(hex: 0x1B422F)
    /// "Weak spot" icons.
    static let rust    = Color(hex: 0x9A442D)
    /// Soft circle backgrounds behind the Done screen's icons.
    static let mint    = Color(hex: 0xBFEDCF)
    static let peach   = Color(hex: 0xFFDEAB)
}

/// Full-width dark-green capsule button with a soft double shadow.
struct PillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(RColor.green))
        }
        // `.plain` stops SwiftUI adding its own blue tint / pressed style.
        .buttonStyle(.plain)
        // Two stacked shadows: a tight one for edge definition, a wide one for depth.
        .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
        .shadow(color: .black.opacity(0.1), radius: 15, y: 10)
    }
}
