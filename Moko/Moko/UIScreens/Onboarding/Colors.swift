//
//  Colors.swift
//  Onboarding
//
//  Created by user@77 on 22/10/26.
//

import SwiftUI

extension Color {
    static let ink         = Color(hex: 0x292B26)
    static let forest      = Color(hex: 0x1B422F)
    static let forestLight = Color(hex: 0x26533D)
    static let cream       = Color(hex: 0xF6F0E4)
    static let cardFill    = Color(hex: 0xFCF8F0)
    static let cardStroke  = Color(hex: 0xDED6C7)
    static let track       = Color(hex: 0xEBDED8)
    static let dotInactive = Color(hex: 0xECE0DD)
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
