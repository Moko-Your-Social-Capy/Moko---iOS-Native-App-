//
//  SwipeQuestionCard.swift
//  Moko
//
//  Draws one question card in the Stitch "Swipe Deck" style: a thick black
//  border, a hard offset shadow, a lime category chip, the Purist mascot scene,
//  a purple reflection box and NOT REALLY / VS / DEFINITELY YES.
//
//  It does not handle swiping itself — OnboardingFlowView moves it around and
//  passes `swipeProgress` in so the card can glow and grow the matching button
//  as the user drags.
//

import SwiftUI

struct SwipeQuestionCard: View {
    let question: OnboardingCardQuestion
    /// -1 (dragged fully left = No) … 0 (centered) … +1 (dragged fully right = Yes)
    var swipeProgress: CGFloat = 0
    var onNo: () -> Void = {}
    var onYes: () -> Void = {}

    private let cornerRadius: CGFloat = 28
    /// Same minimum height on every card so the layout never jumps.
    private let cardMinHeight: CGFloat = 470

    /// The active side's colour: lime for Yes (right), terracotta for No (left).
    private var swipeColor: Color {
        swipeProgress >= 0 ? OBDeck.lime : OBColor.no
    }

    /// How strongly the swiped colour shows: 0 at rest, 1 at full drag.
    private var swipeStrength: Double { Double(abs(swipeProgress)) }

    var body: some View {
        // One clean card — no coloured cards peeking behind it.
        card
    }

    // MARK: - Main card

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            chips
            questionTitle
            illustration
            reflectionBox
            // Thin divider keeps the answer row visually separate.
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(height: 1)
            answerButtons
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .top)
        .background(OBDeck.purple, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            // Soft colour wash shows which way the card is being dragged.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(swipeColor.opacity(swipeStrength * 0.10))
                .allowsHitTesting(false)
        }
        .overlay {
            // Thick black border is the heart of the look.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(OBDeck.ink, lineWidth: 3)
        }
        // Coloured glow grows with the drag.
        .shadow(color: swipeColor.opacity(swipeStrength * 0.55), radius: 18, x: 0, y: 8)
        // Hard offset shadow, like a sticker peeled off the page.
        .shadow(color: OBDeck.ink.opacity(0.30), radius: 0, x: 6, y: 6)
    }

    /// Category tag on the left, XP reward on the right.
    private var chips: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(OBDeck.ink)
                    .frame(width: 7, height: 7)
                Text(question.category)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(OBDeck.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(OBDeck.lime, in: Capsule())
            .overlay {
                Capsule().strokeBorder(OBDeck.ink, lineWidth: 2)
            }

            Spacer(minLength: 4)

            Text("+\(question.xp) XP")
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.4)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(OBDeck.ink, in: Capsule())
        }
    }

    /// Big all-caps question with a hard black drop shadow.
    private var questionTitle: some View {
        Text(question.text)
            .font(.system(size: 19, weight: .black, design: .rounded))
            .tracking(-0.3)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .lineLimit(5)
            .minimumScaleFactor(0.72)
            .shadow(color: OBDeck.ink, radius: 0, x: 2, y: 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Just the Purist mascot vectors, transparent background, filling the middle of the card.
    private var illustration: some View {
        Image(question.imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: question.imageHeight)
            .clipShape(Rectangle())
            .accessibilityHidden(true)
    }

    /// Dark purple note that gives the question a calm, reflective frame.
    private var reflectionBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("REFLECT")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(OBDeck.lime)
            Text(question.reflectionTitle)
                .font(.system(size: 12, weight: .heavy))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(question.reflectionBody)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                // Let the sentence wrap to as many lines as it needs.
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OBDeck.purpleDeep, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(OBDeck.ink, lineWidth: 2)
        }
    }

    /// NO on the left, YES on the right. The matching side grows while dragging.
    private var answerButtons: some View {
        HStack(spacing: 8) {
            Button(action: onNo) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                    Text("NOT REALLY")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(0.3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(OBDeck.ink, in: Capsule())
                .scaleEffect(1 + max(0, -swipeProgress) * 0.1, anchor: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Not really")

            Text("VS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(OBDeck.ink)
                .frame(width: 38, height: 38)
                .background(.white, in: Circle())
                .overlay {
                    Circle().strokeBorder(OBDeck.ink, lineWidth: 2)
                }

            Button(action: onYes) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                    Text("DEFINITELY YES")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(0.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(OBDeck.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(OBDeck.lime, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(OBDeck.ink, lineWidth: 2)
                }
                .scaleEffect(1 + max(0, swipeProgress) * 0.1, anchor: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Definitely yes")
        }
    }
}

#Preview {
    SwipeQuestionCard(question: OnboardingCardQuestion.all[0])
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(OBDeck.screen)
}
