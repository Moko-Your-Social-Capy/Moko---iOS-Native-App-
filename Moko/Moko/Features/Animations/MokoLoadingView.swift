//
//  MokoLoadingView.swift
//  Moko
//
//  Cohesive Moko-themed loader for debriefing, score calculation, and data loading.
//  Uses breathing animation and smooth content transitions.
//

import SwiftUI

/// Moko-themed loading indicator with breathing mascot and optional message.
struct MokoLoadingView: View {
    var message: String = "Calculating your insights..."
    var subtitle: String? = nil

    @State private var isBreathing = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            // Breathing mascot
            MokoMascot(mood: .idle, size: 140)
                .scaleEffect(isBreathing ? 1.08 : 0.95)
                .animation(
                    reduceMotion
                        ? .linear(duration: 0)
                        : Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                    value: isBreathing
                )

            VStack(spacing: 8) {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                }
            }

            // Smooth indeterminate progress capsule
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MokoScreenTheme.Colors.dataViolet.opacity(0.15))

                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MokoScreenTheme.Colors.dataVioletDeep.opacity(0.6),
                                    MokoScreenTheme.Colors.dataVioletDeep
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: g.size.width * 0.4)
                        .offset(x: isBreathing ? g.size.width * 0.6 : -g.size.width * 0.4)
                        .animation(
                            reduceMotion
                                ? .linear(duration: 0)
                                : Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                            value: isBreathing
                        )
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 24)
        }
        .padding(32)
        .onAppear {
            if !reduceMotion {
                isBreathing = true
            }
        }
    }
}

/// Modifier to crossfade between a loading view and content.
extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        ZStack {
            self.opacity(isLoading ? 0 : 1)

            if isLoading {
                MokoLoadingView(message: message)
                    .transition(.opacity)
            }
        }
        .animation(MokoMotion.calm, value: isLoading)
    }
}

#Preview {
    MokoLoadingView(
        message: "Calculating your insights...",
        subtitle: "This usually takes 2-3 seconds"
    )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MokoScreenTheme.Colors.canvasTop)
}
