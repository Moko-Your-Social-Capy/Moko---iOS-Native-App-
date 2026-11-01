//
//  OnboardingTheme.swift
//  Onboarding_Questions
//
//  Created by user@14 on 23/10/26.
//
import SwiftUI

/// Colours pulled straight from the Figma export.
enum OBColor {
    static let ink         = MokoTheme.titleBrown   // title + question text
    static let yes         = Color(hex: 0x2F6E4A)
    static let no          = Color(hex: 0xB9583F)
    static let progressOn  = Color(hex: 0x406A52)
    static let progressOff = MokoTheme.limeSelected
    static let cardFill    = Color(red: 250.0 / 255.0, green: 253.0 / 255.0, blue: 241.0 / 255.0)
    static let cardStroke  = Color(hex: 0xDED6C7)
    static let muted       = Color(hex: 0x887B75, opacity: 0.8)   // the "of" in "1 of 8"
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
