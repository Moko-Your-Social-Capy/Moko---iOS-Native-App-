import Foundation

enum OnboardingAnswer: Equatable {
    case yes   // swipe right
    case no    // swipe left
}

struct OnboardingCardQuestion: Identifiable, Equatable {
    let id: Int
    let text: String
    /// Name of the illustration in your asset catalog.
    let imageName: String
    /// Height of the illustration inside the card (from the Figma).
    var imageHeight: CGFloat = 198.75
}

extension OnboardingCardQuestion {
    /// The progress bar always shows this many segments ("1 of 8").
    static let totalSteps = 8

    /// One entry = one screen, in order.
    static let all: [OnboardingCardQuestion] = [
        .init(id: 1,
              text: "Is there something you’ve wanted to tell a close friend or family member, but haven’t said yet?",
              imageName: "onboarding_q1"),
        .init(id: 2,
              text: "When something’s bothering you, do you usually keep it to yourself even around people you trust?",
              imageName: "onboarding_q2"),
        .init(id: 3,
              text: "In a group setting, do you usually wait for others to speak first before sharing your own opinion?",
              imageName: "onboarding_q3"),
        .init(id: 4,
              text: "Have you skipped joining something (a club, an event, a group chat) because you weren’t sure you’d fit in?",
              imageName: "onboarding_q4"),
        .init(id: 5,
              text: "Within your existing friend group, is there something honest you’ve avoided saying to avoid an awkward moment?",
              imageName: "onboarding_q5",
              imageHeight: 177.64),
        .init(id: 6,
              text: "Do you find it hard to say no to family, even when something doesn’t work for you?",
              imageName: "onboarding_q6"),
        .init(id: 7,
              text: "Do you replay conversations afterward, wondering if you said the wrong thing?",
              imageName: "onboarding_q7",
              imageHeight: 177.64),
        .init(id: 8,
              text: "When there’s tension at home, do you tend to stay quiet rather than say how you feel?",
              imageName: "onboarding_q8",
              imageHeight: 177.64),
    ]
}
