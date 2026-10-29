//
//  Colors.swift
//  Moko
//
//  Apple-inspired color palette with liquid glass principles.

import SwiftUI

enum ColorTokens {
    static let brandPrimary = Color(red: 27/255, green: 66/255, blue: 47/255)
    static let surfacePrimary = Color(red: 240/255, green: 242/255, blue: 245/255)
}

extension View {
    func background() -> some View {
        return self.background(ColorTokens.brandPrimary)
    }

    func textPrimary() -> some View {
        return self.text(Color(red: 31/255, green: 41/255, blue: 55/255))
    }

    func textSecondary() -> some View {
        return self.text(Color(red: 107/255, green: 114/255, blue: 128/255))
    }
}
