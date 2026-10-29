//
//  QuestLibraryView.swift
//  Moko
//
//  Quest Library screen showing categorized situation cards with horizontal snapping
//  and case-insensitive search filtering.
//

import SwiftUI

struct QuestLibraryView: View {
    // MARK: - Models
    struct Quest: Identifiable, Hashable {
        var id: String { title }
        let title: String
        let imageName: String
        let xp: Int
        let tint: Color
    }

    struct QuestSection: Identifiable, Hashable {
        var id: String { title }
        let title: String
        let quests: [Quest]
    }

    // MARK: - Properties
    var onSelect: (Quest) -> Void = { _ in }
    @State private var searchText: String = ""

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
            return QuestSection(title: section.title, quests: matchingQuests)
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
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
            }
            .navigationTitle("Quest Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always)
            )
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
                        situationCard(for: quest)
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
    @ViewBuilder
    private func situationCard(for quest: Quest) -> some View {
        Button {
            onSelect(quest)
        } label: {
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(quest.title), \(quest.xp) XP")
    }
}

// MARK: - Quest Library Data
// Keep this data in one clearly commented place so it is easy to edit later.
extension QuestLibraryView {
    static let sections: [QuestSection] = [
        // Work
        QuestSection(
            title: "Work",
            quests: [
                Quest(title: "Speak up in a meeting", imageName: "quest_speak_up", xp: 100, tint: Color(hex: 0xFAEDD9)),
                Quest(title: "Decline extra work", imageName: "quest_decline_extra_work", xp: 150, tint: Color(hex: 0xF5E6D3)),
                Quest(title: "Correct your boss", imageName: "quest_correct_your_boss", xp: 200, tint: Color(hex: 0xF0DFC8)),
                Quest(title: "Ask for a Raise", imageName: "quest_ask_for_a_raise", xp: 250, tint: Color(hex: 0xEBD8BC)),
                Quest(title: "Ask a Mentor", imageName: "quest_ask_a_mentor", xp: 300, tint: Color(hex: 0xE6D1B1))
            ]
        ),

        // Dating
        QuestSection(
            title: "Dating",
            quests: [
                Quest(title: "Send the first message", imageName: "quest_send_first_message", xp: 100, tint: Color(hex: 0xFBE7E4)),
                Quest(title: "Name what you felt", imageName: "quest_name_what_you_felt", xp: 150, tint: Color(hex: 0xF8DAD4)),
                Quest(title: "Ask where things stand", imageName: "quest_ask_where_things_stand", xp: 200, tint: Color(hex: 0xF5CBBE)),
                Quest(title: "First Date", imageName: "quest_first_date", xp: 250, tint: Color(hex: 0xF1BDAE)),
                Quest(title: "The Ex", imageName: "quest_the_ex", xp: 300, tint: Color(hex: 0xEDAF9F))
            ]
        ),

        // Friends
        QuestSection(
            title: "Friends",
            quests: [
                Quest(title: "Say you’re hurt", imageName: "quest_say_youre_hurt", xp: 100, tint: Color(hex: 0xE7EFE9)),
                Quest(title: "Bring up the distance", imageName: "quest_bring_up_distance", xp: 150, tint: Color(hex: 0xDBE8DE)),
                Quest(title: "Turn down the plan", imageName: "quest_turn_down_plan", xp: 200, tint: Color(hex: 0xCEDECF)),
                Quest(title: "Make a Real Friend", imageName: "quest_make_a_real_friend", xp: 250, tint: Color(hex: 0xC1D4C3)),
                Quest(title: "Check On a Friend", imageName: "quest_check_on_a_friend", xp: 300, tint: Color(hex: 0xB4CAB7))
            ]
        ),

        // Family
        QuestSection(
            title: "Family",
            quests: [
                Quest(title: "The Holiday Table", imageName: "quest_holiday_table", xp: 100, tint: Color(hex: 0xE9EBF7)),
                Quest(title: "The Sibling Talk", imageName: "quest_sibling_talk", xp: 150, tint: Color(hex: 0xDDE1F2)),
                Quest(title: "Hold the Line with Mom", imageName: "quest_hold_the_line_with_mom", xp: 200, tint: Color(hex: 0xCED4EC)),
                Quest(title: "Open Up to Dad", imageName: "quest_open_up_to_dad", xp: 250, tint: Color(hex: 0xC0C8E6))
            ]
        )
    ]
}

// MARK: - Preview
#Preview {
    QuestLibraryView()
}

