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
        List {
            Section {
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
                .listRowBackground(Color.clear)
                .padding(.vertical, 12)
            }

            Section {
                ForEach(MokoCostume.all) { costume in
                    let unlocked = level >= costume.level
                    Button {
                        // Locked outfits cannot be picked.
                        guard unlocked else { return }
                        selectedLevel = costume.level
                    } label: {
                        HStack(spacing: 14) {
                            Image(costume.assetName)
                                .resizable()
                                .scaledToFit()
                                .padding(3)
                                .frame(width: 64, height: 64)
                                .background(MokoScreenTheme.Colors.surfaceLavender.opacity(unlocked ? 0.7 : 0.35), in: Circle())
                                .overlay(Circle().stroke(MokoScreenTheme.Colors.ctaAccent.opacity(0.15), lineWidth: 1))
                                .opacity(unlocked ? 1 : 0.55)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(costume.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                                Text(unlocked ? "Unlocked · Level \(costume.level)" : "Unlocks at Level \(costume.level)")
                                    .font(.subheadline)
                                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                            }
                            Spacer(minLength: 8)
                            if selectedLevel == costume.level && unlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MokoScreenTheme.Colors.brightGreen)
                                    .accessibilityLabel("Selected")
                            } else if !unlocked {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                                    .accessibilityLabel("Locked")
                            }
                        }
                        .frame(minHeight: 68)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                }
            } header: {
                Text("Costumes · \(MokoCostume.all.count)")
            } footer: {
                Text("Keep practicing to unlock each new look. Costumes are never for sale.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Moko’s wardrobe")
        .navigationBarTitleDisplayMode(.large)
        .tint(MokoScreenTheme.Colors.ctaAccent)
    }
}
