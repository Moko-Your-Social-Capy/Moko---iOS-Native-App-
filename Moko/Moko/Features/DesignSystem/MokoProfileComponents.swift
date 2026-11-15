//
//  MokoProfileComponents.swift
//  Moko
//
//  Building blocks used only by the Profile screen:
//  hero header, avatar, level chip, stat tiles, segmented picker,
//  weekly bars, achievement chips and settings rows.
//  Colours and sizes come from `MokoScreenTheme`.
//

import SwiftUI
import UIKit

// A short nickname so we can write `Theme.Colors` instead of `MokoScreenTheme.Colors`.
private typealias Theme = MokoScreenTheme

/// Component-internal metrics. Not screen tokens: they describe one view's
/// construction, not a design decision the rest of the app shares.
private enum Metric {
    static let navButton: CGFloat = 36
    static let navGlyph: CGFloat = 17
    static let navInset: CGFloat = 18
    static let levelChipHeight: CGFloat = 26
    static let levelChipInset: CGFloat = 11
    static let levelGlyph: CGFloat = 9.5
    static let statPlate: CGFloat = 24
    static let statGlyph: CGFloat = 13
    static let statFill: CGFloat = 10
    static let chipPlate: CGFloat = 26
    static let chipGlyph: CGFloat = 14
    static let settingPlate: CGFloat = 28
    static let settingPlateRadius: CGFloat = 9
    static let settingGlyph: CGFloat = 14
    static let chevronGlyph: CGFloat = 13
    static let weekBarHeight: CGFloat = 66
    static let weekBarRadius: CGFloat = 5
    static let weekBarGap: CGFloat = 9
}

// MARK: - Hero (§3)

/// 178pt sage gradient with the bush and leaf strokes, 42pt bottom corners, and
/// an avatar that overlaps the seam by half its height without being clipped.
struct MokoProfileHero<Avatar: View>: View {
    let title: String
    let onClose: () -> Void
    let onOverflow: () -> Void
    /// Height of the hero gradient band. Defaults to `Theme.Size.hero`; use
    /// `heroLarge` for the bigger, brighter profile section.
    var height: CGFloat = Theme.Size.hero
    /// Size of the avatar that overlaps the hero's bottom edge.
    var avatarSize: CGFloat = Theme.Size.avatarLarge
    // @ViewBuilder lets the caller pass in any view (here, the avatar) using `{ ... }`.
    @ViewBuilder var avatar: () -> Avatar

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Colors.heroTop, Theme.Colors.heroMid, Theme.Colors.heroBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                VectorBushShape()
                    .stroke(Theme.Colors.heroVectorBush, lineWidth: Theme.Line.data)
                    .frame(width: 220, height: 142)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -70, y: geo.size.height - 142 + 34)

                VectorLeafShape()
                    .stroke(Theme.Colors.heroVectorLeaf, lineWidth: Theme.Line.data)
                    .frame(width: 150, height: 69)
                    .rotationEffect(.degrees(14))
                    .offset(x: geo.size.width - 60, y: 34)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(height: height)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Theme.Radius.hero,
                bottomTrailingRadius: Theme.Radius.hero,
                style: .continuous
            )
        )
        .overlay(alignment: .top) { navigationRow }
        .overlay(alignment: .bottom) {
            // Push the avatar down by half its height so it sits on the hero's bottom edge.
            avatar()
                .offset(y: avatarSize / 2)
        }
    }

    private var navigationRow: some View {
        HStack(spacing: Theme.Space.s2) {
            circleButton(symbol: "xmark", action: onClose, label: "Close profile")

            Spacer(minLength: 0)

            Text(title)
                .mokoText(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Colors.heroInk)

            Spacer(minLength: 0)

            circleButton(symbol: "ellipsis", action: onOverflow, label: "Edit profile")
        }
        .padding(.horizontal, Metric.navInset)
        .padding(.top, Theme.Space.s2)
    }

    private func circleButton(symbol: String,
                              action: @escaping () -> Void,
                              label: String) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Metric.navGlyph, weight: .semibold))
                .foregroundStyle(Theme.Colors.surfaceWhite)
                .frame(width: Metric.navButton, height: Metric.navButton)
                .background(Theme.Colors.heroButtonSurface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Avatar

/// The round profile picture: the user's photo, or Moko wearing the costume for their level.
struct MokoProfileAvatar: View {
    let level: Int
    let photoData: Data?
    /// Size of the circle. Defaults to the regular avatar size; use
    /// `avatarExtraLarge` for the bigger, brighter profile hero.
    var size: CGFloat = Theme.Size.avatarLarge

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Theme.Colors.avatarTop, Theme.Colors.avatarFill],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))

            MokoCostumeAvatar(level: level,
                              photoData: photoData,
                              size: size,
                              background: .clear,
                              ring: nil)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .padding(Theme.Space.s1)
        .background(Circle().fill(Theme.Colors.avatarRing))
        .shadow(color: Theme.Elevation.avatarColor,
                radius: Theme.Elevation.avatarRadius,
                x: 0, y: Theme.Elevation.avatarOffset)
    }
}

// MARK: - Identity

/// The level pill under the name: sparkles + short badge label on a floating
/// white capsule. It is the only element on the canvas allowed to float free of
/// a card, so its shadow is the near lift rather than the two-layer card lift.
struct MokoLevelChip: View {
    let level: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: Metric.levelGlyph, weight: .bold))

            Text("Level \(level)")
                .mokoText(Theme.Typeface.badge)
        }
        .foregroundStyle(Theme.Colors.sage)
        .padding(.horizontal, Metric.levelChipInset)
        .frame(height: Metric.levelChipHeight)
        .background(Theme.Colors.surfaceWhite, in: Capsule())
        .shadow(color: Theme.Elevation.nearColor, radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(level)")
    }
}

