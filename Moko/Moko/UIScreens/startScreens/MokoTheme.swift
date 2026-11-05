//
//  MokoTheme.swift
//  Moko
//
//  Design tokens using only the official Moko brand palette.
//

import SwiftUI

enum MokoTheme {
    // MARK: - Core Brand Colors
    
    /// Warm Cream: #F6F0E4 (246, 240, 228)
    static let warmCream = Color(red: 246/255, green: 240/255, blue: 228/255)
    
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
    
    /// Muted Brown: #4A3826 (74, 56, 38)
    static let mutedBrown = Color(red: 74/255, green: 56/255, blue: 38/255)
    
    // MARK: - Supporting Neutral Colors
    
    /// Light Gray: #F5F5F5 (245, 245, 245)
    static let lightGray = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    /// Divider Gray: #E5E5E5 (229, 229, 229)
    static let dividerGray = Color(red: 229/255, green: 229/255, blue: 229/255)
    
    /// Secondary Text: #666666 (102, 102, 102)
    static let secondaryText = Color(red: 102/255, green: 102/255, blue: 102/255)
    
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
    
    /// Accent brown detail
    static let accentBrown = mutedBrown
    
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
            .overlay {
                Capsule().stroke(.white.opacity(0.58), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                Capsule().fill(.white.opacity(0.10))
                    .frame(height: 17)
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                    .allowsHitTesting(false)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    MokoTheme.playFeedback(.light)
                }
            }
    }
}

/// Quiet, unfilled companion style for secondary capsule actions.
struct MokoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.75), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Four Petal Floral Ornament
struct MokoFlowerOrnament: View {
    var size: CGFloat = 10
    var color: Color = MokoTheme.forestGreen
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                Circle()
                    .fill(color)
                    .frame(width: size * 0.42, height: size * 0.42)
                    .offset(
                        x: index == 1 ? size * 0.24 : (index == 3 ? -size * 0.24 : 0),
                        y: index == 0 ? -size * 0.24 : (index == 2 ? size * 0.24 : 0)
                    )
            }
            Circle()
                .fill(color)
                .frame(width: size * 0.32, height: size * 0.32)
        }
        .frame(width: size, height: size)
    }
}
