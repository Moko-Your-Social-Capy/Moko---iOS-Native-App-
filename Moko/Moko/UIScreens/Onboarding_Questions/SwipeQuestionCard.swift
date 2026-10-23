import SwiftUI

/// The card only: mascot, illustration, question and the NO / YES buttons.
/// Swiping is handled by `OnboardingFlowView`; the NO / YES labels also work as taps.
struct SwipeQuestionCard: View {
    let question: OnboardingCardQuestion
    /// -1 (dragged fully left = No) … +1 (dragged fully right = Yes)
    var swipeProgress: CGFloat = 0
    var onNo: () -> Void = {}
    var onYes: () -> Void = {}

    private let cornerRadius: CGFloat = 20
    private let cardHeight: CGFloat = 430           // same on every screen (Figma)
    private let mascotSize = CGSize(width: 85, height: 80.7)
    private let cardTopInset: CGFloat = 52          // mascot peeks above the card

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
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)   // 4-line block, centred
                .padding(.horizontal, 36)
                .padding(.top, 30)
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .top)
        // …and the NO / YES buttons pinned to the bottom
        .overlay(alignment: .bottom) { answerButtons }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(OBColor.cardFill)
        )
        // Soft green / red wash while dragging
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill((swipeProgress >= 0 ? OBColor.yes : OBColor.no)
                    .opacity(Double(abs(swipeProgress)) * 0.12))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(OBColor.cardStroke, lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private var answerButtons: some View {
        HStack {
            Button(action: onNo) {
                Text("NO")
                    .foregroundStyle(OBColor.no)
                    .scaleEffect(1 + max(0, -swipeProgress) * 0.2, anchor: .leading)
                    .padding(.vertical, 6)
                    .padding(.trailing, 20)
                    .contentShape(Rectangle())
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
