//
//  MokoLoadingView.swift
//  Moko
//
//  Animated loading screen: the Moko capybara waves, bobs and blinks while
//  three dots pulse underneath. Pure SwiftUI vector drawing, so there are no
//  image or animation files to add: just drop this file into the project.
//
//  Usage:
//      MokoLoadingView()                              // full screen
//      MokoLoadingView(message: "Loading your quests…")
//      MokoCapybara().frame(width: 200)               // just the mascot
//
//  Typical launch gate:
//      ZStack {
//          if isLoading { MokoLoadingView().transition(.opacity) }
//          else { RootTabView() }
//      }
//

import SwiftUI

// MARK: - Loading screen

/// Full-screen loading animation showing the SVG capybara with waving and pulsing dots.
/// Displays immediately without zoom effects - just shows the full SVG from the start.
struct MokoLoadingView: View {

    var message: String? = "Getting things ready…"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var idle = false                // waving / bobbing

    @State private var showDots = false

    private let side: CGFloat = 260

    var body: some View {

        GeometryReader { geo in

            let screen = geo.size

            ZStack {

                LinearGradient(colors: [MokoScreenTheme.Colors.canvasTop,
                                        MokoScreenTheme.Colors.canvasBottom],
                               startPoint: .top, endPoint: .bottom)

                MokoCapybara(faceOpacity: 1, isIdle: idle)
                    .frame(width: side, height: side)
                    .position(x: screen.width / 2, y: screen.height / 2 - 60)

                VStack(spacing: 18) {

                    HStack(spacing: 10) {

                        ForEach(0..<3, id: \.self) { index in

                            PulsingDot(delay: Double(index) * 0.15, animates: !reduceMotion)

                        }

                    }

                    if let message {

                        Text(message)
                            .mokoText(MokoScreenTheme.Typeface.body)
                            .foregroundStyle(MokoScreenTheme.Colors.textBody)

                    }

                }
                .position(x: screen.width / 2, y: screen.height / 2 + side / 2 + 56)
                .opacity(showDots ? 1 : 0)

            }
            .frame(width: screen.width, height: screen.height)

        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message ?? "Loading")
        .task { await play() }

    }

    private func play() async {

        guard !reduceMotion else {
            idle = true
            showDots = true
            return
        }

        // Start animations immediately
        idle = true
        
        withAnimation(.easeOut(duration: 0.4)) { showDots = true }

    }

}

private struct PulsingDot: View {
    let delay: Double
    let animates: Bool
    @State private var on = false

    var body: some View {
        Circle()
            .fill(MokoScreenTheme.Colors.dataVioletDeep)
            .frame(width: 11, height: 11)
            .scaleEffect(on ? 1 : 0.6)
            .opacity(on ? 1 : 0.5)
            .animation(animates ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay) : nil,
                       value: on)
            .onAppear { on = true }
    }
}

// MARK: - Animated mascot

/// The capybara, drawn from vector paths on a 1024 x 1024 grid and animated:
/// body bob, waving arm, blinking eyes, pulsing ground shadow.
struct MokoCapybara: View {

    /// 0 hides the face (snout, mouth, eyes, cheeks) so only the orange body shows.
    var faceOpacity: Double = 1

    /// Turns the waving, bobbing and blinking on or off.
    var isIdle: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var bobbing = false

    @State private var waving = false

    @State private var eyesClosed = false

    private enum Ink {

        static let line   = Color(hex: 0x3A1A14)

        static let orange = Color(hex: 0xE89B4F)

        static let brown  = Color(hex: 0x8B5A3C)

        static let snout  = Color(hex: 0xA5693F)

        static let cream  = Color(hex: 0xF7DDB0)

        static let pink   = Color(hex: 0xF08E86)

        static let mouth  = Color(hex: 0x4A2323)

        static let tongue = Color(hex: 0xEE8F92)

        static let eye    = Color(hex: 0x3D1F17)

        static let ground = Color(hex: 0x7DA34A)

    }

