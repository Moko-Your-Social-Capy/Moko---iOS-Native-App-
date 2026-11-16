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
    static let navButton: CGFloat = 48
    static let navInset: CGFloat = 18
    static let levelChipHeight: CGFloat = 32
    static let levelChipInset: CGFloat = 14
    static let statPlate: CGFloat = 36
    static let statFill: CGFloat = 14
    static let chipPlate: CGFloat = 40
    static let settingPlate: CGFloat = 40
    static let settingPlateRadius: CGFloat = 12
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
                .font(.title3.weight(.semibold))
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
                .font(.caption.weight(.bold))

            Text("Level \(level)")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Theme.Colors.sage)
        .padding(.horizontal, Metric.levelChipInset)
        .frame(minHeight: Metric.levelChipHeight)
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

/// Stat tiles wrap onto another row when larger text needs more room.
struct MokoStatsRow: View {
    let tiles: [MokoStat]
    // Accessibility text gets a full-width card rather than a squeezed column.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 104), spacing: Theme.Space.s3)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Space.s3) {
            ForEach(tiles) { tile in
                MokoStatTile(stat: tile)
            }
        }
    }
}

private struct MokoStatTile: View {
    let stat: MokoStat
    // The icon's backing grows with its symbol when larger text is selected.
    @ScaledMetric(relativeTo: .body) private var iconSize = Metric.statPlate

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s1) {
            Image(systemName: stat.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(stat.tint)
                .frame(width: iconSize, height: iconSize)
                .background(stat.plate, in: Circle())
                .padding(.bottom, 5)

            Text(stat.value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.Colors.dataVioletDeep)
                .fixedSize(horizontal: false, vertical: true)

            Text(stat.label)
                .font(.footnote)
                .foregroundStyle(Theme.Colors.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == index
                                         ? Theme.Colors.forest
                                         : Theme.Colors.textMuted)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, minHeight: 44)
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
    // Keep the badge symbol and its backing in step with the text size.
    @ScaledMetric(relativeTo: .body) private var iconSize = Metric.chipPlate

    var body: some View {
        VStack(spacing: Theme.Space.s2) {
            Image(systemName: locked ? "lock" : symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(locked ? Theme.Colors.textBody : tint)
                .frame(width: iconSize, height: iconSize)
                .background(locked ? Theme.Colors.lockedSurface : plate, in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(locked ? Theme.Colors.textBody : Theme.Colors.textTitle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .padding(Theme.Space.s3)
        .mokoCard(fill: locked ? Theme.Colors.lockedSurface : Theme.Colors.surfaceWhite,
                  radius: Theme.Radius.chip,
                  lift: !locked)
    }
}

/// One readable icon-and-title style for Profile cards and native Settings rows.
struct MokoSettingsLabelStyle: LabelStyle {
    var isDestructive = false
    // Larger text gets a larger icon plate without squeezing the label.
    @ScaledMetric(relativeTo: .body) private var iconSize = Metric.settingPlate

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Theme.Space.s4) {
            configuration.icon
                .font(.title3.weight(.semibold))
                .foregroundStyle(isDestructive ? Theme.Colors.error : Theme.Colors.forest)
                .frame(width: iconSize, height: iconSize)
                .background(
                    isDestructive ? Theme.Colors.error.opacity(0.1) : Theme.Colors.surfaceLavender,
                    in: RoundedRectangle(cornerRadius: Metric.settingPlateRadius, style: .continuous)
                )
                .accessibilityHidden(true)

            configuration.title
                .font(.headline)
                .foregroundStyle(isDestructive ? Theme.Colors.error : Theme.Colors.textTitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Theme.Space.s1)
    }
}

// MARK: - Setting row (§8)

/// One tappable settings row: icon, title and a ">" arrow.
struct MokoSettingRow: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: Theme.Space.s3) {
            Label(title, systemImage: symbol)
                .labelStyle(MokoSettingsLabelStyle())

            Spacer(minLength: Theme.Space.s2)

            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.Colors.textBody)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Theme.Space.s4)
        .padding(.vertical, Theme.Space.s2)
        .frame(minHeight: 72)
        .contentShape(Rectangle())
    }
}
