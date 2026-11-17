//
//  WavingMokoMascot.swift
//  Moko
//
//  Shared capybara mascot with a gentle waving animation.
//  Used on the "Hello, I'm Moko" intro screen and the "Nice to meet you" welcome screen.
//

import SwiftUI

/// Shows MokoMascot.png with a continuous waving animation driven by TimelineView.
/// The image sways left-right anchored at the bottom centre, like a figure waving.
/// Entrance: scales up from 0.85 and fades in. Reduce Motion: entrance fades only, no sway.
struct WavingMokoMascot: View {
    var size: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
            let t = reduceMotion ? 0.0
                : tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100)

            // Cycle = 4.8 s: 3.2 s of waving (3 slow swings) then 1.6 s rest.
            let cycle = t.truncatingRemainder(dividingBy: 4.8)
            let waving = cycle < 3.2

            // Smooth ramp-up / ramp-down in 0.25 s so the motion starts and ends softly.
            let envelope: Double = waving
                ? min(1.0, min(cycle / 0.25, (3.2 - cycle) / 0.25))
                : 0.0

            // 3 full swings over 3.2 s → period ≈ 1.07 s per swing (slow and relaxed).
            let angle = waving ? sin(cycle * .pi * (3.0 / 3.2)) * 18.0 * envelope : 0.0

            Image("MokoMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(angle), anchor: .bottom)
        }
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0.0)
        .offset(y: appeared || reduceMotion ? 0 : size * 0.12)
        .accessibilityLabel("Moko waves hello")
        .onAppear {
            withAnimation(reduceMotion
                ? MokoScreenTheme.Motion.crossfade
                : MokoScreenTheme.Motion.mascotEntrance
            ) {
                appeared = true
            }
        }
    }
}

#Preview {
    WavingMokoMascot(size: 220)
        .padding()
        .background(MokoBackdrop())
}
