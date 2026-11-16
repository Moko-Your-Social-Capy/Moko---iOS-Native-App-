//
//  MokoLottieDemoView.swift
//  Moko
//
//  Debug / QA screen for previewing all bundled Lottie animations.
//  Navigate here from Settings in a debug build to verify files, speeds and
//  loop modes before shipping.
//

import SwiftUI
import Lottie

// MARK: - Main demo view

struct MokoLottieDemoView: View {
    // Which animation is on the preview stage.
    @State private var selectedAnimation: MokoAnimation = .confetti
    // Loop mode for the preview; uses Lottie's own enum directly.
    @State private var loopMode: Lottie.LottieLoopMode = .playOnce
    // Speed multiplier applied to the preview.
    @State private var speed: Double = 1.0
    // Toggle to restart the animation (toggling forces SwiftUI to rebuild the view).
    @State private var animationID = 0
    // Visible scale of the preview card.
    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    previewCard
                    selectorGrid
                    controlsCard
                    integrationExamples
                    packageStatus
                }
                .padding()
            }
            .background(MokoBackdrop())
            .navigationTitle("Lottie Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Preview stage

    private var previewCard: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .mokoText(MokoScreenTheme.Typeface.title2)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            // Re-keying with animationID forces LottieView to restart from frame 0.
            MokoLottieView(animation: selectedAnimation,
                           loopMode: loopMode,
                           speed: speed)
                .frame(width: 180 * animationScale,
                       height: 180 * animationScale)
                .id(animationID)
                .animation(.spring(response: 0.3), value: animationScale)

            Button("Restart") { animationID += 1 }
                .mokoButtonStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.08))
        )
    }

    // MARK: - Animation selector

    private var selectorGrid: some View {
        VStack(spacing: 12) {
            Text("Animations")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 10) {
                ForEach(MokoAnimation.allCases, id: \.self) { item in
                    animationTile(item)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.08))
        )
    }

    private func animationTile(_ item: MokoAnimation) -> some View {
        let isSelected = selectedAnimation == item
        return Button {
            selectedAnimation = item
            animationID += 1
        } label: {
            VStack(spacing: 6) {
                Image(systemName: iconName(for: item))
                    .font(.system(size: 22))
                    .foregroundStyle(item.accentColor)
                    .frame(width: 52, height: 52)
                    .background(item.accentColor.opacity(0.12))
                    .clipShape(Circle())

                Text(item.filename)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(isSelected ? MokoScreenTheme.Colors.textTitle
                                               : MokoScreenTheme.Colors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? item.accentColor.opacity(0.14)
                                     : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? item.accentColor.opacity(0.3)
                                              : MokoScreenTheme.Colors.borderSubtle,
                                    lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Controls

    private var controlsCard: some View {
        VStack(spacing: 16) {
            Text("Controls")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            // Loop mode picker — only valid LottieLoopMode cases.
            VStack(alignment: .leading, spacing: 6) {
                Text("Loop mode")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)

                Picker("Loop mode", selection: $loopMode) {
                    // These are the only cases LottieLoopMode actually has.
                    Text("Once").tag(Lottie.LottieLoopMode.playOnce)
                    Text("Loop").tag(Lottie.LottieLoopMode.loop)
                    Text("Reverse").tag(Lottie.LottieLoopMode.autoReverse)
                }
                .pickerStyle(.segmented)
                // Two-argument onChange form required by Swift 6.
                .onChange(of: loopMode) { _, _ in animationID += 1 }
            }

            // Speed slider.
            VStack(alignment: .leading, spacing: 6) {
                Text("Speed: \(speed, format: .number.precision(.fractionLength(1)))×")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)

                Slider(value: $speed, in: 0.25...3.0, step: 0.25)
                    .onChange(of: speed) { _, _ in animationID += 1 }
            }

            // Scale slider.
            VStack(alignment: .leading, spacing: 6) {
                Text("Scale: \(animationScale, format: .number.precision(.fractionLength(1)))×")
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)

                Slider(value: $animationScale, in: 0.5...2.0, step: 0.25)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.08))
        )
    }

    // MARK: - Integration examples

    private var integrationExamples: some View {
        VStack(spacing: 12) {
            Text("Integration Examples")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            exampleRow("Onboarding success",  "Success check + confetti",
                       a1: .successCheck, a2: .confetti)
            exampleRow("Quest completion",    "Confetti celebration",
                       a1: .confetti, a2: nil)
            exampleRow("Streak milestone",    "Flame + sparkles",
                       a1: .streakFlame, a2: .sparkles)
            exampleRow("Empty state",         "Subtle looping empty",
                       a1: .empty, a2: nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.08))
        )
    }

    private func exampleRow(
        _ title: String, _ description: String,
        a1: MokoAnimation, a2: MokoAnimation?
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                MokoLottieView(animation: a1, loopMode: .playOnce)
                    .frame(width: 50, height: 50)
                if let a2 {
                    MokoLottieView(animation: a2, loopMode: .playOnce)
                        .frame(width: 30, height: 30)
                        .offset(x: 18, y: -18)
                }
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                Text(description)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
            }

            Spacer()

            Button("Preview") {
                selectedAnimation = a1
                animationID += 1
            }
            .mokoButtonStyle(.smallSecondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Package status

    private var packageStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Package Status")
                .mokoText(MokoScreenTheme.Typeface.title3)
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)

            // Lottie is always importable here because this file imports it.
            // If the package were missing the file would not compile at all.
            DemoStatusRow(
                icon: "checkmark.circle.fill",
                title: "lottie-ios",
                status: "Linked",
                color: MokoScreenTheme.Colors.dataTeal
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.08))
        )
    }

    // MARK: - Helpers

    private func iconName(for animation: MokoAnimation) -> String {
        switch animation {
        case .confetti:      return "party.popper"
        case .empty:         return "square.dashed"
        case .streakFlame:   return "flame"
        case .sparkles:      return "sparkles"
        case .successCheck:  return "checkmark.circle"
      
        }
    }
}

// MARK: - Status row component

/// A single status row showing an icon, label and status string in a chosen colour.
struct DemoStatusRow: View {
    let icon: String
    let title: String
    let status: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                Text(status)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(color)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview { MokoLottieDemoView() }
