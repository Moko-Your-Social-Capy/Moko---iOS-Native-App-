//
//  Colors.swift
//  Onboarding
//
//  Created by user@77 on 22/10/26.
//

import SwiftUI

extension Color {
    static let ink         = MokoTheme.titleBrown
    static let forest      = Color(hex: 0x1B422F)
    static let forestLight = Color(hex: 0x26533D)
    static let cream       = MokoTheme.limeBackground
    static let cardFill    = Color(red: 250.0 / 255.0, green: 253.0 / 255.0, blue: 241.0 / 255.0)
    static let cardStroke  = Color(hex: 0xDED6C7)
    static let track       = MokoTheme.limeSelected.opacity(0.55)
    static let dotInactive = MokoTheme.limeSelected.opacity(0.45)
    static let terracotta  = Color(hex: 0x9A442D)

    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}
