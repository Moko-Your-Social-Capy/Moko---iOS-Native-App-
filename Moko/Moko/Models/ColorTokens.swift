//
//  ColorTokens.swift
//  Moko
//
//  Forest green color palette for MOKO wellness app.

import SwiftUI

public enum ColorTokens {
    // Brand Colors - Forest Green Palette
    public static let brandPrimary = Color(red: 15/255, green: 42/255, blue: 29/255) // #0F2A1D Forest
    public static let brandSecondary = Color(red: 55/255, green: 83/255, blue: 52/255) // #375534 Deep Green

    // Surface Colors
    public static let surfacePrimary = Color(red: 174/255, green: 195/255, blue: 176/255) // #AEC3B0 Muted Sage
    public static let surfaceSecondary = Color(red: 227/255, green: 237/255, blue: 212/255) // #E3EED4 Pale Green

    // Text Colors - Use black for main titles, deep green for body
    public static let textPrimary = Color.black // #000000
    public static let textSecondary = Color(red: 55/255, green: 83/255, blue: 52/255) // #375534 Deep Green
    public static let textMuted = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762 Muted gray/green

    // Charts and Progress
    public static let chartPrimary = Color(red: 55/255, green: 83/255, blue: 52/255) // #375534 - primary data
    public static let chartSecondary = Color(red: 107/255, green: 112/255, blue: 113/255) // #6B9071 Sage

    // Control States
    public static let controlSelected = ColorTokens.brandPrimary
    public static let controlInactive = ColorTokens.textSecondary
}

extension View {
    public func background() -> some View {
        return self.background(ColorTokens.surfacePrimary)
    }

    public func textPrimary() -> some View {
        return self.foregroundColor(ColorTokens.textPrimary)
    }
}