// MARK: - Stats (§5)

/// The data for one small stat tile (for example "12 Quests").
struct MokoStat: Identifiable {
    let id: Int
    let symbol: String
    let value: String
    let label: String
    /// Plate the icon sits on, and the ink it is drawn in.
    let plate: Color
    let tint: Color
    let fill: Color
}

/// A row of stat tiles that share the width equally.
struct MokoStatsRow: View {
    let tiles: [MokoStat]

    var body: some View {
        HStack(spacing: Theme.Space.s2) {
            ForEach(tiles) { tile in
                MokoStatTile(stat: tile)
            }
        }
    }
}

private struct MokoStatTile: View {
    let stat: MokoStat

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Image(systemName: stat.symbol)
                .font(.system(size: Metric.statGlyph, weight: .semibold))
                .foregroundStyle(stat.tint)
                .frame(width: Metric.statPlate, height: Metric.statPlate)
                .background(stat.plate, in: Circle())
                .padding(.bottom, 5)

            Text(stat.value)
                .mokoText(Theme.Typeface.stat)
                .foregroundStyle(Theme.Colors.dataVioletDeep)

            Text(stat.label)
                .mokoText(Theme.Typeface.badge)
                .foregroundStyle(Theme.Colors.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metric.statFill)
        .mokoCard(fill: stat.fill, radius: Theme.Radius.tile)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.value), \(stat.label)")
    }
}

// MARK: - Segmented (§6)

/// A small pill-style tab picker (for example Week / Month).
struct MokoSegmented: View {
    let titles: [String]
    // @Binding means the parent owns `selection`; we only read and change it.
    @Binding var selection: Int
    // The phone setting "Reduce Motion". If it is on, the switch happens without animation.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) { selection = index }
                } label: {
                    Text(title)
                        .mokoText(Theme.Typeface.badge)
                        .foregroundStyle(selection == index
                                         ? Theme.Colors.forest
                                         : Theme.Colors.textMuted)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background {
                            if selection == index {
                                Capsule()
                                    .fill(Theme.Colors.surfaceWhite)
                                    .shadow(color: Theme.Elevation.nearColor, radius: 1.5, y: 1)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Theme.Colors.trackCream,
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Week bars (§6)

/// Seven bars, diagonal hatch, the peak solid in forest.
struct MokoWeekBars: View {
    /// The bar gap, exposed so an axis row can align to the same columns.
    static let spacing = Metric.weekBarGap

    /// Normalised heights, 0…1, oldest first.
    let values: [Double]
    /// Index drawn solid instead of hatched.
    let peak: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: Metric.weekBarGap) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                bar(isPeak: index == peak)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, Metric.weekBarHeight * value))
            }
        }
        .frame(height: Metric.weekBarHeight, alignment: .bottom)
        .accessibilityElement()
        .accessibilityLabel("Weekly experience points")
    }

    @ViewBuilder
    private func bar(isPeak: Bool) -> some View {
        if isPeak {
            RoundedRectangle(cornerRadius: Metric.weekBarRadius, style: .continuous)
                .fill(Theme.Colors.forest)
        } else {
            RoundedRectangle(cornerRadius: Metric.weekBarRadius, style: .continuous)
                .fill(Theme.Colors.dataViolet.opacity(0.18))
                .overlay {
                    HatchedFill()
                        .clipShape(RoundedRectangle(cornerRadius: Metric.weekBarRadius,
                                                    style: .continuous))
                }
        }
    }
}

/// 45° stripes, 2pt wide, 5pt apart. One shape, never a tiled image.
private struct HatchedFill: View {
    var body: some View {
        // Canvas draws with code, like a tiny paint program. Here we draw diagonal lines.
        Canvas { context, size in
            var x = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                context.stroke(path, with: .color(Theme.Colors.dataViolet), lineWidth: 2)
                x += 5
            }
        }
    }
}

// MARK: - Achievement chip (§7)

/// One achievement badge. Locked badges are greyed out and show a lock icon.
struct MokoAchievementChip: View {
    let symbol: String
    let title: String
    let plate: Color
    let tint: Color
    let locked: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: locked ? "lock" : symbol)
                .font(.system(size: Metric.chipGlyph, weight: .semibold))
                .foregroundStyle(locked ? Theme.Colors.lockedInk : tint)
                .frame(width: Metric.chipPlate, height: Metric.chipPlate)
                .background(locked ? Theme.Colors.lockedSurface : plate, in: Circle())

            Text(title)
                .mokoText(Theme.Typeface.badge)
                .foregroundStyle(locked ? Theme.Colors.lockedInk : Theme.Colors.textTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 9)
        .padding(.top, 5)
        .padding(.bottom, 8)
        .mokoCard(fill: locked ? Theme.Colors.lockedSurface : Theme.Colors.surfaceWhite,
                  radius: Theme.Radius.chip,
                  lift: !locked)
    }
}

// MARK: - Setting row (§8)

/// One tappable settings row: icon, title and a ">" arrow.
struct MokoSettingRow: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: Metric.settingGlyph, weight: .semibold))
                .foregroundStyle(Theme.Colors.dataVioletDeep)
                .frame(width: Metric.settingPlate, height: Metric.settingPlate)
                .background(Theme.Colors.surfaceLavender,
                            in: RoundedRectangle(cornerRadius: Metric.settingPlateRadius,
                                                 style: .continuous))

            Text(title)
                .mokoText(Theme.Typeface.rowTitle)
                .foregroundStyle(Theme.Colors.textTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: Theme.Space.s2)

            Image(systemName: "chevron.right")
                .font(.system(size: Metric.chevronGlyph, weight: .semibold))
                .foregroundStyle(Theme.Colors.chevron)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .contentShape(Rectangle())
    }
}
