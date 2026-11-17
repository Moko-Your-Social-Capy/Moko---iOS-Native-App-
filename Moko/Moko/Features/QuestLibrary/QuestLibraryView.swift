//
//  QuestLibraryView.swift
//  Moko
//
//  The Explore tab: ready-made quests from Supabase, grouped by category in
//  horizontal rows, with a search bar that filters by title. Choosing one type
//  in the filter bar swaps the rows for a vertical list of larger cards.
//
//  Flow: `QuestLibraryStore` downloads the sections → tapping a card finds (or
//  creates) a hidden SwiftData `Quest` for it → `QuestDetailScreen` opens.
//  Debug tip: if nothing loads, check `store.errorMessage` and the "Network" log.
//

import SwiftUI
import SwiftData
import OSLog

struct QuestLibraryView: View {
    // MARK: - Properties

    // SwiftData's "save box". Used to find or create the quest behind a card.
    @Environment(\.modelContext) private var modelContext
    // The phone setting "Reduce Motion". Cards fade in without sliding when it is on.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Downloads the library from Supabase. @State keeps it alive between redraws.
    @State private var store = QuestLibraryStore()
    // What the user typed in the search bar.
    @State private var searchText: String = ""
    // Which type chip is picked. nil means "All" and keeps the sideways rows.
    @State private var selectedType: String?
    // Setting this pushes the quest briefing.
    @State private var openedQuest: Quest?
    // Card size that grows with the user's text size setting.
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 164
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 224
    /// How far the library has scrolled (0 at rest), used to swap the large header for a compact title.
    @State private var scrollOffset: CGFloat = 0
    /// Artwork URL of the library quest currently being opened. Passed to the
    /// detail screen so it shows the card's image instead of the category
    /// placeholder. Only set for quest library quests, never custom quests.
    @State private var libraryArtworkURL: URL?

    // MARK: - Filtered Data

