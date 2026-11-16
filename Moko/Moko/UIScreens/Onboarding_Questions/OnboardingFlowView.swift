//
//  OnboardingFlowView.swift
//  Moko
//
//  The 8 swipe questions. The header ("x of 8", progress bar, title) stays still;
//  only the card moves. Swipe right = Yes, swipe left = No, then the next card appears.
//
//  The Back button lives in the navigation bar, so this view needs a
//  NavigationStack somewhere above it.
//
//  Debug tip: if swipes stop responding, `isBusy` is probably stuck at true —
//  every path through `commit` / `goBack` must set it back to false.
//

import SwiftUI

struct OnboardingFlowView: View {
    var questions: [OnboardingCardQuestion]
    var totalSteps: Int
    /// Called after the last card is answered. Keys are `OnboardingCardQuestion.id`.
    var onFinish: ([Int: OnboardingAnswer]) -> Void
    /// Called when the user taps Back on the very first card.
    /// The parent decides where to navigate (e.g. back to the Welcome screen).
    var onBack: () -> Void

    init(
        questions: [OnboardingCardQuestion] = OnboardingCardQuestion.all,
        totalSteps: Int = OnboardingCardQuestion.totalSteps,
        onFinish: @escaping ([Int: OnboardingAnswer]) -> Void = { _ in },
        onBack: @escaping () -> Void = {}
    ) {
        self.questions = questions
        self.totalSteps = totalSteps
        self.onFinish = onFinish
        self.onBack = onBack
    }

    /// Which card is on screen right now.
    @State private var index = 0
    /// Drives the counter and progress bar. Kept apart from `index` so the
    /// bar can animate on its own while the card swaps instantly.
    @State private var step = 0
    /// Answers so far, keyed by question id.
    @State private var answers: [Int: OnboardingAnswer] = [:]
    /// How far the card is dragged sideways (negative = left).
    @State private var dragX: CGFloat = 0
    // Moves the card up into the air while the swipe hint is showing.
    @State private var hintOffsetY: CGFloat = 0
    @State private var cardScale: CGFloat = 1
    @State private var cardOpacity: Double = 1
    /// True while a card is flying in/out, so extra taps and drags are ignored.
    @State private var isBusy = false
    /// Increase by 1 to play a light haptic (see `.sensoryFeedback` below).
    @State private var hapticTick = 0
    /// Screen width, saved so the toolbar Back button (outside GeometryReader) can use it.
    @State private var screenWidth: CGFloat = 430
    /// True after the first-card swipe hint has played, so it never repeats.
    @State private var hintPlayed = false

    /// How far (in points) a drag must travel to count as an answer.
    private let swipeThreshold: CGFloat = 110
    private let exitDuration = 0.22

    var body: some View {
        // GeometryReader gives us the screen width so cards can fly fully off-screen.
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
            // `initial: true` also runs this once on first show, so we get the starting width too.
            .onChange(of: geo.size.width, initial: true) { _, newWidth in
                screenWidth = newWidth
            }
        }
        .background(MokoBackdrop())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        // After the first card settles, nudge it left then right to show the user
        // they can swipe. Only plays once, only on card 0.
        .task {
            await playSwipeHintIfNeeded()
        }
        // Replace the system Back button with our own, so Back steps through cards first.
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
                .tint(MokoTheme.forestGreen)
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

            // One capsule per question; filled up to the current one.
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

