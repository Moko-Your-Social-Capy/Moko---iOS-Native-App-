//
//  FamiliarCarouselView.swift
//  Moko
//
//  Intro step 1: five full screens that ask "does this sound familiar?".
//  Each screen shows its own quote as the headline, with one word circled.
//  Every screen is its own page in the navigation stack, so the system back
//  button and the edge swipe both work. The arrow moves forward.
//

import SwiftUI

// MARK: - Model

/// One familiar situation: the picture, the words, and how the words break into lines.
struct FamiliarSituation: Identifiable {
    let id: Int
    let imageName: String
    /// The whole sentence. VoiceOver reads this instead of the split lines.
    let quote: String
    /// The headline split into lines, so one word can be circled.
    let headline: [HeadlineLine]
    /// The size that keeps this headline inside the colour header.
    let headlineSize: CGFloat
    /// Height divided by width of the drawing, so it keeps its shape.
    let aspect: CGFloat

    /// A single headline line: words, an optional circled word, then more words.
    struct HeadlineLine: Identifiable {
        let id = UUID()
        var before: String = ""
        var circled: String?
        var after: String = ""
    }
}

extension FamiliarSituation {
    /// The five cards, in swipe order.
    static let all: [FamiliarSituation] = [
        FamiliarSituation(
            id: 0,
            imageName: "familiar_a",
            quote: "Someone took credit for my idea, and I didn’t say anything.",
            headline: [
                .init(before: "SOMEONE TOOK"),
                .init(before: "CREDIT FOR"),
                .init(before: "MY", circled: "IDEA", after: ", AND"),
                .init(before: "I DIDN’T SAY"),
                .init(before: "ANYTHING.")
            ],
            headlineSize: 23,
            aspect: 239.0 / 330.0
        ),
        FamiliarSituation(
            id: 1,
            imageName: "familiar_b",
            quote: "I held my cup at the party, wanting to join in but frozen in place.",
            headline: [
                .init(before: "I HELD MY CUP"),
                .init(before: "AT THE PARTY,"),
                .init(circled: "FROZEN", after: "IN PLACE.")
            ],
            headlineSize: 23,
            aspect: 194.0 / 330.0
        ),
        FamiliarSituation(
            id: 2,
            imageName: "familiar_c",
            quote: "A neighbor greeted me in the hallway and my mind went blank instantly.",
            headline: [
                .init(before: "A NEIGHBOR"),
                .init(before: "GREETED ME IN"),
                .init(before: "THE HALLWAY AND"),
                .init(before: "MY MIND WENT"),
                .init(circled: "BLANK", after: "INSTANTLY.")
            ],
            headlineSize: 22,
            aspect: 225.0 / 330.0
        ),
        FamiliarSituation(
            id: 3,
            imageName: "familiar_d",
            quote: "Everyone was laughing and sharing stories but I could not find an opening to speak.",
            headline: [
                .init(before: "EVERYONE WAS"),
                .init(before: "LAUGHING AND"),
                .init(before: "SHARING STORIES"),
                .init(before: "BUT I COULD NOT"),
                .init(before: "FIND AN"),
                .init(circled: "OPENING", after: "TO SPEAK.")
            ],
            headlineSize: 20,
            aspect: 231.0 / 330.0
        ),
        FamiliarSituation(
            id: 4,
            imageName: "familiar_e",
            quote: "I rewrote the text three times but kept my phone down without sending it.",
            headline: [
                .init(before: "I REWROTE THE"),
                .init(before: "TEXT THREE TIMES"),
                .init(before: "BUT KEPT MY"),
                .init(before: "PHONE DOWN"),
                .init(before: "WITHOUT"),
                .init(circled: "SENDING", after: "IT.")
            ],
            headlineSize: 20,
            aspect: 239.0 / 330.0
        )
    ]
}

// MARK: - Intro

/// The first familiar screen. It is the root of the intro flow.
struct FamiliarIntroView: View {
    /// Called with this screen's number when the arrow is tapped.
    var onAdvance: (Int) -> Void
    /// Called when the X is tapped.
    var onSkip: () -> Void

    var body: some View {
        FamiliarScreen(
            situation: FamiliarSituation.all[0],
            step: 0,
            total: FamiliarSituation.all.count,
            isLast: false,
            onAdvance: { onAdvance(0) },
            onSkip: onSkip
        )
    }
}

// MARK: - Screen

/// One familiar screen: colour wave, headline, picture and round arrow.
struct FamiliarScreen: View {
    let situation: FamiliarSituation
    let step: Int
    let total: Int
    let isLast: Bool
    let onAdvance: () -> Void
    let onSkip: () -> Void

    /// The colour for this screen: yellow, green, lavender, blue, then round again.
    private var tint: Color { FamiliarPalette.tint(for: step) }

    var body: some View {
        // The drawing keeps the design's share of the width, so the layout looks the same on every phone.
        GeometryReader { proxy in
            let artWidth = proxy.size.width * (330.0 / 390.0)
            VStack(spacing: 0) {
                header
                illustration(width: artWidth)
                Spacer(minLength: 0)
                FamiliarNextButton(tint: tint, isLast: isLast, action: onAdvance)
                    .padding(.bottom, 26)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // A white page under everything, like the empty lower half of the design.
            .background(Color.white)
        }
        // The colour block runs behind the status bar and the nav bar.
        .ignoresSafeArea()
        // The back button of the navigation bar uses this dark ink.
        .tint(FamiliarPalette.ink)
        // A tiny tap when this screen becomes the one on show.
        .sensoryFeedback(.selection, trigger: step)
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .topLeading) {
            // The whole block takes this screen's colour.
            FamiliarWaveHeader().fill(tint)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // Keeps the dashes off the left edge, where the system back button sits.
                    Color.clear.frame(width: 32, height: 32)

                    Spacer()
                    FamiliarStepDashes(current: step, total: total)
                    Spacer()

                    FamiliarSkipButton(action: onSkip)
                }

                headline
                    .padding(.top, 34)
            }
            .padding(.horizontal, 24)
            // Leaves room for the phone's status bar at the very top.
            .padding(.top, 60)
        }
        .frame(height: 392)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(situation.headline) { line in
                FamiliarHeadlineLine(line: line, size: situation.headlineSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(situation.quote)
    }

    // MARK: Illustration

    private func illustration(width: CGFloat) -> some View {
        // The drawing comes straight from the Purist boards, so it stays sharp.
        Image(situation.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width * situation.aspect)
            .frame(maxWidth: .infinity)
            // The headline already tells the story, so VoiceOver can skip this.
            .accessibilityHidden(true)
    }
}

#Preview {
    FamiliarIntroView(onAdvance: { _ in }, onSkip: {})
}
