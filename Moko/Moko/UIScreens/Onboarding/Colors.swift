//
//  Colors.swift
//  Moko
//
//  Created by user@77 on 22/10/26.
//
//  Colours for the onboarding info screens (carousel, name, age, welcome).
//  Use them as `Color.ink`, `Color.forest`, ...
//  `Color(hex:)` lives in MokoScreenTheme.swift.
//

import SwiftUI

extension Color {
    /// Titles and body text.
    static let ink         = MokoTheme.titleBrown
    /// Button fill.
    static let forest      = Color(hex: 0x1B422F)
    /// Filled part of the progress bar.
    static let forestLight = Color(hex: 0x26533D)
    /// Button text.
    static let cream       = MokoTheme.limeBackground
    /// Card background.
    static let cardFill    = MokoTheme.cardBackground
    /// Card border.
    static let cardStroke  = Color(hex: 0xDED6C7)
    /// Empty part of the progress bar.
    static let track       = MokoTheme.limeSelected.opacity(0.55)
    /// Carousel page dots: inactive and active.
    static let dotInactive = MokoTheme.limeSelected.opacity(0.45)
    static let terracotta  = Color(hex: 0x9A442D)
}
