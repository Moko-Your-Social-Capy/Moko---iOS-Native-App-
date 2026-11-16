//
//  RevealModifier.swift
//  Moko
//
//  Staggered entrance animation: fade + upward rise + subtle scale.
//  Use on cards and list items for smooth content reveals.
//

import SwiftUI

/// Entrance animation modifier: fades in, rises up, and scales from 0.96 → 1.0.
/// Applied with staggered delays per index for sequential reveals.
struct RevealModifier: ViewModifier {
    let index: Int
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 24)
            .scaleEffect(isVisible ? 1 : 0.96)
            .onAppear {
                if !reduceMotion {
                    withAnimation(MokoMotion.snappy.delay(Double(index) * 0.08)) {
                        isVisible = true
                    }
                } else {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Apply staggered entrance reveal to a view.
    /// - Parameter index: Order in the sequence (0, 1, 2, ...). Each adds 0.08s delay.
    func mokoReveal(index: Int = 0) -> some View {
        modifier(RevealModifier(index: index))
    }
}
