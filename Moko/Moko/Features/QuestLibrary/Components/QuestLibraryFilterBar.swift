//
//  QuestLibraryFilterBar.swift
//  Moko
//
//  The "All" and type chips above the Quest Library results.
//

import SwiftUI

/// One chip per library type, plus "All". Picking a type tells
/// `QuestLibraryView` to replace the sideways rows with a vertical list.
struct QuestLibraryFilterBar: View {
    /// The loaded sections. One chip is made for each type Supabase returns.
    let sections: [QuestSection]
    /// The picked type. nil means "All".
    @Binding var selectedTitle: String?

    var body: some View {
        // The chips scroll sideways so every type stays reachable on small screens.
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(
                    title: "All",
                    symbol: nil,
                    category: nil,
                    isSelected: selectedTitle == nil
                ) {
                    selectedTitle = nil
                }

                // Types come from Supabase, so use the loaded sections instead of
                // a fixed list. A new type appears here without a code change.
                ForEach(sections) { section in
                    chip(
                        title: section.title,
                        symbol: section.category.symbol,
                        category: section.category,
                        isSelected: selectedTitle == section.title
                    ) {
                        selectedTitle = section.title
                    }
                }
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter quests by type")
    }

    /// One pill. The type keeps its colour, and a selected pill gets a pale wash.
    private func chip(
        title: String,
        symbol: String?,
        category: QuestCategory?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        // Each type keeps its colour all the time, so the chips stay easy to recognise.
        let categoryColor = category.map(QuestStyle.categoryColor(for:))
        // Words and icon share one colour, so each chip reads as a single calm pill.
        let ink = categoryColor ?? (isSelected ? QuestStyle.title : QuestStyle.subtext)
        // A selected chip gets a pale wash of its colour, never a heavy block.
        let fill = isSelected
            ? (category.map(QuestStyle.categoryTint(for:)) ?? QuestStyle.chipSelectedFill)
            : Color.white
        // The border only appears when selected, in the same colour as the words.
        let border = isSelected
            ? (categoryColor?.opacity(0.45) ?? QuestStyle.chipSelectedBorder)
            : Color.clear

        return Button {
            // A short fade makes the change from rows to a list feel calm.
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        } label: {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .semibold))
                }

                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.caption)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(border, lineWidth: 1))
            // A soft glow under the selected chip ties its colour to the screen.
            .shadow(color: isSelected ? (categoryColor ?? Color.clear).opacity(0.22) : Color.clear,
                    radius: 6, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
