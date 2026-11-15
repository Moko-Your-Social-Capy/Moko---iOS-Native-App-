//
//  MokoFlossLoadingView.swift
//  Moko
//
//  The "please wait" view. Big versions show the mascot above a spinner;
//  small versions show only the spinner so they fit inside buttons and rows.
//

import SwiftUI

struct MokoFlossLoadingView: View {
    /// Width and height of the whole loader.
    var size: CGFloat = 112

    // The phone setting "Reduce Motion". If it is on, we show a still icon, not a spinner.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Below this size the mascot would be too tiny to recognise, so we hide it.
    private let mascotMinimumSize: CGFloat = 60

    var body: some View {
        VStack(spacing: 8) {
            if size >= mascotMinimumSize {
                Image("MokoMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: size * 0.7)
            }

            if reduceMotion {
                Image(systemName: "hourglass")
            } else {
                ProgressView()
                    .tint(MokoScreenTheme.Colors.dataVioletDeep)
            }
        }
        .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
        .frame(width: size, height: size)
        // VoiceOver reads one word, "Loading", instead of each piece.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

#Preview {
    MokoFlossLoadingView()
}
