//
//  QuestLibraryView.swift
//  Moko
//
//  Quest Library screen showing categorized situation cards with horizontal snapping
//  and case-insensitive search filtering.
//

import SwiftUI
import SwiftData

struct QuestLibraryView: View {
    // MARK: - Models
    struct LibraryQuest: Identifiable, Hashable {
        var id: String { title }
        let title: String
        let imageName: String
        let xp: Int
        let tint: Color

        /// The saved quest's intensity, chosen from the XP the library awards.
        var intensity: QuestIntensity {
            switch xp {
            case ...100: return .easy
            case 101...200: return .medium
            default: return .hard
            }
        }
    }

    struct QuestSection: Identifiable, Hashable {
        var id: String { title }
        let title: String
        let category: QuestCategory
        let quests: [LibraryQuest]
    }

    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query private var savedQuests: [Quest]
    @State private var searchText: String = ""
    @State private var openedQuest: Quest?
    @State private var addedToast: AddedQuestToast?
    @State private var addFeedback = 0

    init() {
        let ownerID = CurrentUser.localID
        _savedQuests = Query(
            filter: #Predicate<Quest> { $0.ownerID == ownerID },
            sort: \Quest.createdAt,
            order: .reverse
        )
    }

    // MARK: - Filtered Data
    private var filteredSections: [QuestSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return Self.sections
        }
        let normalizedQuery = query.replacingOccurrences(of: "’", with: "'")
        return Self.sections.compactMap { section in
            let matchingQuests = section.quests.filter { quest in
                let normalizedTitle = quest.title.replacingOccurrences(of: "’", with: "'")
                return normalizedTitle.localizedCaseInsensitiveContains(normalizedQuery)
            }
            guard !matchingQuests.isEmpty else { return nil }
            return QuestSection(title: section.title, category: section.category, quests: matchingQuests)
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(hex: 0xF2F2F7)
                    .ignoresSafeArea()

                if filteredSections.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(filteredSections) { section in
                                sectionView(for: section)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }

                if let addedToast {
                    QuestAddedBanner(
                        title: addedToast.title,
                        xp: addedToast.xp,
                        alreadyAdded: addedToast.alreadyAdded
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .id(addedToast.id)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.84), value: addedToast)
            .task(id: addedToast?.id) {
                guard addedToast != nil else { return }
                do {
                    try await Task.sleep(for: .seconds(2.4))
                    withAnimation(.easeInOut(duration: 0.25)) {
                        addedToast = nil
                    }
                } catch {}
            }
            .sensoryFeedback(.success, trigger: addFeedback)
            .navigationTitle("Quest Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always)
            )
        }
        .fullScreenCover(item: $openedQuest) { quest in
            QuestDetailScreen(quest: quest)
        }
    }

    // MARK: - Section View
    @ViewBuilder
    private func sectionView(for section: QuestSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Heading: size 22, weight medium, colour #111827, 20pt left padding
            Text(section.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color(hex: 0x111827))
                .padding(.leading, 20)

            // Horizontal scroll with snapping
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(section.quests) { quest in
                        situationCard(for: quest, in: section)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollClipDisabled()
        }
    }

    // MARK: - Situation Card (fixed 150 x 202)
    private func situationCard(for quest: LibraryQuest, in section: QuestSection) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                open(quest, in: section)
            } label: {
                cardContent(for: quest)
            }
            .buttonStyle(DebriefPressStyle())
            .accessibilityLabel("\(quest.title), \(quest.xp) XP")
            .accessibilityHint("Opens the quest briefing")

            addButton(for: quest, in: section)
                .padding(.top, 120)
                .padding(.trailing, 11)
        }
    }

    private func cardContent(for quest: LibraryQuest) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Picture area: 128 x 98, corner radius 15 (continuous), filled with pastel tint
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(quest.tint)
                .frame(width: 128, height: 98)
                .overlay {
                    Image(quest.imageName)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            // 2. Title: size 16, weight medium, colour #111827, max 2 lines, left aligned, min height 39, 5pt above it
            Text(quest.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: 0x111827))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 39, alignment: .topLeading)
                .padding(.trailing, 28)
                .padding(.top, 5)

            // 3. Flexible spacer
            Spacer(minLength: 0)

            // 4. 1pt divider, colour #F3F4F6, full inner width
            Rectangle()
                .fill(Color(hex: 0xF3F4F6))
                .frame(height: 1)

            // 5. XP label: size 12, regular, colour #9CA3AF, left aligned, min height 21.5
            Text("\(quest.xp) XP")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(hex: 0x9CA3AF))
                .frame(maxWidth: .infinity, minHeight: 21.5, alignment: .leading)
        }
        .padding(11)
        .frame(width: 150, height: 202)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.03), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Add button
    private func addButton(for quest: LibraryQuest, in section: QuestSection) -> some View {
        let added = isAdded(quest, in: section)

        return Button {
            add(quest, in: section)
        } label: {
            ZStack {
                if added {
                    Circle()
                        .fill(QuestStyle.chipSelectedFill)

                    Circle()
                        .strokeBorder(QuestStyle.chipSelectedBorder.opacity(0.6), lineWidth: 1)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(QuestStyle.green)
                        .symbolEffect(.bounce, value: added)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [QuestStyle.green, QuestStyle.deepGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)

                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 26, height: 26)
            .shadow(
                color: added ? Color.black.opacity(0.05) : QuestStyle.deepGreen.opacity(0.28),
                radius: 5,
                x: 0,
                y: 2
            )
            .contentShape(Circle())
        }
        .buttonStyle(DebriefPressStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: added)
        .accessibilityLabel(added ? "\(quest.title) is already in Quests" : "Add \(quest.title) to Quests")
    }

    // MARK: - Connections
    /// Opens the quest briefing for a library card. The card is added to the
    /// user's quests the first time it's opened, and reopened after that.
    private func open(_ item: LibraryQuest, in section: QuestSection) {
        openedQuest = savedQuest(for: item, in: section)
    }

    /// Adds the card straight to the Quests tab and confirms it in place.
    private func add(_ item: LibraryQuest, in section: QuestSection) {
        let alreadyAdded = isAdded(item, in: section)
        _ = savedQuest(for: item, in: section)

        addFeedback += 1
        addedToast = AddedQuestToast(
            title: item.title,
            xp: item.xp,
            alreadyAdded: alreadyAdded
        )
    }

    private func isAdded(_ item: LibraryQuest, in section: QuestSection) -> Bool {
        savedQuests.contains {
            !$0.isCompleted && $0.title == item.title && $0.category == section.category
        }
    }

    private func savedQuest(for item: LibraryQuest, in section: QuestSection) -> Quest {
        let ownerID = CurrentUser.localID
        let title = item.title
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { quest in
                quest.ownerID == ownerID && quest.title == title
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let matches = (try? modelContext.fetch(descriptor)) ?? []
        if let existing = matches.first(where: { !$0.isCompleted && $0.category == section.category }) {
            return existing
        }

        let quest = Quest(
            ownerID: ownerID,
            title: item.title,
            notes: "",
            intensity: item.intensity,
            category: section.category,
            date: QuestFormat.defaultSchedule(),
            xp: item.xp
        )
        modelContext.insert(quest)
        try? modelContext.save()
        return quest
    }
}

// MARK: - Confirmation
private struct AddedQuestToast: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let xp: Int
    let alreadyAdded: Bool
}

