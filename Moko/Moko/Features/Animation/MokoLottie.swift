
import SwiftUI
import Lottie

// MARK: - Animation Catalogue

enum MokoAnimation: String, CaseIterable {
    // Real files in the bundle: the raw value is the exact file name
    case confetti = "confetti"
    case confetti2 = "Confetti 2"
    case empty = "empty"
    case streakFlame = "flame___streak"
    case sparkles = "sparkles"
    case successCheck = "success_check"   // use your real file name
    case loading2 = "loading-2"
    case brickBreathing = "[BB] Brick breathing"
    case easterBunnyWaving = "Easter Bunny Boy waving"
    // add "strings" here only once strings.lottie is in the project

    // Placeholders: no raw value of their own
    case mokoWaving, mokoListening, breathing, grounding, guidedImagery, mirrorReflection, strings

    // Exact JSON filename without the .json extension.
    var filename: String { rawValue }

    var defaultLoopMode: Lottie.LottieLoopMode {
        switch self {
        case .streakFlame, .breathing, .loading2, .brickBreathing, .easterBunnyWaving:
            return .loop
        case .confetti, .confetti2, .sparkles, .successCheck, .empty, .mokoWaving, .mokoListening,
             .grounding, .guidedImagery, .mirrorReflection, .strings:
            return .playOnce
        }
    }

    var respectsReduceMotion: Bool {
        switch self {
        case .confetti, .confetti2, .sparkles:
            return true
        default:
            return false
        }
    }

    var accentColor: Color {
        switch self {
        case .confetti, .confetti2:
            return Color(red: 0.85, green: 0.20, blue: 0.65)
        case .empty:
            return .gray
        case .streakFlame:
            return .yellow
        case .sparkles:
            return .blue
        case .successCheck:
            return .green
        case .mokoWaving, .mokoListening, .easterBunnyWaving:
            return .orange
        case .breathing, .brickBreathing:
            return Color(hex: 0x365948) // forest green
        case .loading2:
            return MokoScreenTheme.Colors.dataVioletDeep
        case .grounding:
            return Color(hex: 0x2F4C43) // teal-green
        case .guidedImagery:
            return Color(hex: 0x54457E) // violet
        case .mirrorReflection:
            return Color(hex: 0x55749F) // blue-purple
        case .strings:
            return Color(hex: 0xC4547A) // magenta
        }
    }

    var iconName: String {
        switch self {
        case .confetti, .confetti2: return "party.popper"
        case .empty: return "square.dashed"
        case .streakFlame: return "flame"
        case .sparkles: return "sparkles"
        case .successCheck: return "checkmark.circle"
        case .mokoWaving, .easterBunnyWaving: return "hand.wave"
        case .mokoListening: return "ear"
        case .breathing, .brickBreathing: return "wind"
        case .loading2: return "arrow.2.circlepath"
        case .grounding: return "leaf"
        case .guidedImagery: return "brain.head.profile"
        case .mirrorReflection: return "person.crop.circle"
        case .strings: return "music.note"
        
        }
    }
}

// MARK: - SwiftUI Lottie View

struct MokoLottieView: View {
    let animation: MokoAnimation

    var loopMode: Lottie.LottieLoopMode? = nil
    var speed: Double = 1.0
    var contentMode: ContentMode = .fit

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private var effectiveLoopMode: Lottie.LottieLoopMode {
        loopMode ?? animation.defaultLoopMode
    }

    private var resolvedLottieAnimation: LottieAnimation? {
        LottieAnimation.named(animation.filename)
            ?? MokoAnimationAssets.url(named: animation.filename, extension: "json").flatMap { LottieAnimation.filepath($0.path) }
    }

    var body: some View {
        if animation.respectsReduceMotion && reduceMotion {
            fallbackIcon
        } else {
            lottieView
        }
    }

    @ViewBuilder
    private var lottieView: some View {
        if let resolvedLottieAnimation {
            LottieView(animation: resolvedLottieAnimation)
                .configure { view in
                    view.loopMode = effectiveLoopMode
                    view.animationSpeed = CGFloat(speed)
                    view.backgroundBehavior = .pauseAndRestore
                }
                .play()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(contentMode: contentMode)
                .accessibilityLabel("\(animation.filename) animation")
                .accessibilityHidden(true)
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: animation.iconName)
            .font(.system(size: 32))
            .foregroundStyle(animation.accentColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }
}

// MARK: - Convenience Modifier

extension View {
    func withLottieAnimation(
        _ animation: MokoAnimation,
        loopMode: Lottie.LottieLoopMode? = nil,
        speed: Double = 1.0,
        alignment: Alignment = .center
    ) -> some View {
        overlay(
            MokoLottieView(
                animation: animation,
                loopMode: loopMode,
                speed: speed
            )
            .allowsHitTesting(false),
            alignment: alignment
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(MokoAnimation.allCases, id: \.self) { item in
                VStack(spacing: 8) {
                    Text(item.filename)
                        .font(.caption)

                    MokoLottieView(animation: item)
                        .frame(height: 140)
                        .background(
                            MokoScreenTheme.Colors.surfaceLavender
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                }
            }
        }
        .padding()
    }
    .background(MokoBackdrop())
}
