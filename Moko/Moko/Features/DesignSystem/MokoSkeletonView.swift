//
//  MokoSkeletonView.swift
//  Moko
//
//  A light skeleton placeholder shown while content loads. The fade-in uses a calm
//  0.2 second ease so the placeholder does not feel abrupt.

import SwiftUI

struct MokoSkeletonView: View {
    var style: MokoScreenTheme.TextStyle = MokoScreenTheme.Typeface.body
    var lines: Int = 2
    var cornerRadius: CGFloat = MokoScreenTheme.Radius.card

    @Environment(\.mokoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: style.size * 0.3) {
            ForEach(0..<max(1, lines)) { _ in
                RoundedRectangle(cornerRadius: min(cornerRadius, style.leading * 0.35), style: .continuous)
                    .fill(theme.colors.cardSurface.opacity(0.55))
                    .frame(height: style.leading, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isVisible)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isVisible = true
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 2)
        .mokoThemeRoot()
}
