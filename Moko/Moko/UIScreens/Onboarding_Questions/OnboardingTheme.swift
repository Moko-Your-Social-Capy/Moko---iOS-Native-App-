//
//  OnboardingTheme.swift
//  Moko
//
//  Created by user@14 on 23/10/26.
//
//  Colours for the swipeable onboarding questions, taken from the Figma export.
//  `Color(hex:)` lives in MokoScreenTheme.swift.
//

import SwiftUI

enum OBColor {
    /// Title and question text.
    static let ink         = MokoTheme.titleBrown
    /// "Yes" button and swipe tint.
    static let yes         = Color(hex: 0x2F6E4A)
    /// "No" button and swipe tint.
    static let no          = Color(hex: 0xB9583F)
    /// Progress bar: done and not-done segments.
    static let progressOn  = Color(hex: 0x406A52)
    static let progressOff = MokoTheme.limeSelected
    static let cardFill    = MokoTheme.cardBackground
    static let cardStroke  = Color(hex: 0xDED6C7)
    /// The "of" in "1 of 8".
    static let muted       = Color(hex: 0x887B75, opacity: 0.8)
}

// Colors for the Stitch "Swipe Deck" redesign of the question cards.
enum OBDeck {
    /// Soft lavender behind the whole screen.
    static let screen      = Color(hex: 0xEDE9FE)
    /// Main card purple.
    static let purple      = Color(hex: 0xA855F7)
    /// Darker purple for the reflection box.
    static let purpleDeep  = Color(hex: 0x6B21A8)
    /// Near-black used for borders, text and the hard shadow.
    static let ink         = Color(hex: 0x18181B)
    /// Bright lime for the category chip and the Yes button.
    static let lime        = Color(hex: 0xA3E635)
}
