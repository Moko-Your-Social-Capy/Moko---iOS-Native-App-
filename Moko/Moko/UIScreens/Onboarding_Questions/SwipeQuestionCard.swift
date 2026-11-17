//
//  SwipeQuestionCard.swift
//  Moko
//
//  Draws one question card: peeking mascot, illustration, question and NO / YES.
//  It does not handle swiping itself — OnboardingFlowView moves it around and
//  passes `swipeProgress` in so the card can tint, outline, shadow, and grow the
//  matching label as the user drags.
//

import SwiftUI

struct SwipeQuestionCard: View {
    let question: OnboardingCardQuestion
    /// -1 (dragged fully left = No) … 0 (centered) … +1 (dragged fully right = Yes)
    var swipeProgress: CGFloat = 0
    var onNo: () -> Void = {}
    var onYes: () -> Void = {}

    private let cornerRadius: CGFloat = 20
    /// Same height on every card so the layout never jumps between questions.
    private let cardHeight: CGFloat = 430
    private let mascotSize = CGSize(width: 85, height: 80.7)
    /// The card starts this far down so the mascot can peek over its top edge.
    private let cardTopInset: CGFloat = 52

    // MARK: - Computed swipe colours

    /// The active side's colour: green for Yes (right), red for No (left).
    /// At zero the card rests on the neutral stroke colour.
    private var swipeColor: Color {
        swipeProgress >= 0 ? OBColor.yes : OBColor.no
    }

    /// How strongly the swiped colour shows: 0 at rest, 1 at full drag.
    private var swipeStrength: Double { Double(abs(swipeProgress)) }

    /// Stroke colour blends from the resting neutral into the swipe colour as the drag grows.
    private var borderColor: Color {
        OBColor.cardStroke.mix(with: swipeColor, by: swipeStrength)
    }

    /// Border thickness grows from 1 pt at rest up to 2.5 pt at full drag.
    private var borderWidth: CGFloat { 1 + CGFloat(swipeStrength) * 1.5 }

    /// Shadow radius grows from 0 at rest to 14 pt at full drag.
    private var shadowRadius: CGFloat { CGFloat(swipeStrength) * 14 }

    /// Shadow opacity mirrors the drag strength.
    private var shadowOpacity: Double { swipeStrength * 0.45 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            card
                .padding(.top, cardTopInset)

            Image("capybara_peek")
                .resizable()
                .scaledToFit()
                .frame(width: mascotSize.width, height: mascotSize.height)
                .padding(.leading, 2)
                .accessibilityHidden(true)
        }
    }

    // MARK: Card

    private var card: some View {
        // Illustration + question, pinned to the top…
        VStack(spacing: 0) {
            illustration
                .padding(.horizontal, 16)
                .padding(.top, 33)

            Text(question.text)
                .font(.system(size: 20))
                .foregroundStyle(OBColor.ink)
                .multilineTextAlignment(.center)
                // Room for 4 lines, so short and long questions sit at the same height.
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
                .padding(.horizontal, 36)
                .padding(.top, 30)
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .top)
        // …and the NO / YES buttons pinned to the bottom.
        .overlay(alignment: .bottom) { answerButtons }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(OBColor.cardFill)
        )
        // Soft green (Yes) or red (No) wash that gets stronger as you drag.
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill((swipeProgress >= 0 ? OBColor.yes : OBColor.no)
                    .opacity(Double(abs(swipeProgress)) * 0.12))
                .allowsHitTesting(false)                 // let taps pass through to the buttons
        )
        // Coloured outline: blends from the neutral resting stroke to the swipe colour.
        // Grows from 1 pt at rest to 2.5 pt at full drag so the border is clearly visible.
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .allowsHitTesting(false)
        )
        // Coloured glow shadow that matches the border colour, growing with the drag.
        .shadow(
            color: swipeColor.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 0,
            y: 4
        )
    }

    /// NO on the left, YES on the right. The label on the drag side grows up to 20%.
    private var answerButtons: some View {
        HStack {
            Button(action: onNo) {
                Text("NO")
                    .foregroundStyle(OBColor.no)
                    .scaleEffect(1 + max(0, -swipeProgress) * 0.2, anchor: .leading)
                    .padding(.vertical, 6)
                    .padding(.trailing, 20)
                    .contentShape(Rectangle())           // bigger tap area than the text
            }
            .buttonStyle(.plain)
            .accessibilityLabel("No")

            Spacer()

            Button(action: onYes) {
                Text("YES")
                    .foregroundStyle(OBColor.yes)
                    .scaleEffect(1 + max(0, swipeProgress) * 0.2, anchor: .trailing)
                    .padding(.vertical, 6)
                    .padding(.leading, 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Yes")
        }
        .font(.system(size: 22, weight: .bold))
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
    }

    /// Fixed-height frame that the image fills and gets cropped to.
    private var illustration: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: question.imageHeight, maxHeight: question.imageHeight)
            .overlay(
                Image(question.imageName)
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    SwipeQuestionCard(question: OnboardingCardQuestion.all[4])
        .padding(.horizontal, 40)
}
