//
//  MocoScreenTheme.swift
//  Moko
//
//  Collection "Moco Screen Theme" v1.0 — iOS 27, 393×852 @3x, 4pt base.
//
//  Naming law (§0): a value is stated once, here, and referred to by name
//  everywhere else. No screen may restate a hex, a point size or a radius, and
//  no two names may describe the same value.
//
//  Registered names follow the spec's dotted paths:
//      moco.color.canvas.top      →  MocoScreenTheme.Colors.canvasTop
//      moco.type.title1           →  MocoScreenTheme.Typeface.title1
//      moco.space.page            →  MocoScreenTheme.Space.page
//      moco.radius.card           →  MocoScreenTheme.Radius.card
//      moco.stroke.card           →  MocoScreenTheme.Line.card
//

import SwiftUI

enum MocoScreenTheme {

    // MARK: - §2 Color registry

    enum Colors {
        static let canvasTop = Color(hex: 0xF3F8F0)
        static let canvasBottom = Color(hex: 0xE7F0E2)

        static let surfaceWhite = Color(hex: 0xFFFFFF)
        static let surfaceLavender = Color(hex: 0xEDEFF8)

        static let strokeInk = Color(hex: 0x17161C)

        static let textTitle = Color(hex: 0x17161C)
        static let textBody = Color(hex: 0x5E5B6A)
        static let textMuted = Color(hex: 0x6E6B7A)

        static let stateEmptyTitle = Color(hex: 0x2E5B4D)

        static let dataNumeral = Color(hex: 0x55457F)
        static let dataViolet = Color(hex: 0x8C7CB8)
        static let dataVioletDeep = Color(hex: 0x55457F)
        static let dataGrid = Color(hex: 0xC9CEDD)
        static let dataNode = Color(hex: 0x2B2440)

        static let accentBlue = Color(hex: 0x2168E0)
        static let accentBlueTint = Color(hex: 0xE8F1FF)

        static let countdownValue = Color(hex: 0x47679B)

        static let avatarFill = Color(hex: 0xC9CFE6)
        static let avatarText = Color(hex: 0x2F3346)

        /// Vector strokes carry their registration opacity with them.
        static let vectorBush = Color(hex: 0x7FAF79).opacity(0.15)
        static let vectorLeaf = Color(hex: 0x8FB98A).opacity(0.18)

        static let tabActiveBackground = Color(hex: 0xEDE6F7)
        static let tabActiveGlyph = Color(hex: 0x2F6B4F)
        static let tabInactive = Color(hex: 0x1E1C26)

        // MARK: Profile

        static let cream = Color(hex: 0xFBF6EA)
        static let forest = Color(hex: 0x254C3C)
        static let sage = Color(hex: 0x3F6B54)

        /// Hero gradient, topLeft → bottomRight.
        static let heroTop = Color(hex: 0x55866A)
        static let heroMid = Color(hex: 0x3F6B54)
        static let heroBottom = Color(hex: 0x2C5140)
        static let heroInk = Color(hex: 0xF1F6EE)
        /// Hero vectors, each carrying its registration opacity.
        static let heroVector = Color(hex: 0xDCEBD5)
        static let heroVectorBush = heroVector.opacity(0.14)
        static let heroVectorLeaf = heroVector.opacity(0.12)
        /// The hero's round navigation buttons.
        static let heroButtonSurface = Color(hex: 0xFFFFFF).opacity(0.16)

        /// Top stop of the avatar gradient. The bottom stop is `avatarFill`.
        static let avatarTop = Color(hex: 0xE6E1F2)
        static let avatarRing = Color(hex: 0xF6FAF2)

        /// Icon plate tints, cycled by stat / chip position.
        static let tileSage = Color(hex: 0xE2EFDD)
        static let tileLilac = Color(hex: 0xE5E1F1)
        static let tileCream = Color(hex: 0xE9EFE2)

        static let trackCream = Color(hex: 0xEFE8D8)
        static let lockedSurface = Color(hex: 0xF4F2EC)
        static let lockedInk = Color(hex: 0x9A94A4)
        static let chevron = Color(hex: 0xA6A2B0)
        static let axisLabel = Color(hex: 0x8E8778)
        static let ringTrack = Color(hex: 0xD6D8E8)
        static let error = Color(hex: 0xB9583F)

        /// Medal metals, used only by the badge artwork.
        static let medalGold = Color(hex: 0xD9A441)
        static let medalSilver = Color(hex: 0xB9C1C3)
    }