    /// "3 of 8"
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
        // VoiceOver reads one clear sentence instead of three fragments.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(step + 1) of \(totalSteps)")
    }

    // MARK: - Swipeable card

    private func card(width: CGFloat) -> some View {
        SwipeQuestionCard(question: questions[index],
                          // -1...1: how close the drag is to counting as No / Yes.
                          swipeProgress: max(-1, min(1, dragX / (swipeThreshold * 1.5))),
                          onNo: { commit(.no, width: width) },
                          onYes: { commit(.yes, width: width) })
            // Tilt up to 20° while dragging, pivoting at the bottom like a real card.
            .rotationEffect(.degrees(Double(max(-20, min(20, dragX / 18)))), anchor: .bottom)
            // Offset sideways when dragged, and upwards when the hint lifts the card.
            .offset(x: dragX, y: hintOffsetY)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            // `simultaneous` so the NO / YES buttons inside still get their taps.
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
                // Where the finger *would* end up if it kept moving — catches quick flicks.
                let flick = value.predictedEndTranslation.width
                if abs(travelled) > swipeThreshold {
                    commit(travelled > 0 ? .yes : .no, width: width)
                } else if abs(flick) > swipeThreshold * 2.5 {
                    commit(flick > 0 ? .yes : .no, width: width)
                } else {
                    // Not far enough: spring back to the middle.
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragX = 0 }
                }
            }
    }

    // MARK: - Navigation

    /// Saves the answer, flies the card off, then brings in the next one
    /// (or calls `onFinish` after the last card).
    private func commit(_ answer: OnboardingAnswer, width: CGFloat) {
        guard !isBusy else { return }
        isBusy = true
        hapticTick += 1

        answers[questions[index].id] = answer
        let direction: CGFloat = answer == .yes ? 1 : -1

        // 1. Fly the card off screen in the swipe direction.
        withAnimation(.easeOut(duration: exitDuration)) { dragX = direction * width * 1.2 }

        // `Task` lets us wait between steps without freezing the screen.
        Task {
            try? await Task.sleep(for: .seconds(exitDuration))

            guard index + 1 < questions.count else {
                onFinish(answers)
                // If this view stays on screen (e.g. it was pushed), quietly bring the last card back.
                try? await Task.sleep(for: .milliseconds(600))
                withoutAnimation { dragX = 0 }
                isBusy = false
                return
            }

            // 2. Swap to the next card while it's hidden and slightly smaller…
            withoutAnimation {
                index += 1
                dragX = 0
                hintOffsetY = 0
                cardScale = 0.92
                cardOpacity = 0
            }
            withAnimation(.easeInOut(duration: 0.25)) { step = index }

            // 3. …then spring it in. The tiny pause lets SwiftUI draw the hidden state first.
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1
                cardOpacity = 1
            }
            isBusy = false
        }
    }

    /// Goes back one card, or leaves the screen if we're on the first card.
    private func goBack(width: CGFloat) {
        guard !isBusy else { return }
        // On the first card, ask the parent to handle navigation instead of dismissing.
        guard index > 0 else { onBack(); return }
        isBusy = true
        hapticTick += 1

        // 1. Current card shrinks away.
        withAnimation(.easeOut(duration: 0.15)) {
            cardScale = 0.92
            cardOpacity = 0
        }

        Task {
            try? await Task.sleep(for: .milliseconds(150))

            // 2. Previous card waits off-screen on the side it was swiped to…
            let previous = questions[index - 1]
            let side: CGFloat = answers[previous.id] == .no ? -1 : 1
            withoutAnimation {
                index -= 1
                dragX = side * width * 1.2
                hintOffsetY = 0
                cardScale = 1
                cardOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.25)) { step = index }

            // 3. …then slides back in.
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { dragX = 0 }
            try? await Task.sleep(for: .milliseconds(400))
            isBusy = false
        }
    }

    // MARK: - First-card swipe hint

    /// Gently lifts the first card and tilts it left and right twice to teach swiping.
    /// Does nothing if the card has already been answered or the hint already played.
    @MainActor
    private func playSwipeHintIfNeeded() async {
        // Only run on the very first card and only once per session.
        guard index == 0, !hintPlayed else { return }

        // Let the spring-in animation finish before we start nudging.
        try? await Task.sleep(for: .milliseconds(900))

        // Guard again: user may have already swiped during the delay.
        guard index == 0, !isBusy else { return }

        // Lock interaction so a drag mid-hint can't fight the animation.
        isBusy = true
        hintPlayed = true

        // 1. Lift the card up into the air for the duration of the tutorial hint.
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            hintOffsetY = -20
        }
        try? await Task.sleep(for: .milliseconds(300))

        // The nudge distance – enough to show visible tilt but nowhere near the commit threshold.
        let nudge: CGFloat = 42

        // Run the swipe animation for two complete cycles.
        for _ in 0..<2 {
            guard index == 0 else { break }

            // Tilt left (swipe-No side) so the user sees "you can swipe left for no".
            withAnimation(.easeInOut(duration: 0.32)) { dragX = -nudge }
            try? await Task.sleep(for: .milliseconds(340))

            // Spring back to centre.
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { dragX = 0 }
            try? await Task.sleep(for: .milliseconds(280))

            guard index == 0 else { break }

            // Tilt right (swipe-Yes side) so the user sees "you can swipe right for yes".
            withAnimation(.easeInOut(duration: 0.32)) { dragX = nudge }
            try? await Task.sleep(for: .milliseconds(340))

            // Spring back to centre.
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { dragX = 0 }
            try? await Task.sleep(for: .milliseconds(280))
        }

        // 2. Put the card back down into its resting place.
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            hintOffsetY = 0
        }
        try? await Task.sleep(for: .milliseconds(380))

        // Unlock: the user can now swipe freely.
        isBusy = false
    }

    /// Changes state instantly, with no animation, even if an animation is already running.
    private func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }
}

#Preview {
    NavigationStack { OnboardingFlowView() }
}
