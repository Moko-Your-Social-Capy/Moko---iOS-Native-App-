//
//  QuestLibraryLargeCard.swift
//  Moko
//
//  The full-width card used when the Quest Library is filtered to one type.
//

import SwiftUI

/// A bigger library card. It uses the full screen width for a taller picture,
/// so one type reads as a comfortable vertical list.
struct QuestLibraryLargeCard: View {
    let quest: LibraryQuest
    let section: QuestSection
    /// Called when the card is tapped. The parent opens the quest briefing.
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            content
        }
        .buttonStyle(DebriefPressStyle())
        .accessibilityLabel("\(quest.title), \(quest.xp) XP")
        .accessibilityHint("Opens the quest briefing")
    }

    /// Picture, title, type label and XP, top to bottom.
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The picture grows to the full card width and is taller than the small card.
            RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.inner, style: .continuous)
                .fill(quest.tint)
                .frame(maxWidth: .infinity)
                .frame(height: 176)
                .overlay {
                    QuestLibraryArtwork(quest: quest, category: section.category)
                }
                .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.inner, style: .continuous))

            // Title: up to 2 lines. Brown matches the other quest titles in the app.
            Text(quest.title)
                .mokoText(MokoScreenTheme.Typeface.cardTitle)
                .foregroundStyle(QuestStyle.titleBrown)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 46, alignment: .topLeading)
                .padding(.top, 8)

            // The type pill repeats the filter choice, and XP fills the bottom row.
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: section.category.symbol)
                        .font(.system(size: 11, weight: .semibold))

                    Text(section.title)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                }
                .foregroundStyle(QuestStyle.categoryColor(for: section.category))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(QuestStyle.categoryTint(for: section.category)))

                Spacer(minLength: 8)

                Text("\(quest.xp) XP")
                    .mokoText(MokoScreenTheme.Typeface.slider)
                    .foregroundStyle(QuestStyle.xpColor(for: quest.xp))
            }
            .padding(.top, 10)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mokoCard()
    }
}