    // MARK: - §1 Scale

    enum Space {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s7: CGFloat = 32
        static let s8: CGFloat = 40

        /// Page gutter.
        static let page = s6
        /// Profile uses the board's 20pt inset, not the 24pt OverView gutter.
        static let profilePage: CGFloat = 20
        /// Profile card inset. The board is a touch tighter than the OverView card.
        static let profileCard: CGFloat = 15
        /// Card inset, vertical.
        static let cardVertical: CGFloat = 18
        /// Card inset, horizontal.
        static let cardHorizontal = s5
        /// Between a card and the section title above it.
        static let gapSection = s4
        /// Between two lines inside a card.
        static let gapInner = s2
        /// Between two sibling cards.
        static let gapCard = s4

        static let safeTop: CGFloat = 59
        static let safeBottom: CGFloat = 34
        /// Floating tab capsule band, measured from the bottom edge.
        static let tabBand: CGFloat = 96
    }

    /// The card surface. One fill for every card on the screen, so the mission
    /// card and the two growth cards can never drift apart.
    enum Card {
        static let fill = Colors.surfaceWhite
        /// §1 registers a 2pt ink outline. It is suppressed: cards separate by
        /// lift instead of line. Raise this to bring the outline back.
        static let outline: CGFloat = 0
        /// Debrief affordance wash — deliberately lighter than accent.blue.tint at full strength.
        static let wash = Colors.accentBlueTint.opacity(0.55)
    }

    /// SF Symbol point sizes. Glyphs are not type, so they get their own names.
    enum Glyph {
        static let avatar: CGFloat = 16
        static let mic: CGFloat = 18
        static let disclosure: CGFloat = 11
    }

    /// Fixed component dimensions (§6).
    enum Size {
        static let avatar: CGFloat = 44
        static let avatarLarge: CGFloat = 84
        static let hero: CGFloat = 178
        /// Growth cards keep the taller mass they had before the migration;
        /// 140 read as too short next to the mission card.
        static let progressCard: CGFloat = 172
        static let radar: CGFloat = 106
        static let barChart = CGSize(width: 116, height: 72)
    }

    enum Radius {
        static let card: CGFloat = 22
        static let inner: CGFloat = 14
        static let pill: CGFloat = 999
        static let knob: CGFloat = 23
        static let avatar: CGFloat = 22
        /// Profile stat tile.
        static let tile: CGFloat = 18
        /// Profile chip and setting row.
        static let chip: CGFloat = 16
        /// Hero bottom corners.
        static let hero: CGFloat = 42
    }

    enum Line {
        static let card: CGFloat = 2
        static let hair: CGFloat = 1
        static let data: CGFloat = 1.5
        static let tab: CGFloat = 1
    }

    // MARK: - §6.4 Control/Slide metrics

    enum Control {
        static let trackHeight: CGFloat = 54
        static let knob: CGFloat = 46
        static let knobInset: CGFloat = 4
        static let completionThreshold: CGFloat = 0.78
        static let chevronSize: CGFloat = 10
        /// Minimum touch target for the debrief affordance.
        static let mic: CGFloat = 54
    }

    // MARK: - §3 Type registry

    /// One registered type style. Sizes are scaled by Dynamic Type unless
    /// `fixed` is set, matching the spec's `moco.type.tab` exception.
    struct TextStyle {
        let size: CGFloat
        let leading: CGFloat
        let weight: Font.Weight
        let tracking: CGFloat
        let relativeTo: Font.TextStyle
        var tabularFigures: Bool = false
        var fixed: Bool = false

        /// SwiftUI adds ~20% of the point size as default leading.
        var extraLineSpacing: CGFloat { max(0, leading - size * 1.2) }
    }

