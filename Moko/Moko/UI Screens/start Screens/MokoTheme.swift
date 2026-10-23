//
//  MokoTheme.swift
//  Moko
//
//  Design tokens and shared styles for Moko Start Screens.
//

import SwiftUI

enum MokoTheme {
   
    
    static let background = Color(red: 250/255, green: 247/255, blue: 242/255)
    
   
    static let forestGreen = Color(red: 30/255, green: 59/255, blue: 43/255)
    
    
    static let forestGreenPressed = Color(red: 23/255, green: 46/255, blue: 34/255)
    
    
    static let textPrimary = Color(red: 28/255, green: 30/255, blue: 29/255)
    
    
    static let textSecondary = Color(red: 83/255, green: 90/255, blue: 85/255)
    
    
    static let textTertiary = Color(red: 142/255, green: 149/255, blue: 143/255)
    
    
    static let borderLight = Color(red: 226/255, green: 223/255, blue: 215/255)
    
    
    static let cardBackground = Color.white
    
    
    static let sageAccent = Color(red: 112/255, green: 138/255, blue: 120/255)
    
    
    
    static func playFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}


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