    /// Sections after the search and the type filter.
    /// Curly apostrophes (’) are treated like straight ones (') so "don't" finds "don’t".
    private var filteredSections: [QuestSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchedSections: [QuestSection]

        if query.isEmpty {
            searchedSections = store.sections
        } else {
            let normalizedQuery = query.replacingOccurrences(of: "’", with: "'")
            searchedSections = store.sections.compactMap { section in
                let matchingQuests = section.quests.filter { quest in
                    let normalizedTitle = quest.title.replacingOccurrences(of: "’", with: "'")
                    return normalizedTitle.localizedCaseInsensitiveContains(normalizedQuery)
                }
                guard !matchingQuests.isEmpty else { return nil }
                return QuestSection(title: section.title, category: section.category, quests: matchingQuests)
            }
        }

        // "All" (nil) keeps every section. One type keeps only its own section.
        guard let selectedType else { return searchedSections }
        return searchedSections.filter { $0.title == selectedType }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MokoBackdrop()

                if store.isLoading || !store.hasAttemptedLoad {
                    VStack(spacing: 14) {
                        MokoLoadingView()
                            .frame(width: 176, height: 176)

                        Text("Loading quests…")
                            .mokoText(MokoScreenTheme.Typeface.body)
                            .foregroundStyle(QuestStyle.title)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 22) {
                            headerSection

                            // Only show the chips once there is something to filter.
                            if !store.sections.isEmpty {
                                QuestLibraryFilterBar(
                                    sections: store.sections,
                                    selectedTitle: $selectedType
                                )
                            }

                            libraryContent
                        }
                        .padding(.bottom, 16)
                    }
                    // Reports how far the list has scrolled, so the small title can fade in.
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y + geometry.contentInsets.top
                    } action: { _, offset in
                        scrollOffset = offset
                    }
                    .overlay(alignment: .top) {
                        compactTitleBar
                    }
                }
            }
            // `.task` runs when the screen appears. Downloads the library the first time only.
            .task {
                await store.loadIfNeeded()
            }
            // If a refresh removes the picked type, quietly return to "All".
            .onChange(of: store.sections.map(\.title)) { _, types in
                if let selectedType, !types.contains(selectedType) {
                    self.selectedType = nil
                }
            }
            // Matches the Overview, Quests and Relax tab headers.
            .navigationTitle("Quest Library")
            .tint(MokoScreenTheme.Colors.dataVioletDeep)
            .toolbar(.hidden, for: .navigationBar)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always)
            )
            // Pushes the briefing whenever `openedQuest` is set.
            .navigationDestination(item: $openedQuest) { quest in
                QuestDetailScreen(quest: quest, libraryArtworkURL: libraryArtworkURL)
            }
        }
    }

    // MARK: - Header

    /// Small title pinned under the status bar. It fades in as the large in-content title scrolls
    /// away, so the screen stays labelled without a navigation bar.
    private var compactTitleBar: some View {
        Text("Quest Library")
            .font(.headline)
            .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            // The backing runs up through the status bar so scrolled cards cannot show there.
            .background {
                MokoScreenTheme.Colors.canvasTop
                    .ignoresSafeArea(edges: .top)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(QuestStyle.title.opacity(0.12))
                    .frame(height: 0.5)
            }
            .opacity(compactTitleOpacity)
            .allowsHitTesting(false)
            .accessibilityHidden(compactTitleOpacity < 0.5)
    }

    /// Cross-fades between 0 and 1 while the large title slides out of view (~55 pt tall).
    private var compactTitleOpacity: Double {
        let fadeStart: CGFloat = 24
        let fadeEnd: CGFloat = 56
        return Double(min(max((scrollOffset - fadeStart) / (fadeEnd - fadeStart), 0), 1))
    }

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Quest Library")
                .mokoText(MokoScreenTheme.Typeface.title1)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            Spacer(minLength: 12)

            Button {
                Task { await store.load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(QuestStyle.accent)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading)
            .accessibilityLabel("Refresh quests")
        }
        .padding(.horizontal, MokoScreenTheme.Space.page)
        .padding(.top, 14)
    }

    // MARK: - Content

    /// Error, empty, "no search results" or the category rows.
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
                .tint(QuestStyle.accent)
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
            emptyFilteredContent
        } else {
            // Some quests are already showing, but the latest refresh failed.
            if let error = store.errorMessage {
                refreshFailedBanner(error)
            }

            // "All" keeps the sideways category rows. One type becomes a vertical list.
            if selectedType == nil {
                ForEach(Array(filteredSections.enumerated()), id: \.element.id) { sectionIndex, section in
                    sectionView(for: section, sectionIndex: sectionIndex)
                }
            } else {
                ForEach(Array(filteredSections.enumerated()), id: \.element.id) { sectionIndex, section in
                    typeListSectionView(for: section, sectionIndex: sectionIndex)
                }
            }
        }
    }

    /// Shown when the search or the picked type leaves nothing to display.
    private var emptyFilteredContent: some View {
        Group {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView {
                    Label("No \(selectedType ?? "") quests", systemImage: "sparkles")
                } description: {
                    Text("New quests will appear here as soon as they're added.")
                }
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func refreshFailedBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))

            Text(message)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            Button("Retry") {
                Task { await store.load() }
            }
            .mokoText(MokoScreenTheme.Typeface.caption)
            .foregroundStyle(QuestStyle.accent)
        }
        .foregroundStyle(QuestStyle.title)
        .padding(14)
        .mokoCard(fill: MokoScreenTheme.Colors.surfaceLavender, radius: MokoScreenTheme.Radius.inner, lift: false)
        .padding(.horizontal, MokoScreenTheme.Space.page)
    }

    // MARK: - Section View

    /// One category: a heading and a sideways-scrolling row of cards.
    @ViewBuilder
    private func sectionView(for section: QuestSection, sectionIndex: Int) -> some View {
        // How many cards come before this row. Used to stagger the first cards' entrance.
        let firstCardIndex = filteredSections.prefix(sectionIndex).reduce(0) { $0 + $1.quests.count }

        VStack(alignment: .leading, spacing: 14) {
            Text(section.title)
                .mokoText(MokoScreenTheme.Typeface.title2)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                .padding(.leading, MokoScreenTheme.Space.page)

            // Horizontal scroll that snaps so a card always lines up with the left edge.
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(section.quests.enumerated()), id: \.element.id) { questIndex, quest in
                        situationCard(for: quest, in: section)
                            .questCardEntrance(order: firstCardIndex + questIndex, reduceMotion: reduceMotion)
                    }
                }
                .scrollTargetLayout()   // tells `.viewAligned` which views to snap to
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, MokoScreenTheme.Space.page, for: .scrollContent)
            .scrollClipDisabled()
        }
    }

    // MARK: - Type List Section View

    /// One type shown as a vertical list: a small group heading and full-width cards.
    /// This is the layout used after a type chip is picked.
    private func typeListSectionView(for section: QuestSection, sectionIndex: Int) -> some View {
        // How many cards come before this section. Keeps the entrance stagger in order.
        let firstCardIndex = filteredSections.prefix(sectionIndex).reduce(0) { $0 + $1.quests.count }
        // "1 quest" reads better than "1 quests".
        let questCountText = section.quests.count == 1 ? "1 quest" : "\(section.quests.count) quests"

        return VStack(alignment: .leading, spacing: 14) {
            // A quiet heading groups the cards, like the day headings in the Quests tab.
            HStack(spacing: 8) {
                Image(systemName: section.category.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QuestStyle.categoryColor(for: section.category))

                Text(section.title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(QuestStyle.subtext)

                Spacer(minLength: 8)

                Text(questCountText)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(QuestStyle.subtext)
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)

            // The big cards stack vertically and use the full screen width.
            LazyVStack(spacing: 16) {
                ForEach(Array(section.quests.enumerated()), id: \.element.id) { questIndex, quest in
                    QuestLibraryLargeCard(quest: quest, section: section) {
                        open(quest, in: section)
                    }
                    .questCardEntrance(order: firstCardIndex + questIndex, reduceMotion: reduceMotion)
                }
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
        }
    }

    // MARK: - Situation Card

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

    /// Picture, title, XP — top to bottom.
    private func cardContent(for quest: LibraryQuest, in section: QuestSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Picture area, filled with the quest's pastel tint behind the artwork.
            RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.inner, style: .continuous)
                .fill(quest.tint)
                .frame(width: cardWidth - 24, height: 106)
                .overlay {
                    QuestLibraryArtwork(quest: quest, category: section.category)
                }
                .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.inner, style: .continuous))

            // 2. Title: up to 2 lines. Brown color matches brand quest titles.
            Text(quest.title)
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(QuestStyle.titleBrown)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 39, alignment: .topLeading)
                .padding(.top, 5)

            // 3. Pushes the XP label to the bottom of the card.
            Spacer(minLength: 0)

            // 4. XP label with distinct, high-visibility color per XP tier.
            Text("\(quest.xp) XP")
                .mokoText(MokoScreenTheme.Typeface.slider)
                .foregroundStyle(QuestStyle.xpColor(for: quest.xp))
                .frame(maxWidth: .infinity, minHeight: 21.5, alignment: .leading)
        }
        .padding(12)
        .frame(width: cardWidth, height: cardHeight)
        .mokoCard()
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
        // #Predicate can't read `item.title` directly, so copy values into locals first.
        let ownerID = CurrentUser.localID
        let title = item.title
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { quest in
                quest.ownerID == ownerID && quest.title == title
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let matches: [Quest]
        do {
            matches = try modelContext.fetch(descriptor)
        } catch {
            Logger.data.error("Library quest lookup failed: \(error.localizedDescription, privacy: .public)")
            matches = []
        }

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
        modelContext.saveOrLog("library quest")
        return quest
    }
}

/// Fades (and slides up) the first 6 cards when the library appears, one after another.
/// Later cards appear straight away so long lists don't feel slow.
private struct QuestCardEntranceModifier: ViewModifier {
    let order: Int
    let reduceMotion: Bool
    // false until the card has appeared once.
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

