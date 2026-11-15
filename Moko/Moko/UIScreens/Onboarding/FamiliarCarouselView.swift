//
//  FamiliarCarouselView.swift
//  Moko
//
//  Intro step 1: a swipeable deck of "does this sound familiar?" cards.
//  The Continue button only appears on the last card.
//
//  Only the cards swipe; the title, dots and button stay put.
//

import SwiftUI

/// One card in the carousel: an illustration plus a quote.
struct Situation {
    let imageName: String
    let quote: String
}

struct FamiliarCarouselView: View {
    var onContinue: () -> Void = {}

    /// The cards, in order. Add more here; the dots and progress bar adapt.
    private let situations: [Situation] = [
        Situation(imageName: "familiar_a",
                  quote: "“Someone took credit for my idea, and I didn’t say anything.”"),
        Situation(imageName: "familiar_b",
                  quote: "“I held my cup at the party, wanting to join in but frozen in place.”"),
        Situation(imageName: "familiar_c",
                  quote: "“A neighbor greeted me in the hallway and my mind went blank instantly.”"),
        Situation(imageName: "familiar_d",
                  quote: "“Everyone was laughing and sharing stories but I could not find an opening to speak.”"),
        Situation(imageName: "familiar_e",
                  quote: "“I rewrote the text three times but kept my phone down without sending it.”")
    ]

    /// Total steps in the whole intro flow (progress = card number / this).
    private let totalOnboardingSteps: CGFloat = 9
    private let cardHeight: CGFloat = 446

    /// Index of the card in view. `.scrollPosition(id:)` updates it as the user swipes
    /// (it can be nil mid-swipe, hence the Optional).
    @State private var selection: Int? = 0

    private var index: Int { selection ?? 0 }
    private var isLastCard: Bool { index == situations.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(progress: CGFloat(index + 1) / totalOnboardingSteps)
                .animation(.easeInOut(duration: 0.25), value: index)
                .padding(.horizontal, 20)
                .padding(.top, 47)

            Text("Do these situations sound familiar?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.ink)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
                .padding(.top, 16)

            Spacer(minLength: 24)

            cards

            Spacer(minLength: 24)

            pageDots

            Spacer(minLength: 24)

            OnboardingContinueButton(action: onContinue)
                // Hidden (but still taking space) until the last card,
                // so the layout doesn't jump when it appears.
                .opacity(isLastCard ? 1 : 0)
                .allowsHitTesting(isLastCard)
                .accessibilityHidden(!isLastCard)
                .animation(.easeInOut(duration: 0.25), value: isLastCard)
                .padding(.horizontal, 20)
                .padding(.bottom, 38)
        }
        .background(MokoTheme.limeBackground.ignoresSafeArea())
    }

    // MARK: Swipeable cards

    private var cards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                // `offset` is the card's position (0, 1, 2…) and doubles as its id.
                ForEach(Array(situations.enumerated()), id: \.offset) { i, item in
                    SituationCard(situation: item, height: cardHeight)
                        .padding(.horizontal, 51)
                        // Each card is exactly one screen wide, so paging lands on it.
                        .containerRelativeFrame(.horizontal)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: cardHeight)
    }

    // MARK: Dots

    /// One dot per card; the current one stretches into a terracotta pill.
    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(situations.indices, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.terracotta : Color.dotInactive)
                    .frame(width: i == index ? 24 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: index)
        .accessibilityElement()
        .accessibilityLabel("Card \(index + 1) of \(situations.count)")
    }
}

// MARK: - Card

private struct SituationCard: View {
    let situation: Situation
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Image(situation.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 15)
                .accessibilityHidden(true)               // decorative; the quote says it all

            Spacer(minLength: 8)

            Text(situation.quote)
                .font(.system(size: 20))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 12)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardStroke, lineWidth: 1))
    }
}

#Preview {
    FamiliarCarouselView()
}
