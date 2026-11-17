//
//  MokoCostume.swift
//  Moko
//
//  Moko's outfits. A new costume unlocks as the user levels up.
//  - `MokoCostume`: the list of outfits and the unlock rules.
//  - `MokoCostumeAvatar`: the round picture (user photo or Moko in an outfit).
//  - `MokoWardrobeView`: the screen where the user picks an outfit.
//

import SwiftUI
import UIKit

/// One outfit. `level` is the level needed to unlock it, and it is also the outfit's id.
struct MokoCostume: Identifiable, Hashable {
    let level: Int
    let name: String
    let assetName: String
    var id: Int { level }

    static let all: [MokoCostume] = [
        .init(level: 1, name: "Everyday Starter", assetName: "MokoCostume01"),
        .init(level: 2, name: "Cozy Cardigan", assetName: "MokoCostume02"),
        .init(level: 3, name: "Canteen Casual", assetName: "MokoCostume03"),
        .init(level: 4, name: "Garden Helper", assetName: "MokoCostume04"),
        .init(level: 5, name: "Campus Classic", assetName: "MokoCostume05"),
        .init(level: 6, name: "Thoughtful Scholar", assetName: "MokoCostume06"),
        .init(level: 8, name: "Confident Blazer", assetName: "MokoCostume07"),
        .init(level: 10, name: "Weekend Explorer", assetName: "MokoCostume08"),
        .init(level: 12, name: "Modern Kurta", assetName: "MokoCostume09"),
        .init(level: 14, name: "Studio Artist", assetName: "MokoCostume10"),
        .init(level: 16, name: "Mountain Guide", assetName: "MokoCostume11"),
        .init(level: 18, name: "Celebration Suit", assetName: "MokoCostume12"),
        .init(level: 20, name: "Heritage Waistcoat", assetName: "MokoCostume13"),
        .init(level: 24, name: "Mentor Look", assetName: "MokoCostume14"),
        .init(level: 30, name: "Level Master", assetName: "MokoCostume15")
    ]

    /// How many outfits the user has at this level.
    static func unlockedCount(for level: Int) -> Int {
        all.filter { $0.level <= level }.count
    }

    /// The outfit to show: the one the user picked if it is unlocked,
    /// otherwise the newest unlocked one, otherwise the first outfit (for level 0).
    static func selected(unlockedAt level: Int, selection: Int) -> MokoCostume {
        all.first(where: { $0.level == selection && $0.level <= level })
            ?? all.last(where: { $0.level <= level })
            ?? all[0]
    }
}

/// A round avatar. Shows the user's photo if they set one, otherwise Moko in the chosen outfit.
struct MokoCostumeAvatar: View {
    let level: Int
    let photoData: Data?
    var size: CGFloat
    /// Pass `.clear` when the avatar sits on a themed surface of its own.
    var background: Color = MokoScreenTheme.Colors.surfaceLavender
    var ring: Color? = MokoScreenTheme.Colors.ctaAccent.opacity(0.18)
    // @AppStorage saves the picked outfit in UserDefaults, so it is remembered after the app closes.
    // Every view that uses the same key updates together.
    @AppStorage("moko.selectedCostumeLevel") private var selectedLevel = 1

    private var costume: MokoCostume { .selected(unlockedAt: level, selection: selectedLevel) }

    var body: some View {
        Group {
            // Turn the saved photo bytes back into an image. If that fails, show Moko instead.
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(costume.assetName)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.035)
            }
        }
        .frame(width: size, height: size)
        .background(background, in: Circle())
        .clipShape(Circle())
        .overlay {
            if let ring {
                Circle().stroke(ring, lineWidth: 1)
            }
        }
        .accessibilityLabel(photoData == nil ? "Moko wearing \(costume.name)" : "Profile photo")
    }
}

/// Profile → Wardrobe: every outfit, with locked ones greyed out.
struct MokoWardrobeView: View {
    let level: Int
    // Same key as `MokoCostumeAvatar`, so tapping an outfit here changes the avatar everywhere.
    @AppStorage("moko.selectedCostumeLevel") private var selectedLevel = 1

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                VStack(spacing: 8) {
                    MokoCostumeAvatar(level: level, photoData: nil, size: 144)
                    Text(MokoCostume.selected(unlockedAt: level, selection: selectedLevel).name)
                        .font(.headline)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    Text("Level \(level) · \(MokoCostume.unlockedCount(for: level)) of \(MokoCostume.all.count) unlocked")
                        .font(.subheadline)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                ForEach(Array(MokoCostume.all.enumerated()), id: \.element.id) { index, costume in
                    MokoWardrobeCostumeCard(
                        costume: costume,
                        index: index,
                        isUnlocked: level >= costume.level,
                        isSelected: selectedLevel == costume.level
                    ) {
                        guard level >= costume.level else { return }
                        selectedLevel = costume.level
                    }
                }

                Text("Keep practicing to unlock each new look. Costumes are never for sale.")
                    .font(.footnote)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.vertical, 16)
        }
        .background(MokoBackdrop())
        .navigationTitle("Moko’s wardrobe")
        .navigationBarTitleDisplayMode(.large)
        .tint(MokoScreenTheme.Colors.ctaAccent)
    }
}

/// Costume card with alternating left/right entrance animation as it scrolls into view.
private struct MokoWardrobeCostumeCard: View {
    let costume: MokoCostume
    let index: Int
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Tracks whether this row has played its one-time entrance.
    @State private var hasAppeared = false

    // Even rows enter from the left, odd rows from the right.
    private var fromLeft: Bool { index.isMultiple(of: 2) }

    var body: some View {
        let hidden = !hasAppeared && !reduceMotion
        let startOffset: CGFloat = hidden ? (fromLeft ? -48 : 48) : 0

        // Button lets the user pick an unlocked costume.
        Button {
            onSelect()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        // Slide and fade in once when the card first scrolls into view.
        .offset(x: startOffset)
        .opacity(hidden ? 0 : 1)
        .onAppear {
            // Trigger entrance once; skip movement for Reduce Motion.
            guard !hasAppeared else { return }
            if reduceMotion {
                hasAppeared = true
            } else {
                // Smooth spring gives a natural alternating entrance.
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    hasAppeared = true
                }
            }
        }
    }

    // Row content for one costume card.
    private var cardContent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MokoScreenTheme.Colors.surfaceLavender.opacity(isUnlocked ? 0.7 : 0.35))
                Image(costume.assetName)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            }
            .frame(width: 72, height: 72)
            .opacity(isUnlocked ? 1 : 0.55)

            VStack(alignment: .leading, spacing: 4) {
                Text(costume.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                Text(isUnlocked ? "Unlocked · Level \(costume.level)" : "Unlocks at Level \(costume.level)")
                    .font(.subheadline)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
            }

            Spacer(minLength: 8)

            Group {
                if isSelected && isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MokoScreenTheme.Colors.ctaAccent)
                        .accessibilityLabel("Selected")
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        .accessibilityLabel("Locked")
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(14)
        .mokoCard(fill: MokoScreenTheme.Colors.surfaceWhite)
    }
}
