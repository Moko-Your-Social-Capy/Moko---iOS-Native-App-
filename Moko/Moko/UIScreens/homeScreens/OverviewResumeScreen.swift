//
//  OverviewResumeScreen.swift
//  Moko
//
//  The Overview tab ("resume" version): shown when a debrief was left with
//  "Finish Later". The mission card says how far the user got and offers
//  "Slide to Resume". The header and Growth cards come from `OverviewScaffold`.
//

import SwiftUI
import SwiftData

private typealias Theme = MokoScreenTheme

struct OverviewResumeScreen: View {
    /// The quest whose debrief is waiting to be finished.
    var quest: Quest? = nil

    /// Opens the debrief that was left unfinished.
    var onSlideResume: (() -> Void)? = nil

    /// Where the saved conversation stopped, so the user knows nothing was lost.
    private var resumeDescription: String {
        guard let quest, let draft = DebriefDraftStore.load(for: quest.id) else {
            return "Pick up where you left off and share how it went."
        }

        // Only accepted answers count; rejected gibberish never looks like completed coverage.
        let answered = draft.answers.count
        if answered == 0 {
            return "Your debrief is saved. Slide to answer the first question."
        }
        let label = answered == 1 ? "answer" : "answers"
        return "\(answered) \(label) saved. Slide to pick up where you left off."
    }

    var body: some View {
        OverviewScaffold {
            VStack(alignment: .leading, spacing: Theme.Space.gapInner) {
                Text(quest?.title ?? "Unfinished Debrief")
                    .mokoText(Theme.Typeface.cardTitle)
                    .foregroundStyle(Theme.Colors.textTitle)
                    .fixedSize(horizontal: false, vertical: true)

                Text(resumeDescription)
                    .mokoText(Theme.Typeface.body)
                    .foregroundStyle(Theme.Colors.textBody)
                    .fixedSize(horizontal: false, vertical: true)

                // The pill opens the unfinished debrief straight away — no second button.
                MokoSlideControl(label: "Slide to Resume") {
                    onSlideResume?()
                }
                .padding(.top, Theme.Space.gapSection)
            }
        }
    }
}

#Preview {
    OverviewResumeScreen()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
