//
//  QuestLibraryView.swift
//  Moko
//
//  Quest Library screen showing categorized situation cards with horizontal snapping
//  and case-insensitive search filtering.
//

import SwiftUI
import SwiftData
import UIKit

struct QuestLibraryView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store = QuestLibraryStore()
    @State private var searchText: String = ""
    @State private var openedQuest: Quest?
    /// Artwork URL of the library quest currently being opened. Passed to the
    /// detail screen so it shows the card's image instead of the category
    /// placeholder. Only set for quest library quests, never custom quests.
    @State private var libraryArtworkURL: URL?

    // MARK: - Filtered Data
    private var filteredSections: [QuestSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return store.sections
        }
        let normalizedQuery = query.replacingOccurrences(of: "’", with: "'")
        return store.sections.compactMap { section in
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
                AppBackground()

                if store.isLoading || !store.hasAttemptedLoad {
                    VStack(spacing: 14) {
                        MokoFlossLoadingView(size: 176)
                            .frame(width: 176, height: 176)

                        Text("Loading quests…")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(QuestStyle.title)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 30) {
                            headerSection

                            libraryContent
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .task {
                await store.loadIfNeeded()
            }
            // Matches the Overview, Quests and Relax tab headers.
            .navigationTitle("Quest Library")
            .toolbar(.hidden, for: .navigationBar)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always)
            )
            .navigationDestination(item: $openedQuest) { quest in
                QuestDetailScreen(quest: quest, libraryArtworkURL: libraryArtworkURL)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Quest Library")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(MokoTheme.titleBrown)

            Spacer(minLength: 12)

            Button {
                Task { await store.load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(QuestStyle.green)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading)
            .accessibilityLabel("Refresh quests")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Content
    @ViewBuilder
    private var libraryContent: some View {
        if let error = store.errorMessage, store.sections.isEmpty {
            ContentUnavailableView {
                Label("Couldn't load quests", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") {
                    Task { await store.load() }
                }
                .buttonStyle(.borderedProminent)
                .tint(QuestStyle.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else if store.sections.isEmpty {
            ContentUnavailableView {
                Label("No quests yet", systemImage: "sparkles")
            } description: {
                Text("New quests will appear here as soon as they're added.")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else if filteredSections.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            if let error = store.errorMessage {
                refreshFailedBanner(error)
            }

            ForEach(Array(filteredSections.enumerated()), id: \.element.id) { sectionIndex, section in
                sectionView(for: section, sectionIndex: sectionIndex)
            }
        }
    }

    private func refreshFailedBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            Button("Retry") {
                Task { await store.load() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(QuestStyle.green)
        }
        .foregroundStyle(QuestStyle.title)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Section View
    @ViewBuilder
    private func sectionView(for section: QuestSection, sectionIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Heading: size 22, weight medium, colour #111827, 20pt left padding
            Text(section.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(MokoTheme.titleBrown)
                .padding(.leading, 20)

            // Horizontal scroll with snapping
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(section.quests.enumerated()), id: \.element.id) { questIndex, quest in
                        let firstCardIndex = filteredSections.prefix(sectionIndex).reduce(0) { $0 + $1.quests.count }
                        situationCard(for: quest, in: section)
                            .questCardEntrance(order: firstCardIndex + questIndex, reduceMotion: reduceMotion)
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
        Button {
            open(quest, in: section)
        } label: {
            cardContent(for: quest, in: section)
        }
        .buttonStyle(DebriefPressStyle())
        .accessibilityLabel("\(quest.title), \(quest.xp) XP")
        .accessibilityHint("Opens the quest briefing")
    }

    private func cardContent(for quest: LibraryQuest, in section: QuestSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Picture area: 128 x 98, corner radius 15 (continuous), filled with pastel tint
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(quest.tint)
                .frame(width: 128, height: 98)
                .overlay {
                    artwork(for: quest, in: section)
                }
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            // 2. Title: size 16, weight medium, colour #111827, max 2 lines, left aligned, min height 39, 5pt above it
            Text(quest.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MokoTheme.titleBrown)
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
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// Card artwork from Supabase Storage. Until a file is uploaded, or while it
    /// is loading, the category symbol keeps the card legible.
    @ViewBuilder
    private func artwork(for quest: LibraryQuest, in section: QuestSection) -> some View {
        if let url = quest.artworkURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ZStack {
                        Color.white.opacity(0.25)
                        MokoFlossLoadingView(size: 44)
                            .frame(width: 44, height: 44)
                    }
                case .failure:
                    categorySymbol(for: section.category)
                @unknown default:
                    categorySymbol(for: section.category)
                }
            }
        } else if let imageName = quest.imageName, UIImage(named: imageName) != nil {
            // Optional fallback for artwork bundled in Assets.xcassets.
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            categorySymbol(for: section.category)
        }
    }

    private func categorySymbol(for category: QuestCategory) -> some View {
        Image(systemName: category.symbol)
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(QuestStyle.green.opacity(0.45))
    }

    // MARK: - Connections
    /// Opens the quest briefing for a library card. Library cards live outside
    /// the Quests tab, so the saved record is only used to run the debrief.
    private func open(_ item: LibraryQuest, in section: QuestSection) {
        libraryArtworkURL = item.artworkURL
        openedQuest = libraryQuest(for: item, in: section)
    }

    /// Reuses an unfinished library quest or creates a new hidden one. Library
    /// quests carry a specific XP value, which keeps them out of the Quests tab
    /// while still letting their debrief scores reach Insights.
    private func libraryQuest(for item: LibraryQuest, in section: QuestSection) -> Quest {
        let ownerID = CurrentUser.localID
        let title = item.title
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { quest in
                quest.ownerID == ownerID && quest.title == title
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let matches = (try? modelContext.fetch(descriptor)) ?? []
        if let existing = matches.first(where: {
            $0.isFromLibrary && !$0.debriefRecorded && $0.category == section.category
        }) {
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

private struct QuestCardEntranceModifier: ViewModifier {
    let order: Int
    let reduceMotion: Bool
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(order < 6 && !isVisible ? 0 : 1)
            .offset(y: order < 6 && !reduceMotion && !isVisible ? 12 : 0)
            .onAppear {
                guard order < 6, !isVisible else { return }
                let animation = reduceMotion
                    ? Animation.easeInOut(duration: 0.2)
                    : Animation.spring(response: 0.42, dampingFraction: 0.86).delay(Double(order) * 0.04)
                withAnimation(animation) { isVisible = true }
            }
    }
}

private extension View {
    func questCardEntrance(order: Int, reduceMotion: Bool) -> some View {
        modifier(QuestCardEntranceModifier(order: order, reduceMotion: reduceMotion))
    }
}

// MARK: - Preview
#Preview {
    QuestLibraryView()
        .modelContainer(MokoDatabase.preview)
}

