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
    public static let surfacePrimary = Color(red: 246.0 / 255.0, green: 250.0 / 255.0, blue: 232.0 / 255.0) // #F6FAE8 pale lime
    public static let surfaceSecondary = Color(red: 226.0 / 255.0, green: 245.0 / 255.0, blue: 177.0 / 255.0) // #E2F5B1 lime

    // Text Colors - Use black for main titles, deep green for body
    public static let textPrimary = Color(red: 92.0 / 255.0, green: 67.0 / 255.0, blue: 48.0 / 255.0) // #5C4330 brown
    public static let textSecondary = Color(red: 81.0 / 255.0, green: 68.0 / 255.0, blue: 62.0 / 255.0) // #51443E warm brown
    public static let textMuted = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762 Muted gray/green

    // Charts and Progress
    public static let chartPrimary = Color(red: 55/255, green: 83/255, blue: 52/255) // #375534 - primary data
    public static let chartSecondary = Color(red: 107/255, green: 112/255, blue: 113/255) // #6B9071 Sage

    // Control States
    public static let controlSelected = Color(red: 226.0 / 255.0, green: 245.0 / 255.0, blue: 177.0 / 255.0)
    public static let controlInactive = ColorTokens.textSecondary

    // MARK: - Profile Palette

    /// Primary text color for profiles
    public static let profileText = Color(red: 92.0 / 255.0, green: 67.0 / 255.0, blue: 48.0 / 255.0)

    /// Secondary text color for profiles
    public static let profileSecondary = Color(red: 81.0 / 255.0, green: 68.0 / 255.0, blue: 62.0 / 255.0)

    /// Success/green indicator
    public static let profileSuccess = Color(red: 27.0 / 255.0, green: 66.0 / 255.0, blue: 47.0 / 255.0)

    /// Mid green for backgrounds
    public static let profileMidGreen = Color(red: 54.0 / 255.0, green: 89.0 / 255.0, blue: 72.0 / 255.0)

    /// Accent color for profiles
    public static let profileAccent = Color(red: 226.0 / 255.0, green: 245.0 / 255.0, blue: 177.0 / 255.0)

    // MARK: - Costume Asset Reference

    public enum CostumeAssetType: String, CaseIterable, Identifiable {
        case mokoSittingRaw = "moko_sitting_raw"
        case mokoWavingRaw = "moko_waving_raw"
        case capybaraPeek = "capybara_peek"

        public var id: String { rawValue }

        func description() -> String {
            switch self {
            case .mokoSittingRaw: return "The original Moko - sitting quietly in the forest"
            case .mokoWavingRaw: return "Saying hello to friends across the landscape"
            case .capybaraPeek: return "A peek into capybara culture"
            }
        }
    }
}

extension View {
    public func background() -> some View {
        return self.background(ColorTokens.surfacePrimary)
    }

    public func textPrimary() -> some View {
        return self.foregroundColor(ColorTokens.textPrimary)
    }
}
