//
//  MokoCompletionAnimation.swift
//  Moko
//
//  Shared completion animation and reveal modifiers for relaxation and onboarding.
//

import SwiftUI

/// Expanding ring/ripple animation for completion states across relaxation and onboarding.
struct MokoCompletionAnimation: View {
    let ringDiameter: CGFloat
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .stroke(MokoScreenTheme.Colors.dataViolet.opacity(0.4), lineWidth: 2)
                    .frame(width: ringDiameter, height: ringDiameter)
                    .scaleEffect(animate ? 1.6 : 0.8)
                    .opacity(animate ? 0 : 1)
                    .animation(
                        reduceMotion ? .none : .easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(i) * 0.4),
                        value: animate
                    )
            }
            Circle()
                .fill(MokoScreenTheme.Colors.dataViolet.opacity(0.2))
                .frame(width: ringDiameter, height: ringDiameter)
        }
        .onAppear {
            animate = true
        }
    }
}

struct MokoCompletionRevealModifier: ViewModifier {
    var isPresented: Bool = true
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        // Completion effect placeholder or overlay
                    }
                }
            )
    }
}

extension View {
    func mokoCompletionReveal(isPresented: Bool = true) -> some View {
        self.modifier(MokoCompletionRevealModifier(isPresented: isPresented))
    }
}
