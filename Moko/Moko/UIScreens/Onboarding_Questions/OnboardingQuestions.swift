//
//  OnboardingQuestions.swift
//  Moko
//
//  The data for the 8 "Does this sound like you?" swipe cards.
//  To change a question or its picture, edit `OnboardingCardQuestion.all`.
//
//  The pictures are the vector mascot scenes from the Purist board
//  "Moko – Onboarding Mascots", one SVG per question.
//

import Foundation

/// The user's answer to one card.
enum OnboardingAnswer: Equatable {
    case yes   // swipe right
    case no    // swipe left
}

/// One swipe card: a question plus its illustration and reflection copy.
struct OnboardingCardQuestion: Identifiable, Equatable {
    /// Stable number (1...8). Answers are stored by this id, so don't renumber.
    let id: Int
    let text: String
    /// Name of the illustration in the asset catalog.
    let imageName: String
    /// Height of the illustration inside the card.
    var imageHeight: CGFloat = 170
    /// Small all-caps chip at the top of the card.
    var category = "COMMUNICATION & HONESTY"
    /// Heading inside the reflection box.
    var reflectionTitle = "BE HONEST, EVEN WHEN IT'S HARD"
    /// One calm sentence under the reflection heading.
    var reflectionBody = "Notice what you avoid, and how that choice sits with you."
    /// Points the card awards.
    var xp = 150
}

extension OnboardingCardQuestion {
    /// The progress bar always shows this many segments ("1 of 8").
    static let totalSteps = 8

    /// One entry = one screen, in order.
    static let all: [OnboardingCardQuestion] = [
        .init(id: 1,
              text: "Is there something you’ve wanted to tell a close friend or family member, but haven’t said yet?",
              imageName: "mascot_scene_q1",
              category: "COMMUNICATION & HONESTY",
              reflectionTitle: "BE HONEST, EVEN WHEN IT'S HARD",
              reflectionBody: "Reflect on how avoiding this conversation might be affecting your relationships and your own peace of mind."),
        .init(id: 2,
              text: "When something’s bothering you, do you usually keep it to yourself even around people you trust?",
              imageName: "mascot_scene_q2",
              category: "SELF EXPRESSION",
              reflectionTitle: "LET PEOPLE IN",
              reflectionBody: "Think about what staying quiet protects you from, and what it quietly costs."),
        .init(id: 3,
              text: "In a group setting, do you usually wait for others to speak first before sharing your own opinion?",
              imageName: "mascot_scene_q3",
              category: "CONFIDENCE",
              reflectionTitle: "YOUR VOICE MATTERS",
              reflectionBody: "Notice the moments you hold back, and what you tell yourself before you do."),
        .init(id: 4,
              text: "Have you skipped joining something (a club, an event, a group chat) because you weren’t sure you’d fit in?",
              imageName: "mascot_scene_q4",
              category: "BELONGING",
              reflectionTitle: "TAKE UP SPACE",
              reflectionBody: "Think about the rooms you avoid, and whether the fear is louder than the truth."),
        .init(id: 5,
              text: "Within your existing friend group, is there something honest you’ve avoided saying to avoid an awkward moment?",
              imageName: "mascot_scene_q5",
              category: "FRIENDSHIP",
              reflectionTitle: "SMALL TRUTHS MATTER",
              reflectionBody: "Consider how small unspoken things can slowly grow into distance."),
        .init(id: 6,
              text: "Do you find it hard to say no to family, even when something doesn’t work for you?",
              imageName: "mascot_scene_q6",
              category: "BOUNDARIES",
              reflectionTitle: "SAYING NO IS CARE",
              reflectionBody: "Reflect on the difference between keeping the peace and keeping yourself small."),
        .init(id: 7,
              text: "Do you replay conversations afterward, wondering if you said the wrong thing?",
              imageName: "mascot_scene_q7",
              category: "SELF TALK",
              reflectionTitle: "REPLAYS ARE NOT REALITY",
              reflectionBody: "Notice how your inner reviewer talks to you, and whether it would say that to a friend."),
        .init(id: 8,
              text: "When there’s tension at home, do you tend to stay quiet rather than say how you feel?",
              imageName: "mascot_scene_q8",
              category: "FAMILY & FEELINGS",
              reflectionTitle: "QUIET ISN’T PEACE",
              reflectionBody: "Think about what staying quiet keeps safe, and what it leaves unsaid."),
    ]
}
