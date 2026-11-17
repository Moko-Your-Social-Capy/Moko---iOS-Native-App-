//
//  QuestLibraryArtwork.swift
//  Moko
//
//  The picture area shared by the small and large Quest Library cards.
//

import SwiftUI
import UIKit

/// Shows the quest's artwork from Supabase Storage, a bundled image, or the
/// category symbol while the picture is missing or loading.
struct QuestLibraryArtwork: View {
    let quest: LibraryQuest
    let category: QuestCategory

    var body: some View {
        if let url = quest.artworkURL {
            // AsyncImage downloads the picture. `phase` tells us loading / done / failed.
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ZStack {
                        Color.white.opacity(0.25)
                        MokoInlineLoader(size: 36)
                    }
                case .failure:
                    categorySymbol
                @unknown default:
                    categorySymbol
                }
            }
        } else if let imageName = quest.imageName, UIImage(named: imageName) != nil {
            // Optional fallback for artwork bundled in Assets.xcassets.
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            categorySymbol
        }
    }

    /// A soft category icon keeps the card readable when no picture exists.
    private var categorySymbol: some View {
        Image(systemName: category.symbol)
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(QuestStyle.accent.opacity(0.45))
    }
}
