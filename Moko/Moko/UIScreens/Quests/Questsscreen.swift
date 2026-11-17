//
//  QuestsScreen.swift
//  Moko
//
//  Quests tab. Reads this user's quests from SwiftData with @Query.
//  No quests: "No Active Quest" card. Otherwise: category chips and quests
//  grouped by day. Each card has Edit and Complete buttons; swipe a card
//  right to left to delete it (native red swipe action).
//

import SwiftUI
import SwiftData

/// Which full-screen cover is open. `Identifiable` lets us use `.fullScreenCover(item:)`.
private enum QuestsRoute: Identifiable {
    case newQuest
    case edit(Quest)

    var id: String {
        switch self {
        case .newQuest:           return "new"
        case .edit(let quest):    return "edit-\(quest.id.uuidString)"
        }
    }
}

struct QuestsScreen: View {
    // SwiftData's "save box". Used here to delete quests.
    @Environment(\.modelContext) private var modelContext

    /// Only this user's quests, soonest first. @Query keeps the list up to date.
    @Query private var quests: [Quest]

    // The selected category chip. nil means "All".
    @State private var filter: QuestCategory?
    // Shows placeholder cards while the quest list is loading.
    @State private var isLoading = true
    // The open full-screen cover (new or edit), or nil when none is open.
    @State private var route: QuestsRoute?
    // Setting this pushes the quest briefing. Clearing it pops back.
    @State private var detailQuest: Quest?

    /// "All" (nil) followed by every category.
    private let chipOptions: [QuestCategory?] = [nil] + QuestCategory.allCases

    init() {
        // @Query filters can't read other properties directly, so copy the id into a local first.
        let userID = CurrentUser.localID
        _quests = Query(filter: #Predicate<Quest> { $0.ownerID == userID }, sort: \Quest.date)
    }

    /// One day's heading plus the quests on that day.
    private struct DayGroup: Identifiable {
        let day: Date
        let quests: [Quest]
        var id: Date { day }
    }

    private var customQuests: [Quest] {
        // Library scenarios are started from Explore and should never appear
        // in the Quests tab.
        quests.filter { !$0.isFromLibrary }
    }

    private var filteredQuests: [Quest] {
        guard let filter else { return customQuests }
        return customQuests.filter { $0.category == filter }
    }

    /// Quests grouped by calendar day, earliest day first.
    private var groups: [DayGroup] {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: filteredQuests) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted().map { day in
            DayGroup(day: day, quests: byDay[day] ?? [])   // already sorted by date
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                MokoBackdrop()

                VStack(alignment: .leading, spacing: 0) {
                    Text("Quest")
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 14)

                    filterBar
                        .padding(.top, 22)

                    content
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                addButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .toolbar(.hidden, for: .navigationBar)
            // Do not force the tab bar visible here: on iOS 26+ that overrides
            // the hidden state declared by QuestDetailScreen, so the tab bar
            // would stay on screen during the quest briefing and debrief.
            // Pushes the briefing whenever `detailQuest` is set.
            .navigationDestination(item: $detailQuest) { quest in
                QuestDetailScreen(quest: quest)
            }
        }
        .task {
            isLoading = false
        }
        .fullScreenCover(item: $route) { destination in
            switch destination {
            case .newQuest:
                NewQuestScreen()
            case .edit(let quest):
                NewQuestScreen(quest: quest)
            }
        }
        // After a custom quest is added, show the full list so it is visible.
        // Library scenarios are started from Explore and never affect this screen.
        .onChange(of: customQuests.count) { oldCount, newCount in
            if newCount > oldCount { filter = nil }
        }
    }

