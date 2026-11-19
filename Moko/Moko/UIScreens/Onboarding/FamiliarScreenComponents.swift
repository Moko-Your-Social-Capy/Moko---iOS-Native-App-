//
//  FamiliarScreenComponents.swift
//  Moko
//
//  The pieces the familiar onboarding screens are built from:
//  the coloured wave header, the step dashes, one headline line (which can
//  circle a word) and the round next button.
//

import SwiftUI

// MARK: - Palette

/// The bright palette the familiar screens use. Each screen cycles through it.
enum FamiliarPalette {
    /// The big block behind the question.
    static let green = Color(hex: 0xB8F500)
    /// The next button and the step the user is on.
    static let yellow = Color(hex: 0xFFE81A)
    /// The oval drawn around one word.
    static let lavender = Color(hex: 0xC3A6FF)
    /// The fourth colour in the cycle.
    static let blue = Color(hex: 0x0AA5FF)
    /// Question text, the dashes and the arrow.
    static let ink = Color(hex: 0x1B1B1B)

    /// The colour for a screen: yellow, green, lavender, blue, then round again.
    static func tint(for step: Int) -> Color {
        switch step % 4 {
        case 0: yellow
        case 1: green
        case 2: lavender
        default: blue
        }
    }
}

// MARK: - Wave header

/// A colour block whose lower edge rolls like a wave, traced from the design.
struct FamiliarWaveHeader: Shape {
    func path(in rect: CGRect) -> Path {
        // The design was drawn on a 390 x 392 board, so stretch from that.
        let x = rect.width / 390
        let y = rect.height / 392

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 390 * x, y: 0))
        path.addLine(to: CGPoint(x: 390 * x, y: 322 * y))
        // Three soft dips make the wavy bottom edge.
        path.addCurve(
            to: CGPoint(x: 238 * x, y: 324 * y),
            control1: CGPoint(x: 342 * x, y: 356 * y),
            control2: CGPoint(x: 300 * x, y: 302 * y)
        )
        path.addCurve(
            to: CGPoint(x: 60 * x, y: 324 * y),
            control1: CGPoint(x: 176 * x, y: 346 * y),
            control2: CGPoint(x: 120 * x, y: 300 * y)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: 338 * y),
            control1: CGPoint(x: 32 * x, y: 336 * y),
            control2: CGPoint(x: 14 * x, y: 330 * y)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Step dashes

/// Short bars at the top: the steps behind, the step now, the steps left.
struct FamiliarStepDashes: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { step in
                Capsule()
                    // Dark bars so they can be seen on every colour, not just green.
                    .fill(FamiliarPalette.ink.opacity(opacity(for: step)))
                    .frame(width: 34, height: 3)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Situation \(current + 1) of \(total)")
    }

    /// The step being read is solid, the ones behind are faint, the rest fainter.
    private func opacity(for step: Int) -> Double {
        if step == current { return 1 }
        return step < current ? 0.55 : 0.28
    }
}

// MARK: - Headline line

/// One headline line. A single word can sit inside a lavender oval.
struct FamiliarHeadlineLine: View {
    let line: FamiliarSituation.HeadlineLine
    let size: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            if !line.before.isEmpty {
                Text(line.before)
                    .lineLimit(1)
                    // On a very narrow phone the line shrinks instead of clipping.
                    .minimumScaleFactor(0.75)
            }

            if let circled = line.circled {
                circledWord(circled)
            }

            if !line.after.isEmpty {
                Text(line.after)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    // A comma hugs the oval; other words keep a normal space.
                    .padding(.leading, line.after.hasPrefix(",") ? -8 : 0)
            }
        }
        .font(.system(size: size, weight: .black))
        .textCase(.uppercase)
        .foregroundStyle(FamiliarPalette.ink)
    }

    /// One word with the lavender oval drawn around it.
    private func circledWord(_ word: String) -> some View {
        Text(word)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            // Room inside the oval so the word never touches the line.
            .padding(.horizontal, 9)
            .padding(.vertical, 1)
            .overlay {
                // The oval is drawn around the word, not a real border.
                Capsule().stroke(FamiliarPalette.lavender, lineWidth: 3)
            }
    }
}

// MARK: - Nav buttons

/// The round button with a dark arrow in it. Its label changes on the last card.
struct FamiliarNextButton: View {
    let tint: Color
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(tint)
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FamiliarPalette.ink)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLast ? "Continue" : "Next situation")
    }
}

/// A small X that leaves the intro.
struct FamiliarSkipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(FamiliarPalette.ink.opacity(0.85))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip intro")
    }
}
