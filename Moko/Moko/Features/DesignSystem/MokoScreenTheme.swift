//
//  MokoScreenTheme.swift
//  Moko
//
//  The app's style sheet: every colour, spacing, size, font and animation
//  lives here once and has a name. Screens use the name, never the raw number.
//
//  Updated with centralized color system: all UI colors referenced from here.
//  Mission card (white), Progress cards (#ECEFF8), Purple accents, Charts,
//  Avatar, Tab bar, and Shadow tokens.
//

import SwiftUI

// An `enum` with no cases is just a named folder for constants; you cannot create one.
enum MokoScreenTheme {

    // MARK: - §2 Color registry

    /// Every colour in the app, resolved from the active MOKO theme.
    /// Legacy token names are preserved and mapped to semantic theme colors.
    enum Colors {
        @MainActor private static var t: MokoResolvedTheme { MokoThemeManager.shared.current }
        @MainActor private static var c: MokoThemeColors { t.colors }

        // MARK: Background
        static var lightSage: Color { c.backgroundTop }
        static var cleanWhite: Color { c.backgroundBottom }
        static var canvasTop: Color { c.backgroundTop }
        static var canvasBottom: Color { c.backgroundBottom }

        // MARK: Card Surfaces
        static var surfaceWhite: Color { c.cardSurface }
        static var surfaceLavender: Color { c.elevatedCardBackground }

        static var strokeInk: Color { c.border }

        // MARK: Text Colors
        static var textTitle: Color { c.textPrimary }
        static var textMissionTitle: Color { c.textPrimary }
        static var textBody: Color { c.textSecondary }
        static var textMuted: Color { c.textSecondary.opacity(0.85) }
        static var countdownValue: Color { c.ctaAccent }

        // MARK: Data Visualization
        static var dataViolet: Color { c.chartSecondary }
        static var dataVioletDeep: Color { c.chartPrimary }
        static var dataNumeral: Color { c.chartPrimary }
        static var dataGrid: Color { c.chartGrid }
        static var dataNode: Color { c.chartPrimary }

        static var accentBlue: Color { c.ctaAccent }
        static var accentBlueTint: Color { c.ctaAccent.opacity(0.15) }

        // MARK: Avatar
        static var avatarFill: Color { c.secondary.opacity(0.35) }
        static var avatarText: Color { c.textPrimary }

        static var vectorBush: Color { c.secondary.opacity(0.15) }
        static var vectorLeaf: Color { c.accent.opacity(0.18) }

        static var tabActiveGlyph: Color { c.selectedTab }

        // MARK: Profile
        static var cream: Color { c.card }
        static var forest: Color { c.primary }
        static var sage: Color { c.secondary }

        static var heroTop: Color { c.profileAccent }
        static var heroMid: Color { c.profileAccent }
        static var heroBottom: Color { c.profileAccent }
        static var heroInk: Color { c.inverseText }
        static var heroVector: Color { c.ctaAccent }
        static var heroVectorBush: Color { c.mokoMascotAccent.opacity(0.16) }
        static var heroVectorLeaf: Color { c.ctaAccent.opacity(0.14) }
        static var heroButtonSurface: Color { c.inverseText.opacity(0.16) }

        static var avatarTop: Color { c.secondary.opacity(0.25) }
        static var avatarRing: Color { c.card }

        static var tileSage: Color { c.secondary.opacity(0.18) }
        static var tileLilac: Color { c.accent.opacity(0.14) }
        static var tileCream: Color { c.elevatedSurface }

        static var trackCream: Color { c.elevatedSurface }
        static var lockedSurface: Color { c.inputBackground }
        static var lockedInk: Color { c.placeholder }
        static var chevron: Color { c.placeholder }
        static var axisLabel: Color { c.textSecondary.opacity(0.8) }
        static var error: Color { Color(hex: 0xB9583F) }

        static var medalGold: Color { Color(hex: 0xD9A441) }
        static var medalSilver: Color { Color(hex: 0xB9C1C3) }

        // MARK: Extended data palette
        static var dataMagenta: Color { c.chart3 }
        static var dataGold: Color { c.accent }
        static var dataTeal: Color { c.secondary }
        static var dataVioletLight: Color { c.secondary.opacity(0.4) }