    // MARK: Filter chips
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chipOptions, id: \.self) { option in
                    chip(for: option)
                }
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
        }
    }

    private func chip(for option: QuestCategory?) -> some View {
        let isSelected = filter == option
        // A category keeps its own colour all the time; the "All" chip stays neutral.
        let categoryColor = option.map(QuestStyle.categoryColor(for:))
        // Words and icon share one colour, so each chip reads as a single calm pill.
        let ink = categoryColor ?? (isSelected ? QuestStyle.title : QuestStyle.subtext)
        // A selected chip gets a pale wash of its colour, never a heavy block.
        let fill = isSelected
            ? (option.map(QuestStyle.categoryTint(for:)) ?? QuestStyle.chipSelectedFill)
            : Color.white
        // The border only appears when selected, in the same colour as the words.
        let border = isSelected
            ? (categoryColor?.opacity(0.45) ?? QuestStyle.chipSelectedBorder)
            : Color.clear

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filter = option
            }
        } label: {
            HStack(spacing: 5) {
                if let option {
                    Image(systemName: option.symbol)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(option?.rawValue ?? "All")
                    .mokoText(MokoScreenTheme.Typeface.caption)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(border, lineWidth: 1))
            // A soft glow under the selected chip ties the colour to the screen.
            // It is faint on purpose so it calms the eye instead of drawing a box.
            .shadow(color: isSelected ? (categoryColor ?? Color.clear).opacity(0.22) : Color.clear, radius: 6, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    // MARK: Content
    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(alignment: .leading, spacing: 16) {
                MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 1)
                MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 2)
                MokoSkeletonView(style: MokoScreenTheme.Typeface.body, lines: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else if customQuests.isEmpty {
            emptyCard(
                title: "No Active Quest",
                message: "Tap below to add a Custom Quest, or use explore option to browse library of quests"
            )
        } else if filteredQuests.isEmpty {
            emptyCard(
                title: "No \(filter?.rawValue ?? "") Quests",
                message: "Nothing here yet. Tap + to add a quest in this category."
            )
        } else {
            questList
        }
    }

    private func emptyCard(title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Text(title)
                .mokoText(MokoScreenTheme.Typeface.section)
                .foregroundStyle(QuestStyle.title)

            Text(message)
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(QuestStyle.subtext)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(MokoScreenTheme.Space.cardHorizontal)
        .frame(maxWidth: .infinity, minHeight: 250)
        .mokoCard()
        .padding(.horizontal, MokoScreenTheme.Space.page)
        .padding(.top, 70)
    }

    // A List (not a ScrollView) so rows get the native swipe-to-delete action.
    private var questList: some View {
        List {
            ForEach(groups) { group in
                Text(QuestFormat.groupTitle(group.day))
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(QuestStyle.subtext)
                    .listRowInsets(EdgeInsets(top: 18, leading: MokoScreenTheme.Space.page, bottom: 4, trailing: MokoScreenTheme.Space.page))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                ForEach(group.quests, id: \.id) { quest in
                    questCard(quest)
                        .listRowInsets(EdgeInsets(top: 8, leading: MokoScreenTheme.Space.page, bottom: 8, trailing: MokoScreenTheme.Space.page))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(quest)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                        }
                }
            }

            // Space so the last card can scroll clear of the add button.
            Color.clear
                .frame(height: 100)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func questCard(_ quest: Quest) -> some View {
        // A finished debrief is read-only: the card is muted and opens nothing.
        let isDebriefed = quest.debriefRecorded

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .mokoText(MokoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(isDebriefed ? QuestStyle.subtext : QuestStyle.title)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("\(quest.awardedXP) XP")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(isDebriefed ? QuestStyle.subtext : QuestStyle.xpColor(for: quest.awardedXP))

                    if quest.debriefRecorded {
                        Text("· Debrief done")
                            .mokoText(MokoScreenTheme.Typeface.caption)
                            .foregroundStyle(QuestStyle.subtext)
                    } else if quest.isCompleted {
                        Text("· Completed")
                            .mokoText(MokoScreenTheme.Typeface.caption)
                            .foregroundStyle(QuestStyle.subtext)
                    }
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                cardButton(
                    symbol: "pencil",
                    filled: false,
                    label: "Edit quest",
                    isEnabled: !isDebriefed
                ) {
                    route = .edit(quest)
                }

                cardButton(
                    symbol: "checkmark",
                    filled: true,
                    label: "Open quest",
                    isEnabled: !isDebriefed
                ) {
                    detailQuest = quest
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mokoCard(
            fill: isDebriefed ? MokoScreenTheme.Colors.surfaceLavender : MokoScreenTheme.Colors.surfaceWhite,
            lift: !isDebriefed
        )
        // Tapping the card itself still opens the quest briefing; the two buttons take priority.
        .onTapGesture {
            guard !isDebriefed else { return }
            detailQuest = quest
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(isDebriefed ? "Debrief complete" : "")
    }

    /// A round 44pt icon button. `filled` = green with a white icon (the main action).
    private func cardButton(
        symbol: String,
        filled: Bool,
        label: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(
                    isEnabled
                        ? (filled ? Color.white : QuestStyle.title)
                        : (filled ? Color.white.opacity(0.65) : QuestStyle.subtext)
                )
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(
                        isEnabled
                            ? (filled ? QuestStyle.accent : QuestStyle.screenBg)
                            : MokoScreenTheme.Colors.dataGrid
                    )
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    // MARK: Actions

    private func delete(_ quest: Quest) {
        withAnimation {
            modelContext.delete(quest)
            modelContext.saveOrLog("deleted quest")
        }
    }

    // MARK: Add button
    private var addButton: some View {
        Button {
            route = .newQuest
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(Circle().fill(QuestStyle.accent))
                .shadow(color: MokoScreenTheme.Elevation.ambientColor, radius: MokoScreenTheme.Elevation.ambientRadius, x: 0, y: MokoScreenTheme.Elevation.ambientOffset)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add quest")
    }
}

#Preview {
    QuestsScreen()
        .modelContainer(MokoDatabase.preview)
}
