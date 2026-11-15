//
//  MokoTheme.swift
//  Moko
//
//  Design tokens using only the official Moko brand palette.
//

import SwiftUI

enum MokoTheme {
    // MARK: - Core Brand Colors
    
    /// Forest Green: #1B422F (27, 66, 47)
    static let forestGreen = Color(red: 27.0 / 255.0, green: 66.0 / 255.0, blue: 47.0 / 255.0)

    /// Pale lime canvas used across the Relax screens: #F6FAE8.
    static let limeBackground = Color(red: 246.0 / 255.0, green: 250.0 / 255.0, blue: 232.0 / 255.0)

    /// Selected control fill: #E2F5B1.
    static let limeSelected = Color(red: 226.0 / 255.0, green: 245.0 / 255.0, blue: 177.0 / 255.0)

    /// Warm title brown used across the Relax screens: #5C4330.
    static let titleBrown = Color(red: 92.0 / 255.0, green: 67.0 / 255.0, blue: 48.0 / 255.0)

    static let bodyBrown = Color(red: 81.0 / 255.0, green: 68.0 / 255.0, blue: 62.0 / 255.0)
    
    /// White: #FFFFFF (255, 255, 255)
    static let white = Color(red: 255/255, green: 255/255, blue: 255/255)
    
    /// Warm Neutral: #F7F5F2 (247, 245, 242)
    static let warmNeutral = Color(red: 247/255, green: 245/255, blue: 242/255)
    
    // MARK: - Supporting Neutral Colors
    
    /// Divider Gray: #E5E5E5 (229, 229, 229)
    static let dividerGray = Color(red: 229/255, green: 229/255, blue: 229/255)
    
    /// Primary Text: #262626 (38, 38, 38)
    static let primaryText = titleBrown
    
    // MARK: - Semantic Mappings (Strictly using the above colors)
    
    /// Screen background
    static let background = limeBackground
    
    /// Card and text field background
    static let cardBackground = Color(red: 250.0 / 255.0, green: 253.0 / 255.0, blue: 241.0 / 255.0)
    
    /// Primary heading text
    static let textPrimary = titleBrown
    
    /// Secondary description / subtitle text
    static let textSecondary = bodyBrown
    
    /// Muted placeholder text
    static let textTertiary = Color(red: 111.0 / 255.0, green: 103.0 / 255.0, blue: 98.0 / 255.0)
    
    /// Subtle borders and divider lines
    static let borderLight = dividerGray
    
    // MARK: - Haptic Feedback Helper
    
    static func playFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func playNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Primary Button Style
struct MokoPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    MokoTheme.playFeedback(.light)
                }
            }
    }
}