private struct QuestAddedBanner: View {
    let title: String
    let xp: Int
    let alreadyAdded: Bool

    @State private var pop = false
    @State private var progress: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))

                    Circle()
                        .fill(QuestStyle.chipSelectedFill)
                        .padding(4)

                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(QuestStyle.deepGreen)
                        .symbolEffect(.bounce, value: pop)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(alreadyAdded ? "Already in Quests" : "Added to Quests")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        if !alreadyAdded {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(QuestStyle.chipSelectedFill)
                        }
                    }

                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9, weight: .bold))

                    Text("\(xp) XP")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(QuestStyle.chipSelectedFill)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(Capsule().fill(Color.white.opacity(0.14)))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))

                    Capsule()
                        .fill(QuestStyle.chipSelectedFill)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 11)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [QuestStyle.deepGreen, QuestStyle.green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: QuestStyle.deepGreen.opacity(0.3), radius: 18, x: 0, y: 8)
        .onAppear {
            pop = true
            withAnimation(.linear(duration: 2.4)) {
                progress = 0
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quest Library Data
// Keep this data in one clearly commented place so it is easy to edit later.
extension QuestLibraryView {
    static let sections: [QuestSection] = [
        // Work
        QuestSection(
            title: "Work",
            category: .work,
            quests: [
                LibraryQuest(title: "Speak up in a meeting", imageName: "quest_speak_up", xp: 100, tint: Color(hex: 0xFAEDD9)),
                LibraryQuest(title: "Decline extra work", imageName: "quest_decline_extra_work", xp: 150, tint: Color(hex: 0xF5E6D3)),
                LibraryQuest(title: "Correct your boss", imageName: "quest_correct_your_boss", xp: 200, tint: Color(hex: 0xF0DFC8)),
                LibraryQuest(title: "Ask for a Raise", imageName: "quest_ask_for_a_raise", xp: 250, tint: Color(hex: 0xEBD8BC)),
                LibraryQuest(title: "Ask a Mentor", imageName: "quest_ask_a_mentor", xp: 300, tint: Color(hex: 0xE6D1B1))
            ]
        ),

        // Dating
        QuestSection(
            title: "Dating",
            category: .dating,
            quests: [
                LibraryQuest(title: "Send the first message", imageName: "quest_send_first_message", xp: 100, tint: Color(hex: 0xFBE7E4)),
                LibraryQuest(title: "Name what you felt", imageName: "quest_name_what_you_felt", xp: 150, tint: Color(hex: 0xF8DAD4)),
                LibraryQuest(title: "Ask where things stand", imageName: "quest_ask_where_things_stand", xp: 200, tint: Color(hex: 0xF5CBBE)),
                LibraryQuest(title: "First Date", imageName: "quest_first_date", xp: 250, tint: Color(hex: 0xF1BDAE)),
                LibraryQuest(title: "The Ex", imageName: "quest_the_ex", xp: 300, tint: Color(hex: 0xEDAF9F))
            ]
        ),

        // Friends
        QuestSection(
            title: "Friends",
            category: .friends,
            quests: [
                LibraryQuest(title: "Say you’re hurt", imageName: "quest_say_youre_hurt", xp: 100, tint: Color(hex: 0xE7EFE9)),
                LibraryQuest(title: "Bring up the distance", imageName: "quest_bring_up_distance", xp: 150, tint: Color(hex: 0xDBE8DE)),
                LibraryQuest(title: "Turn down the plan", imageName: "quest_turn_down_plan", xp: 200, tint: Color(hex: 0xCEDECF)),
                LibraryQuest(title: "Make a Real Friend", imageName: "quest_make_a_real_friend", xp: 250, tint: Color(hex: 0xC1D4C3)),
                LibraryQuest(title: "Check On a Friend", imageName: "quest_check_on_a_friend", xp: 300, tint: Color(hex: 0xB4CAB7))
            ]
        ),

        // Family
        QuestSection(
            title: "Family",
            category: .family,
            quests: [
                LibraryQuest(title: "The Holiday Table", imageName: "quest_holiday_table", xp: 100, tint: Color(hex: 0xE9EBF7)),
                LibraryQuest(title: "The Sibling Talk", imageName: "quest_sibling_talk", xp: 150, tint: Color(hex: 0xDDE1F2)),
                LibraryQuest(title: "Hold the Line with Mom", imageName: "quest_hold_the_line_with_mom", xp: 200, tint: Color(hex: 0xCED4EC)),
                LibraryQuest(title: "Open Up to Dad", imageName: "quest_open_up_to_dad", xp: 250, tint: Color(hex: 0xC0C8E6))
            ]
        )
    ]
}

// MARK: - Preview
#Preview {
    QuestLibraryView()
        .modelContainer(MokoDatabase.preview)
}

