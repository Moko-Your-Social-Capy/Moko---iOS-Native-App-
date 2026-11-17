//
//  RelaxCompleteView.swift
//  Moko
//
//  Calm completion view for relaxation activities: slow ripples, breathing mascot,
//  delayed message fade-in, and light haptic feedback.
//

import SwiftUI

/// Calm, meditative completion screen for relaxation activities.
/// Features expanding ripples, breathing mascot, and soft haptic feedback.
struct RelaxCompleteView: View {
    @State private var expand = false
    @State private var showText = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                // Concentric expanding ripples (3 layers)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(MokoScreenTheme.Colors.dataViolet.opacity(0.18))
                        .frame(width: 160, height: 160)
                        .scaleEffect(expand ? 2.2 : 0.6)
                        .opacity(expand ? 0 : 1)
                        .animation(
                            reduceMotion
                                ? .linear(duration: 0)
                                : Animation.easeOut(duration: 3)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.15),
                            value: expand
                        )
                }

                // Breathing mascot in the center
                MokoMascot(mood: .idle, size: 130)
            }

            // Delayed message fade-in
            Text("Nicely done. Take one slow breath.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                .multilineTextAlignment(.center)
                .opacity(showText ? 1 : 0)
                .animation(
                    reduceMotion
                        ? .linear(duration: 0)
                        : MokoMotion.calm.delay(0.8),
                    value: showText
                )
        }
        .padding(32)
        .sensoryFeedback(.impact(weight: .light), trigger: showText)
        .onAppear {
            if !reduceMotion {
                expand = true
                showText = true
            } else {
                // If reduce motion is on, just show text immediately
                showText = true
            }
        }
    }
}

#Preview {
    RelaxCompleteView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MokoScreenTheme.Colors.canvasTop)
}
