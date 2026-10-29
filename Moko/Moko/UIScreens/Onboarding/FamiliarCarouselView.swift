import SwiftUI

struct Situation: Identifiable {
    let id = UUID()
    let imageName: String
    let quote: String
}

struct FamiliarCarouselView: View {
    var onContinue: () -> Void = {}

    // Add more cards here, in order
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

    // Total steps in your whole onboarding (progress = card number / this)
    private let totalOnboardingSteps: CGFloat = 9

    @State private var selection: Int? = 0

    private var index: Int { selection ?? 0 }
    private var isLastCard: Bool { index == situations.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed: does not swipe
            progressBar
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

            // Only this part swipes
            cards

            Spacer(minLength: 24)

            // Fixed: does not swipe
            pageDots

            Spacer(minLength: 24)

            continueButton
                .padding(.horizontal, 20)
                .padding(.bottom, 38)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.track)
                Capsule().fill(Color.forestLight)
                    .frame(width: geo.size.width * CGFloat(index + 1) / totalOnboardingSteps)
            }
        }
        .frame(height: 3)
        .animation(.easeInOut(duration: 0.25), value: index)
    }

    // MARK: Swipeable cards

    private var cards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(situations.enumerated()), id: \.offset) { i, item in
                    SituationCard(situation: item)
                        .padding(.horizontal, 51)
                        .containerRelativeFrame(.horizontal)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 446)
    }

    // MARK: Dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<situations.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.terracotta : Color.dotInactive)
                    .frame(width: i == index ? 24 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: index)
    }

    // MARK: Continue button (only visible on the last card)

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 8) {
                Text("Continue")
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 50.5)
            .background(Color.forest, in: Capsule())
        }
        .opacity(isLastCard ? 1 : 0)
        .allowsHitTesting(isLastCard)
        .animation(.easeInOut(duration: 0.25), value: isLastCard)
    }
}

// MARK: - Card

private struct SituationCard: View {
    let situation: Situation

    var body: some View {
        VStack(spacing: 0) {
            Image(situation.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 15)

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
        .frame(height: 446)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardStroke, lineWidth: 1))
    }
}

#Preview {
    FamiliarCarouselView()
}