        // MARK: Parameter-specific colors
        static var parameterCourage: Color { c.chart1 }
        static var parameterCourageDark: Color { c.primary }
        static var parameterClarity: Color { c.chart2 }
        static var parameterClarityDark: Color { c.secondary }
        static var parameterPresence: Color { c.chart4 }
        static var parameterPresenceDark: Color { c.primary.opacity(0.85) }
        static var parameterWarmth: Color { c.chart3 }
        static var parameterWarmthDark: Color { c.accent }

        // MARK: Score-based colors (semantic, consistent across themes)
        static var scoreExcellent: Color { c.success }
        static var scoreExcellentDark: Color { c.success.opacity(0.85) }
        static var scoreGood: Color { c.accent }
        static var scoreGoodDark: Color { c.accent.opacity(0.85) }
        static var scoreNeedsImprovement: Color { Color(hex: 0xC4547A) }
        static var scoreNeedsImprovementDark: Color { Color(hex: 0x9A3C5D) }

        // MARK: Button & UI Colors
        static var textOnBrand: Color { c.ctaAccentText }
        static var ctaAccent: Color { c.ctaAccent }
        static var cardShadow: Color { c.cardShadow }
        static var cardGlow: Color { c.cardGlow }
        static var chartTertiary: Color { c.chartTertiary }
        static var buttonDisabled: Color { c.disabledButton }
        static var borderSubtle: Color { c.cardBorder }

        // MARK: Profile bright
        static var brightGreen: Color { c.ctaAccent }
        static var brightSun: Color { c.missionAccent }
        static var brightHeroTop: Color { c.profileAccent }
        static var brightHeroBottom: Color { c.profileAccent }
    }

    // MARK: - §1 Scale

    /// Spacing steps on a 4-point grid (s1 = 4, s2 = 8, …). Use these for padding and gaps.
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

