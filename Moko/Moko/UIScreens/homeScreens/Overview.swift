//
//  Overview.swift
//  Moko
//
//  The Overview tab ("to-do" version): today's mission card with a slide control.
//  The header and Growth cards come from `OverviewScaffold`.
//
//  Flow: slide the mission → `QuestProgress.complete` awards XP → `onStartDebrief`
//  tells `MokoRootView` to open the debrief full screen.
//  Today's mission is created by `MokoRootView`'s `.task`, not here, so it is
//  only ever created once.
//

import SwiftUI
import SwiftData

// Short name so the code below reads `Theme.Colors...` instead of `MokoScreenTheme.Colors...`.
private typealias Theme = MokoScreenTheme

struct Overview: View {
    /// The real quest shown as today's mission. Nil (previews only) means work it out here.
    let mission: Quest?

    /// Called with the mission when the user starts its debrief.
    let onStartDebrief: ((Quest) -> Void)?

    init(mission: Quest? = nil,
         onStartDebrief: ((Quest) -> Void)? = nil) {
        self.mission = mission
        self.onStartDebrief = onStartDebrief
    }

    // MARK: - State Properties

    // SwiftData's "save box". Used to complete the quest before the debrief.
    @Environment(\.modelContext) private var modelContext

    // Every saved quest, newest first. Only used when no `mission` is passed in.
    @Query(sort: \Quest.date, order: .reverse) private var allQuests: [Quest]

    /// Set from the slide until the debrief cover has taken over, so the pill cannot flip
    /// to "Slide to Debrief" in the frames between completing and the cover appearing.
    @State private var isHandingOffToDebrief: Bool = false

    /// The quest on the mission card.
    private var activeMission: Quest {
        mission ?? Quest.todaysMission(from: allQuests)
    }

    /// True once the quest is complete — reachable only by leaving a debrief behind, because
    /// completing the mission opens the debrief in the same slide.
    private var isMissionCompleted: Bool {
        activeMission.isCompleted
    }

    /// Held at "Slide to Complete" during the handoff so the label never flashes the next
    /// action before the debrief is on screen.
    private var slideTitle: String {
        isMissionCompleted && !isHandingOffToDebrief ? "Slide to Debrief" : "Slide to Complete"
    }

    var body: some View {
        OverviewScaffold {
            missionCard(for: activeMission)
        }
    }

    // MARK: - Mission

    /// Title, description and the slide control.
    private func missionCard(for quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.gapInner) {
            Text(quest.title)
                .mokoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.textTitle)
                .fixedSize(horizontal: false, vertical: true)

            Text(missionDescription(for: quest))
                .mokoText(Theme.Typeface.body)
                .foregroundStyle(Theme.Colors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            missionAction(for: quest)
                .padding(.top, Theme.Space.gapSection)
        }
        // Cross-fades the slide label when the quest becomes completed.
        .animation(Theme.Motion.crossfade, value: isMissionCompleted)
    }

    /// One slide does the whole thing: the quest is completed (XP and streak awarded) and the
    /// debrief opens in the same gesture. Afterwards the same pill reads "Slide to Debrief".
    private func missionAction(for quest: Quest) -> some View {
        MokoSlideControl(label: slideTitle) {
            isHandingOffToDebrief = true
            if !isMissionCompleted {
                QuestProgress.complete(quest, in: modelContext)
            }
            openDebrief(for: quest)

            // The cover needs a beat to cover the card; only then may the pill reflect
            // the new state (it is behind the debrief by that point).
            // `Task` starts a small background job so the slide doesn't have to wait.
            Task {
                try? await Task.sleep(for: .milliseconds(1_200))
                isHandingOffToDebrief = false
            }
        }
        // `MokoSlideControl` stays completed once slid, so a new label gets a fresh control:
        // "Slide to Debrief" must still be draggable after the cover closes.
        .id("\(quest.id)-\(slideTitle)")
    }

    /// The fallback mission isn't saved yet, so it is saved first: the debrief needs a real record.
    private func openDebrief(for quest: Quest) {
        if quest.modelContext == nil {
            modelContext.insert(quest)
            modelContext.saveOrLog("mission before debrief")
        }
        onStartDebrief?(quest)
    }

    /// A description built from the quest's notes or category and intensity.
    private func missionDescription(for quest: Quest) -> String {
        let trimmed = quest.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return "A \(quest.intensity.rawValue.lowercased()) \(quest.category.rawValue.lowercased()) quest. Take your time and go at your pace."
    }
}

#Preview {
    Overview()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