    enum Typeface {
        static let title1 = TextStyle(size: 32, leading: 38, weight: .bold,
                                      tracking: -0.4, relativeTo: .largeTitle)
        static let title2 = TextStyle(size: 22, leading: 28, weight: .semibold,
                                      tracking: -0.2, relativeTo: .title2)
        static let section = TextStyle(size: 21, leading: 26, weight: .semibold,
                                       tracking: 0, relativeTo: .title3)
        static let cardTitle = TextStyle(size: 17, leading: 22, weight: .semibold,
                                         tracking: 0, relativeTo: .body)
        static let body = TextStyle(size: 15, leading: 22, weight: .regular,
                                    tracking: 0, relativeTo: .subheadline)
        static let caption = TextStyle(size: 13, leading: 18, weight: .medium,
                                       tracking: 0, relativeTo: .footnote)
        static let numeral = TextStyle(size: 44, leading: 44, weight: .bold,
                                       tracking: -1.0, relativeTo: .largeTitle,
                                       tabularFigures: true)
        static let unit = TextStyle(size: 15, leading: 20, weight: .medium,
                                    tracking: 0, relativeTo: .subheadline)
        static let slider = TextStyle(size: 15, leading: 20, weight: .semibold,
                                      tracking: 0.2, relativeTo: .headline)
        static let tab = TextStyle(size: 10, leading: 12, weight: .medium,
                                   tracking: 0, relativeTo: .caption2, fixed: true)

        // MARK: Profile

        /// Stat tile value.
        static let stat = TextStyle(size: 19, leading: 21, weight: .bold,
                                    tracking: 0, relativeTo: .title2, tabularFigures: true)
        /// Smallest label: stat captions, chip labels, day axis.
        static let badge = TextStyle(size: 9.5, leading: 11, weight: .bold,
                                     tracking: 0, relativeTo: .caption2)
        /// Setting row title.
        static let rowTitle = TextStyle(size: 12.5, leading: 16, weight: .semibold,
                                        tracking: 0, relativeTo: .subheadline)
        /// Journey headline number.
        static let journeyValue = TextStyle(size: 25, leading: 30, weight: .bold,
                                            tracking: 0, relativeTo: .title2,
                                            tabularFigures: true)
        /// Profile display name.
        static let profileName = TextStyle(size: 27, leading: 32, weight: .bold,
                                           tracking: -0.3, relativeTo: .largeTitle)
    }

    // MARK: - §1 Elevation

    enum Elevation {
        /// Cards float on a tinted two-layer lift: a 1pt contact line plus a wide
        /// ambient shadow. Both are green-black, never pure black.
        static let nearColor = Color(hex: 0x1E2D23).opacity(0.05)
        static let nearRadius: CGFloat = 1
        static let nearOffset: CGFloat = 1

        static let ambientColor = Color(hex: 0x1E2D23).opacity(0.11)
        static let ambientRadius: CGFloat = 13
        static let ambientOffset: CGFloat = 12

        /// The knob needs to read as grabbable, still without a hard shadow.
        static let knobColor = Color.black.opacity(0.14)
        static let knobRadius: CGFloat = 6
        static let knobOffset: CGFloat = 2

        /// The hero avatar straddles the seam, so it needs its own lift.
        static let avatarColor = Color(hex: 0x1E2D23).opacity(0.20)
        static let avatarRadius: CGFloat = 12
        static let avatarOffset: CGFloat = 10
    }

    // MARK: - §7 Motion

    enum Motion {
        /// Selection and value changes.
        static let tap = Animation.spring(response: 0.28, dampingFraction: 0.86)
        /// Release under threshold.
        static let snapBack = Animation.spring(response: 0.34, dampingFraction: 0.82)
        /// Snap to the end once the threshold is crossed.
        static let snapToEnd = Animation.spring(response: 0.24, dampingFraction: 0.9)
        /// Card state crossfade.
        static let crossfade = Animation.easeInOut(duration: 0.24)
        /// Knob glyph swap.
        static let glyphSwap = Animation.easeInOut(duration: 0.18)
        /// Idle knob breath.
        static let breath = Animation.easeInOut(duration: 2.4)
        /// Track flash while completing.
        static let flash = Animation.easeInOut(duration: 0.12)
    }
}

// MARK: - Type application

private struct MocoTextStyleModifier: ViewModifier {
    private let style: MocoScreenTheme.TextStyle

    @ScaledMetric private var size: CGFloat

    init(_ style: MocoScreenTheme.TextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        let resolvedSize = style.fixed ? style.size : size
        let base = Font.system(size: resolvedSize, weight: style.weight)

        return content
            .font(style.tabularFigures ? base.monospacedDigit() : base)
            .tracking(style.tracking)
            .lineSpacing(style.extraLineSpacing)
    }
}

extension View {
    /// Applies a registered `moco.type.*` style, including Dynamic Type scaling.
    func mocoText(_ style: MocoScreenTheme.TextStyle) -> some View {
        modifier(MocoTextStyleModifier(style))
    }
}
