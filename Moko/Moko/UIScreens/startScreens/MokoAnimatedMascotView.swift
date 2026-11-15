//
//  MokoAnimatedMascotView.swift
//  Moko
//
//  The waving mascot. It hops up a little and fades in one time,
//  then stays still (no looping animation running in the background).
//

import SwiftUI

struct MokoAnimatedMascotView: View {
    /// How wide the mascot is. The height follows the picture's shape.
    var size: CGFloat = 220

    // The phone setting "Reduce Motion". If it is on, we only fade.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // False at the start, true once the mascot has shown up.
    @State private var appeared = false

    var body: some View {
        Image("MokoMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * MokoScreenTheme.Size.mascotAspect)
            // Starts a little lower, then springs into place.
            .offset(y: appeared || reduceMotion ? 0 : size * 0.12)
            .opacity(appeared ? 1 : 0)
            .accessibilityLabel("Moko waves hello")
            // .onAppear runs when the mascot first shows on screen.
            .onAppear {
                withAnimation(reduceMotion ? MokoScreenTheme.Motion.crossfade : MokoScreenTheme.Motion.mascotEntrance) {
                    appeared = true
                }
            }
    }
}

#Preview {
    MokoAnimatedMascotView()
}
