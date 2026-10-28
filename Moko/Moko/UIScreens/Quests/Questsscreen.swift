//
//  QuestsScreen.swift
//  Moko
//
//  Quests tab. Reads this user's quests from SwiftData with @Query.
//  No quests: "No Active Quest" card. Otherwise: category chips and quests
//  grouped by day. The + button opens NewQuestScreen, which saves to SwiftData.
//

import SwiftUI
import SwiftData

private enum QuestsRoute: Identifiable {
    case newQuest
    case detail(Quest)

    var id: String {
        switch self {
        case .newQuest:          return "new"
        case .detail(let quest): return quest.id.uuidString
        }
    }
}

struct QuestsScreen: View {
    @Environment(\.modelContext) private var modelContext

    /// Only this user's quests, soonest first. @Query keeps the list up to date.
    @Query private var quests: [Quest]

    /// nil means "All"
    @State private var filter: QuestCategory?
    @State private var route: QuestsRoute?

    private let chipOptions: [QuestCategory?] = [nil] + QuestCategory.allCases.map { Optional($0) }

    init() {
        let userID = CurrentUser.localID
        _quests = Query(filter: #Predicate<Quest> { $0.ownerID == userID }, sort: \Quest.date)
    }

    private struct DayGroup: Identifiable {
        let day: Date
        let quests: [Quest]
        var id: Date { day }
    }

    private var filteredQuests: [Quest] {
        guard let filter else { return quests }
        return quests.filter { $0.category == filter }
    }

    private var groups: [DayGroup] {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: filteredQuests) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted().map { day in
            DayGroup(day: day, quests: byDay[day] ?? [])   // already sorted by date
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            QuestStyle.screenBg
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Quest")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
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
        .fullScreenCover(item: $route) { destination in
            switch destination {
            case .newQuest:
                NewQuestScreen()
            case .detail(let quest):
                QuestDetailScreen(quest: quest)
            }
        }
        // After a quest is added, show the full list so the new quest is visible
        .onChange(of: quests.count) { oldCount, newCount in
            if newCount > oldCount { filter = nil }
        }
    }

    // MARK: Filter chips
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(chipOptions.enumerated()), id: \.offset) { _, option in
                    chip(for: option)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(for option: QuestCategory?) -> some View {
        let isSelected = filter == option

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
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? QuestStyle.green : QuestStyle.subtext)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Capsule().fill(isSelected ? QuestStyle.chipSelectedFill : Color.white))
            .overlay(Capsule().stroke(isSelected ? QuestStyle.chipSelectedBorder : Color.clear, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Content
    @ViewBuilder
    private var content: some View {
        if quests.isEmpty {
            emptyCard(
                title: "No Active Quest",
                message: "Tap below to add a Custom Quest whenever you’re ready, or use explore option to browse library of quests"
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(QuestStyle.title)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(QuestStyle.subtext)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 34)
        .padding(.top, 70)
    }

    private var questList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groups) { group in
                    Text(QuestFormat.groupTitle(group.day))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(QuestStyle.subtext)
                        .padding(.horizontal, 28)
                        .padding(.top, 26)
                        .padding(.bottom, 10)

                    VStack(spacing: 12) {
                        ForEach(group.quests, id: \.id) { quest in
                            Button {
                                route = .detail(quest)
                            } label: {
                                questCard(quest)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 110) // clear of the add button
        }
    }

    private func questCard(_ quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(quest.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(QuestStyle.title)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
            }

            Text("\(quest.intensity.xp) XP")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(QuestStyle.subtext)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(quest)
                    try? modelContext.save()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: Add button
    private var addButton: some View {
        Button {
            route = .newQuest
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 62, height: 62)
                .background(Circle().fill(QuestStyle.green))
                .shadow(color: QuestStyle.green.opacity(0.35), radius: 10, x: 0, y: 5)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuestsScreen()
        .modelContainer(MokoDatabase.preview)
}
