//
//  CelebrationOverlay.swift
//  Moko
//
//  Reusable celebration effect overlay: falling confetti or bouncing balls.
//  Respects accessibility reduce motion setting.
//

import SwiftUI

enum CelebrationStyle {
    case confetti
    case balls
}

/// Overlay that displays falling confetti or bouncing balls.
/// Use with .celebration($showEffect) modifier.
struct CelebrationOverlay: View {
    var style: CelebrationStyle = .confetti
    var duration: Double = 3.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start = Date()
    @State private var pieces: [Piece]

    struct Piece {
        let x: Double              // horizontal position (0...1)
        let size: Double
        let speed: Double          // pixels per second
        let spin: Double           // rotation speed
        let delay: Double          // delay before starting
        let decay: Double          // bounce decay rate
        let color: Color
    }

    init(style: CelebrationStyle = .confetti, duration: Double = 3.5) {
        self.style = style
        self.duration = duration

        let count = style == .confetti ? 70 : 14
        let palette: [Color] = [
            MokoScreenTheme.Colors.dataVioletDeep,
            MokoScreenTheme.Colors.dataViolet,
            MokoScreenTheme.Colors.surfaceLavender,
            Color(hex: 0x7C3AED),  // vibrant violet
            Color(hex: 0x10B981),  // mint
        ]

        _pieces = State(initialValue: (0..<count).map { i in
            Piece(
                x: .random(in: 0.05...0.95),
                size: style == .confetti ? .random(in: 6...12) : .random(in: 16...28),
                speed: .random(in: 250...450),
                spin: .random(in: -6...6),
                delay: .random(in: 0...(style == .confetti ? 0.6 : 0.9)),
                decay: .random(in: 0.9...1.4),
                color: palette[i % palette.count]
            )
        })
    }

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSince(start)
                    // Fade out during the last 0.5s
                    let fade = max(0, min(1, (duration - t) / 0.5))

                    for p in pieces {
                        let lt = t - p.delay
                        guard lt > 0 else { continue }

                        var c = ctx
                        c.opacity = fade

                        switch style {
                        case .confetti:
                            // Gravity: y = speed*t + 0.5*g*t^2 with sideways sway
                            let g: Double = 300
                            let y = -20 + p.speed * lt + 0.5 * g * lt * lt
                            guard y < size.height + 20 else { continue }

                            c.translateBy(
                                x: p.x * size.width + sin(lt * 3 + p.spin) * 20,
                                y: y
                            )
                            c.rotate(by: .radians(p.spin * lt))
                            c.fill(
                                Path(CGRect(x: 0, y: 0, width: p.size, height: p.size * 0.6)),
                                with: .color(p.color)
                            )

                        case .balls:
                            // Bouncing effect: dampens with each bounce
                            let floorY = size.height - p.size
                            let bounceY = floorY - floorY * exp(-p.decay * lt)
                            let bounceHeight = abs(cos(lt * 3.2))

                            let r = p.size / 2
                            c.fill(
                                Path(ellipseIn: CGRect(
                                    x: p.x * size.width - r,
                                    y: bounceY + bounceHeight * 20 - r,
                                    width: p.size,
                                    height: p.size
                                )),
                                with: .color(p.color)
                            )
                        }
                    }
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .onAppear { start = Date() }
            }
        }
    }
}

/// Modifier to add celebration overlay to any view.
/// Automatically removes itself after duration and fires a success haptic.
extension View {
    func celebration(
        _ isActive: Binding<Bool>,
        style: CelebrationStyle = .confetti,
        duration: Double = 3.5
    ) -> some View {
        overlay {
            if isActive.wrappedValue {
                CelebrationOverlay(style: style, duration: duration)
                    .task {
                        try? await Task.sleep(for: .seconds(duration))
                        isActive.wrappedValue = false
                    }
            }
        }
        .sensoryFeedback(.success, trigger: isActive.wrappedValue) { _, new in new }
    }
}