    var body: some View {

        // Everything is laid out in a 1024-point square, then scaled to fit.
        GeometryReader { geo in

            let side = min(geo.size.width, geo.size.height)

            ZStack {

                // Ground shadow
                SVGPathShape(d: Self.artShadow)

                    .fill(Ink.ground.opacity(0.55))

                    .scaleEffect(bobbing ? 0.92 : 1, anchor: UnitPoint(x: 518 / 1024, y: 872 / 1024))

                // Character (bobs up and down)
                ZStack {

                    solid(Self.artFootL, Ink.brown)

                    solid(Self.artFootR, Ink.brown)

                    solid(Self.artEarL, Ink.orange)

                    solid(Self.artEarR, Ink.orange)

                    flat(Self.artEarInL, Ink.brown)

                    flat(Self.artEarInR, Ink.brown)

                    solid(Self.artTuft, Ink.orange)

                    solid(Self.artBody, Ink.orange)

                    flat(Self.artBelly, Ink.cream)

                    Group {

                    flat(Self.artCheekL, Ink.pink)

                    flat(Self.artCheekR, Ink.pink)

                    flat(Self.artSnout, Ink.snout)

                    line(Self.artNostrilL, 5)

                    line(Self.artNostrilR, 5)

                    line(Self.artNoseLine, 5)

                    solid(Self.artMouth, Ink.mouth)

                    flat(Self.artTongue, Ink.tongue)

                    line(Self.artChin, 4)

                    line(Self.artBrowL, 4)

                    line(Self.artBrowR, 4)

                    // Eyes blink by squashing vertically around their own centre.
                    flat(Self.artEyeL, Ink.eye)

                        .scaleEffect(y: eyesClosed ? 0.08 : 1,

                                     anchor: UnitPoint(x: 397 / 1024, y: 290 / 1024))

                    flat(Self.artEyeR, Ink.eye)

                        .scaleEffect(y: eyesClosed ? 0.08 : 1,

                                     anchor: UnitPoint(x: 637 / 1024, y: 290 / 1024))

                    flat(Self.artHiL, .white).opacity(eyesClosed ? 0 : 1)

                    flat(Self.artHiR, .white).opacity(eyesClosed ? 0 : 1)

                    flat(Self.artSpL, .white).opacity(eyesClosed ? 0 : 1)

                    flat(Self.artSpR, .white).opacity(eyesClosed ? 0 : 1)

                    }

                    .opacity(faceOpacity)

                    // Waving arm pivots at the shoulder.
                    ZStack {

                        solid(Self.artArm, Ink.orange)

                        solid(Self.artHand, Ink.brown)

                    }

                    .rotationEffect(.degrees(waving ? 10 : -14),

                                    anchor: UnitPoint(x: 335 / 1024, y: 540 / 1024))

                }

                .offset(y: bobbing ? -10 : 0)

            }

            .frame(width: 1024, height: 1024)

            .scaleEffect(side / 1024, anchor: .topLeading)

            .frame(width: side, height: side, alignment: .topLeading)

            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }

        .aspectRatio(1, contentMode: .fit)

        .accessibilityHidden(true)

        .onAppear(perform: start)

        .onChange(of: isIdle) { _, _ in start() }

    }

    // MARK: Animation

    private func start() {

        guard isIdle, !reduceMotion, !bobbing else { return }

        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {

            bobbing = true

        }

        withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {

            waving = true

        }

    }

    // MARK: Layer helpers

    private func solid(_ d: String, _ fill: Color) -> some View {

        SVGPathShape(d: d)

            .fill(fill)

            .overlay(

                SVGPathShape(d: d)

                    .stroke(Ink.line, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

            )

    }

    private func flat(_ d: String, _ fill: Color) -> some View {

        SVGPathShape(d: d).fill(fill)

    }

    private func line(_ d: String, _ width: CGFloat) -> some View {

        SVGPathShape(d: d)

            .stroke(Ink.line, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))

    }

    // MARK: Artwork (SVG path data on a 1024 grid)

