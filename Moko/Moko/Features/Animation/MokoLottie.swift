
import SwiftUI
import Lottie

// MARK: - Animation Catalogue

enum MokoAnimation: String, CaseIterable {
    case confetti = "confetti"
    case empty = "empty"
    case streakFlame = "flame___streak"
    case sparkles = "sparkles"
    case successCheck = "success_check"

    // Exact JSON filename without the .json extension.
    var filename: String { rawValue }

    var defaultLoopMode: Lottie.LottieLoopMode {
        switch self {
        case .streakFlame:
            return .loop
        case .confetti, .sparkles, .successCheck, .empty:
            return .playOnce
        }
    }

    var respectsReduceMotion: Bool {
        switch self {
        case .confetti, .sparkles:
            return true
        default:
            return false
        }
    }

    var accentColor: Color {
        switch self {
        case .confetti:
            return Color(red: 0.85, green: 0.20, blue: 0.65)
        case .empty:
            return .gray
        case .streakFlame:
            return .yellow
        case .sparkles:
            return .blue
        case .successCheck:
            return .green
        }
    }

    var iconName: String {
        switch self {
        case .confetti: return "party.popper"
        case .empty: return "square.dashed"
        case .streakFlame: return "flame"
        case .sparkles: return "sparkles"
        case .successCheck: return "checkmark.circle"
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

    var body: some View {
        if animation.respectsReduceMotion && reduceMotion {
            fallbackIcon
        } else {
            lottieView
        }
    }

    private var lottieView: some View {
        LottieView(
            animation: .named(animation.filename, bundle: .main)
        )
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
