import SwiftUI

/// Whole onboarding flow. Header ("x of 8", progress bar, title) is static;
/// only the card moves. Swipe right = Yes, swipe left = No, then the next card appears.
/// The back button is the native navigation-bar button (needs a NavigationStack above this view).
struct OnboardingFlowView: View {
    var questions: [OnboardingCardQuestion]
    var totalSteps: Int
    /// Called after the last card is answered. Keys are `OnboardingCardQuestion.id`.
    var onFinish: ([Int: OnboardingAnswer]) -> Void

    init(
        questions: [OnboardingCardQuestion] = OnboardingCardQuestion.all,
        totalSteps: Int = OnboardingCardQuestion.totalSteps,
        onFinish: @escaping ([Int: OnboardingAnswer]) -> Void = { _ in }
    ) {
        self.questions = questions
        self.totalSteps = totalSteps
        self.onFinish = onFinish
    }

    @Environment(\.dismiss) private var dismiss   // back button on the first card

    @State private var index = 0                  // card currently on screen
    @State private var step = 0                   // drives counter + progress bar
    @State private var answers: [Int: OnboardingAnswer] = [:]
    @State private var dragX: CGFloat = 0
    @State private var cardScale: CGFloat = 1
    @State private var cardOpacity: Double = 1
    @State private var isBusy = false             // ignore input while a transition runs
    @State private var hapticTick = 0             // bump to fire a light haptic
    @State private var screenWidth: CGFloat = 430 // used by the toolbar back button

    private let swipeThreshold: CGFloat = 110
    private let exitDuration = 0.22

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                header

                Text("Does this sound like you?")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(OBColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.leading, 36)
                    .padding(.top, 46)

                card(width: geo.size.width)
                    .padding(.horizontal, 40)
                    .padding(.top, 21)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear { screenWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, newWidth in screenWidth = newWidth }
        }
        .background(Color.white.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        // Native navigation bar + back button
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    goBack(width: screenWidth)
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
                .tint(OBColor.ink)
                .accessibilityLabel("Back")
            }
        }
    }

    // MARK: - Static header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            counter
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 53)

            // Figma uses 36pt leading / 52pt trailing for the bar – tweak here if you want it symmetric.
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? OBColor.progressOn : OBColor.progressOff)
                        .frame(height: 6)
                }
            }
            .padding(.top, 10)
            .padding(.leading, 36)
            .padding(.trailing, 52)
        }
    }

    private var counter: some View {
        HStack(spacing: 0) {
            Text("\(step + 1)")
                .bold()
                .foregroundStyle(OBColor.progressOn)
            Text(" of ")
                .foregroundStyle(OBColor.muted)
            Text("\(totalSteps)")
                .bold()
                .foregroundStyle(OBColor.progressOn)
        }
        .font(.system(size: 15, weight: .semibold))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(step + 1) of \(totalSteps)")
    }

    // MARK: - Swipeable card

    private func card(width: CGFloat) -> some View {
        SwipeQuestionCard(question: questions[index],
                          swipeProgress: max(-1, min(1, dragX / (swipeThreshold * 1.5))),
                          onNo: { commit(.no, width: width) },
                          onYes: { commit(.yes, width: width) })
            .rotationEffect(.degrees(Double(max(-20, min(20, dragX / 18)))), anchor: .bottom)
            .offset(x: dragX)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .simultaneousGesture(dragGesture(width: width))
            .accessibilityAction(named: "Answer yes") { commit(.yes, width: width) }
            .accessibilityAction(named: "Answer no") { commit(.no, width: width) }
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !isBusy else { return }
                dragX = value.translation.width
            }
            .onEnded { value in
                guard !isBusy else { return }
                let travelled = value.translation.width
                let flick = value.predictedEndTranslation.width
                if abs(travelled) > swipeThreshold {
                    commit(travelled > 0 ? .yes : .no, width: width)
                } else if abs(flick) > swipeThreshold * 2.5 {
                    commit(flick > 0 ? .yes : .no, width: width)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragX = 0 }
                }
            }
    }

    // MARK: - Navigation

    private func commit(_ answer: OnboardingAnswer, width: CGFloat) {
        guard !isBusy else { return }
        isBusy = true
        hapticTick += 1

        answers[questions[index].id] = answer
        let direction: CGFloat = answer == .yes ? 1 : -1

        // 1. fly the card off screen
        withAnimation(.easeIn(duration: exitDuration)) { dragX = direction * width * 1.2 }

        DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
            guard index + 1 < questions.count else {
                onFinish(answers)
                // If this view stays in the hierarchy (e.g. pushed screen), bring the last card back quietly.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withoutAnimation { dragX = 0 }
                    isBusy = false
                }
                return
            }

            // 2. swap to the next card (hidden, slightly smaller)…
            withoutAnimation {
                index += 1
                dragX = 0
                cardScale = 0.92
                cardOpacity = 0
            }
            withAnimation(.easeInOut(duration: 0.25)) { step = index }

            // 3. …and spring it in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    cardScale = 1
                    cardOpacity = 1
                }
                isBusy = false
            }
        }
    }

    private func goBack(width: CGFloat) {
        guard !isBusy else { return }
        guard index > 0 else { dismiss(); return }
        isBusy = true
        hapticTick += 1

        // 1. current card shrinks away
        withAnimation(.easeIn(duration: 0.15)) {
            cardScale = 0.92
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // 2. previous card waits off-screen on the side it was swiped to…
            let previous = questions[index - 1]
            let side: CGFloat = answers[previous.id] == .no ? -1 : 1
            withoutAnimation {
                index -= 1
                dragX = side * width * 1.2
                cardScale = 1
                cardOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.25)) { step = index }

            // 3. …then slides back in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { dragX = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isBusy = false }
            }
        }
    }

    private func withoutAnimation(_ body: () -> Void) {
        var t = Transaction(animation: nil)
        t.disablesAnimations = true
        withTransaction(t, body)
    }
}

#Preview {
    NavigationStack { OnboardingFlowView() }
}