    private static let artShadow = "M 738 872 C 738 887.5 639.5 900 518 900 C 396.5 900 298 887.5 298 872 C 298 856.5 396.5 844 518 844 C 639.5 844 738 856.5 738 872 Z"
    private static let artFootL = "M 447 858 C 447 870.2 423.7 880 395 880 C 366.3 880 343 870.2 343 858 C 343 845.8 366.3 836 395 836 C 423.7 836 447 845.8 447 858 Z"
    private static let artFootR = "M 687 858 C 687 870.2 663.7 880 635 880 C 606.3 880 583 870.2 583 858 C 583 845.8 606.3 836 635 836 C 663.7 836 687 845.8 687 858 Z"
    private static let artEarL = "M 430 200 C 430 221.0 413.0 238 392 238 C 371.0 238 354 221.0 354 200 C 354 179.0 371.0 162 392 162 C 413.0 162 430 179.0 430 200 Z"
    private static let artEarR = "M 681 200 C 681 221.0 664.0 238 643 238 C 622.0 238 605 221.0 605 200 C 605 179.0 622.0 162 643 162 C 664.0 162 681 179.0 681 200 Z"
    private static let artEarInL = "M 410 206 C 410 220.4 401.0 232 390 232 C 379.0 232 370 220.4 370 206 C 370 191.6 379.0 180 390 180 C 401.0 180 410 191.6 410 206 Z"
    private static let artEarInR = "M 665 206 C 665 220.4 656.0 232 645 232 C 634.0 232 625 220.4 625 206 C 625 191.6 634.0 180 645 180 C 656.0 180 665 191.6 665 206 Z"
    private static let artTuft = "M 488 188 Q 494 162 512 150 Q 510 166 518 174 Q 526 160 536 154 Q 540 172 546 188 Z"
    private static let artBody = "M 430 195 C 345 240 312 330 318 405 C 322 470 345 520 322 600 C 306 680 300 760 345 820 Q 385 850 445 840 L 585 840 Q 645 850 690 820 C 722 790 735 740 735 690 C 752 680 778 665 778 635 C 778 580 735 510 690 468 C 705 450 722 420 720 385 C 718 300 665 215 590 195 Q 510 165 430 195 Z"
    private static let artBelly = "M 641 672 C 641 740.5 585.0 796 516 796 C 447.0 796 391 740.5 391 672 C 391 603.5 447.0 548 516 548 C 585.0 548 641 603.5 641 672 Z"
    private static let artCheekL = "M 394 362 C 394 378.6 380.6 392 364 392 C 347.4 392 334 378.6 334 362 C 334 345.4 347.4 332 364 332 C 380.6 332 394 345.4 394 362 Z"
    private static let artCheekR = "M 698 362 C 698 378.6 684.6 392 668 392 C 651.4 392 638 378.6 638 362 C 638 345.4 651.4 332 668 332 C 684.6 332 698 345.4 698 362 Z"
    private static let artSnout = "M 515 280 C 470 280 435 300 432 350 C 430 410 470 450 515 450 C 560 450 600 410 598 350 C 595 300 560 280 515 280 Z"
    private static let artNostrilL = "M 460 322 Q 478 336 496 322"
    private static let artNostrilR = "M 534 322 Q 552 336 570 322"
    private static let artNoseLine = "M 515 345 L 515 412"
    private static let artMouth = "M 452 418 Q 482 434 515 412 Q 548 434 578 418 Q 566 470 515 472 Q 464 470 452 418 Z"
    private static let artTongue = "M 541 454 C 541 461.2 529.4 467 515 467 C 500.6 467 489 461.2 489 454 C 489 446.8 500.6 441 515 441 C 529.4 441 541 446.8 541 454 Z"
    private static let artChin = "M 490 490 Q 515 497 540 490"
    private static let artBrowL = "M 395 242 Q 408 236 420 246"
    private static let artBrowR = "M 612 246 Q 625 236 638 242"
    private static let artEyeL = "M 422 290 C 422 307.1 410.8 321 397 321 C 383.2 321 372 307.1 372 290 C 372 272.9 383.2 259 397 259 C 410.8 259 422 272.9 422 290 Z"
    private static let artEyeR = "M 662 290 C 662 307.1 650.8 321 637 321 C 623.2 321 612 307.1 612 290 C 612 272.9 623.2 259 637 259 C 650.8 259 662 272.9 662 290 Z"
    private static let artHiL = "M 415 280 C 415 285.0 411.0 289 406 289 C 401.0 289 397 285.0 397 280 C 397 275.0 401.0 271 406 271 C 411.0 271 415 275.0 415 280 Z"
    private static let artHiR = "M 637 280 C 637 285.0 633.0 289 628 289 C 623.0 289 619 285.0 619 280 C 619 275.0 623.0 271 628 271 C 633.0 271 637 275.0 637 280 Z"
    private static let artSpL = "M 386 297 L 388.52 303.48 L 395 306 L 388.52 308.52 L 386 315 L 383.48 308.52 L 377 306 L 383.48 303.48 Z"
    private static let artSpR = "M 646 297 L 648.52 303.48 L 655 306 L 648.52 308.52 L 646 315 L 643.48 308.52 L 637 306 L 643.48 303.48 Z"
    private static let artArm = "M 332 598 C 302 548 252 482 227 436 C 207 400 237 372 270 378 C 302 386 332 420 388 484 C 402 502 382 532 352 588 Z"
    private static let artHand = "M 296 410 C 296 428.2 278.1 443 256 443 C 233.9 443 216 428.2 216 410 C 216 391.8 233.9 377 256 377 C 278.1 377 296 391.8 296 410 Z"
}

// MARK: - SVG path parser

/// Draws SVG path data (absolute M, L, C, Q, Z only) scaled from a 1024-point grid.
struct SVGPathShape: Shape {
    let d: String

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 1024
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + CGFloat(x) * scale, y: rect.minY + CGFloat(y) * scale)
        }

        // Put spaces around command letters, then split into tokens.
        var spaced = ""
        for ch in d {
            if ch.isLetter { spaced += " \(ch) " } else { spaced.append(ch) }
        }
        let tokens = spaced.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)

        var path = Path()
        var i = 0
        func next() -> Double {
            defer { i += 1 }
            return Double(tokens[i]) ?? 0
        }

        while i < tokens.count {
            let command = tokens[i]
            i += 1
            switch command {
            case "M": path.move(to: point(next(), next()))
            case "L": path.addLine(to: point(next(), next()))
            case "Q":
                let c = point(next(), next())
                let p = point(next(), next())
                path.addQuadCurve(to: p, control: c)
            case "C":
                let c1 = point(next(), next())
                let c2 = point(next(), next())
                let p = point(next(), next())
                path.addCurve(to: p, control1: c1, control2: c2)
            case "Z": path.closeSubpath()
            default: break
            }
        }
        return path
    }
}

#Preview {
    MokoLoadingView()
}