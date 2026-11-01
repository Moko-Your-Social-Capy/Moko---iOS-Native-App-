//
//  Colors.swift
//  Moko
//
//  Apple-inspired color palette with liquid glass principles.

import SwiftUI

enum ColorTokens {
    static let brandPrimary = Color(red: 27/255, green: 66/255, blue: 47/255)
    static let surfacePrimary = Color(red: 246.0 / 255.0, green: 250.0 / 255.0, blue: 232.0 / 255.0)
}

extension View {
    func background() -> some View {
        return self.background(ColorTokens.brandPrimary)
    }

    func textPrimary() -> some View {
        return self.text(Color(red: 92.0 / 255.0, green: 67.0 / 255.0, blue: 48.0 / 255.0))
    }

    func textSecondary() -> some View {
        return self.text(Color(red: 81.0 / 255.0, green: 68.0 / 255.0, blue: 62.0 / 255.0))
    }
}