        /// Floating tab capsule band, measured from the bottom edge.
        static let tabBand: CGFloat = 96
    }

    /// The card surface. Mission card is white, progress cards are light lavender-blue.
    enum Card {
        /// Mission card fill (white/light in light, themed surface in dark)
        static var missionFill: Color { Colors.surfaceWhite }
        /// Progress cards fill (Insights and Calm Down)
        static var progressFill: Color { Colors.surfaceLavender }
        /// Default/standard card fill
        static var fill: Color { Colors.surfaceWhite }
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
        /// Height ÷ width of the `MokoMascot` picture. Keeps the mascot from looking squashed.
        static let mascotAspect: CGFloat = 758.0 / 592.0
        /// Size of the Moko flash image on the simulation intro screen.
        static let mascotFlash: CGFloat = 220
        static let avatar: CGFloat = 44
        static let avatarLarge: CGFloat = 84
        /// Extra-big avatar for the brighter profile hero.
        static let avatarExtraLarge: CGFloat = 130
        static let hero: CGFloat = 178
        /// Taller hero for the bigger, brighter profile section.
        static let heroLarge: CGFloat = 240
        /// Growth cards keep the taller mass they had before the migration;
        /// 140 read as too short next to the mission card.
        static let progressCard: CGFloat = 172
        static let radar: CGFloat = 106
        static let barChart = CGSize(width: 116, height: 72)
    }

    /// Corner radii. `pill` is so large that any shape becomes fully rounded.
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

    /// Line widths for borders and chart strokes.
    enum Line {
        static let card: CGFloat = 2
        static let hair: CGFloat = 1
        static let data: CGFloat = 1.5
        static let tab: CGFloat = 1
    }

    // MARK: - §6.4 Control/Slide metrics

    /// Sizes for the "slide to finish" control (`MokoSlideControl`).
    enum Control {
        static let trackHeight: CGFloat = 54
        static let knob: CGFloat = 46
        static let knobInset: CGFloat = 4
        /// How far (0–1) you must slide before letting go counts as "done".
        static let completionThreshold: CGFloat = 0.78
        static let chevronSize: CGFloat = 10
        /// Minimum touch target for the debrief affordance.
        static let mic: CGFloat = 54
    }

    // MARK: - §3 Type registry

    /// One registered type style. Sizes are scaled by Dynamic Type unless
    /// `fixed` is set, matching the spec's `moko.type.tab` exception.
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

    /// Named text styles. Apply one with `.mokoText(MokoScreenTheme.Typeface.body)`.
    enum Typeface {
        static let title1 = TextStyle(size: 32, leading: 38, weight: .bold,
                                      tracking: -0.4, relativeTo: .largeTitle)
        static let title2 = TextStyle(size: 22, leading: 28, weight: .semibold,
                                      tracking: -0.2, relativeTo: .title2)
        // Mid-level heading, one step below title2.
        static let title3 = TextStyle(size: 18, leading: 24, weight: .semibold,
                                      tracking: -0.1, relativeTo: .title3)
        // Section label above a form group (e.g. "Profile photo").
        static let sectionHeader = TextStyle(size: 13, leading: 18, weight: .semibold,
                                             tracking: 0.2, relativeTo: .caption)
        // Small label sitting directly above an input field.
        static let fieldLabel = TextStyle(size: 13, leading: 18, weight: .medium,
                                          tracking: 0, relativeTo: .footnote)
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
        static let button = TextStyle(size: 16, leading: 22, weight: .semibold,
                                      tracking: 0, relativeTo: .headline)

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

    /// Shadow settings that make cards look like they float above the background.
    enum Elevation {
        /// Cards float on a tinted two-layer lift: contact + ambient shadow from the active theme.
        @MainActor private static var shadow: Color { MokoThemeManager.shared.current.colors.cardShadow }
        static var nearColor: Color { shadow.opacity(0.06) }
        static let nearRadius: CGFloat = 1
        static let nearOffset: CGFloat = 1

        static var ambientColor: Color { shadow.opacity(0.14) }
        static let ambientRadius: CGFloat = 13
        static let ambientOffset: CGFloat = 12

        /// The knob needs to read as grabbable, still without a hard shadow.
        static let knobColor = Color.black.opacity(0.14)
        static let knobRadius: CGFloat = 6
        static let knobOffset: CGFloat = 2

        /// The hero avatar straddles the seam, so it needs its own lift.
        static var avatarColor: Color { shadow.opacity(0.22) }
        static let avatarRadius: CGFloat = 12
        static let avatarOffset: CGFloat = 10
    }

    // MARK: - §7 Motion

    /// Shared animations. Use them with `withAnimation(MokoScreenTheme.Motion.tap) { ... }`.
    /// A "spring" moves like a bouncy spring; `easeInOut` starts and ends slowly.
    enum Motion {
        /// One-shot mascot and achievement entrances.
        static let mascotEntrance = Animation.spring(duration: 0.5, bounce: 0.2)
        /// Selection and value changes.
        static let tap = Animation.spring(response: 0.28, dampingFraction: 0.86)
        /// Release under threshold.
        static let snapBack = Animation.spring(response: 0.34, dampingFraction: 0.82)
        /// Snap to the end once the threshold is crossed.
        static let snapToEnd = Animation.spring(response: 0.24, dampingFraction: 0.9)
        /// Card state crossfade.
        static let crossfade = Animation.easeInOut(duration: 0.24)
        /// Two panels part once to reveal a finished session.
        static let completionReveal = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.28)
        /// Knob glyph swap.
        static let glyphSwap = Animation.easeInOut(duration: 0.18)
        /// Idle knob breath.
        static let breath = Animation.easeInOut(duration: 2.4)
        /// Track flash while completing.
        static let flash = Animation.easeInOut(duration: 0.12)
    }
}

// MARK: - Type application

/// Turns one of our `TextStyle`s into a real SwiftUI font.
private struct MokoTextStyleModifier: ViewModifier {
    private let style: MokoScreenTheme.TextStyle

    // @ScaledMetric grows the size when the user picks bigger text in Settings.
    @ScaledMetric private var size: CGFloat

    init(_ style: MokoScreenTheme.TextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        // Fixed styles (like tab labels) ignore the text-size setting.
        let resolvedSize = style.fixed ? style.size : size
        // Use the font style chosen in Appearance settings (stored with the theme).
        let design = MokoThemeManager.shared.fontOption.design
        let base = Font.system(size: resolvedSize, weight: style.weight, design: design)

        return content
            // monospacedDigit makes every number the same width, so counters don't wobble.
            .font(style.tabularFigures ? base.monospacedDigit() : base)
            .tracking(style.tracking)
            .lineSpacing(style.extraLineSpacing)
    }
}

extension View {
    /// Applies a registered `moko.type.*` style, including Dynamic Type scaling.
    func mokoText(_ style: MokoScreenTheme.TextStyle) -> some View {
        modifier(MokoTextStyleModifier(style))
    }
}

// MARK: - Hex colours

extension Color {
    /// Makes a colour from a web-style hex code, e.g. `Color(hex: 0x2F6E4A)`.
    /// `>>` shifts the bits right and `& 0xFF` keeps the last two hex digits,
    /// which pulls out the red, green and blue parts one by one.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
