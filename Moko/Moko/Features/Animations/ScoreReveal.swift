//
//  ScoreReveal.swift
//  Moko
//
//  Animated score reveal with color-coded stat bars filling sequentially.
//  Each stat has its own distinct color from the harmony palette.
//

import SwiftUI

/// Parameter/stat types with their assigned harmonious colors.
enum StatParameter: String, CaseIterable {
    case courage
    case clarity
    case presence
    case warmth

    var title: String {
        self.rawValue.capitalized
    }

    /// Harmonious color palette: violet, green, indigo, teal-green family
    var color: Color {
        switch self {
        case .courage:
            return Color(hex: 0x7C3AED)  // vibrant violet/orchid
        case .clarity:
            return Color(hex: 0x10B981)  // emerald green
        case .presence:
            return Color(hex: 0x4F46E5)  // indigo/periwinkle
        case .warmth:
            return Color(hex: 0x14B8A6)  // teal-green
        }
    }

    /// Lighter version for track/background
    var trackColor: Color {
        color.opacity(0.18)
    }
}

/// Score reveal view showing animated stat bars and average.
struct ScoreReveal: View {
    let scores: [StatParameter: Int]  // 0...100 per stat
    /// How today's average compares with yesterday, in points. Nil hides the row.
    var comparison: Int? = nil
    /// XP earned for this debrief. Zero hides the badge.
    var xp: Int = 0
    /// Current streak, shown beside the XP badge. Zero hides it.
    var streak: Int = 0
    /// When set, a Continue button appears inside the same white card.
    var onContinue: (() -> Void)? = nil
    @State private var fills: [StatParameter: Double] = [:]
    @State private var average = 0
    @State private var tick = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 22) {
            // Large average number with numeric text transition
            Text("\(average)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                .contentTransition(.numericText(value: Double(average)))
                .animation(MokoMotion.snappy, value: average)

            Text("Average Score")
                .font(.caption)
                .foregroundStyle(MokoScreenTheme.Colors.textMuted)

            Divider()
                .padding(.vertical, 8)

            // A single comparison line keeps the "better than yesterday" story.
            if let comparison {
                HStack(spacing: 4) {
                    Text("Compared to yesterday")
                        .font(.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)

                    Spacer(minLength: 8)

                    Text(comparison >= 0 ? "+\(comparison)" : "\(comparison)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(comparison >= 0 ? MokoScreenTheme.Colors.scoreExcellent : MokoScreenTheme.Colors.error)

                    Text("points")
                        .font(.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                }
                .accessibilityElement(children: .combine)
            }

            // Color-coded stat bars
            ForEach(StatParameter.allCases, id: \.self) { stat in
                StatBarRow(
                    stat: stat,
                    value: scores[stat] ?? 0,
                    fill: fills[stat] ?? 0
                )
            }

            // XP and streak sit together so the card still explains the reward.
            if xp > 0 || streak > 0 {
                HStack(spacing: 8) {
                    if xp > 0 {
                        Text("+\(xp) XP")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(MokoScreenTheme.Colors.surfaceLavender, in: Capsule())
                    }

                    if streak > 0 {
                        Text("\(streak)-day streak")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(MokoScreenTheme.Colors.surfaceLavender, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // One button finishes the debrief from inside the same card.
            if let onContinue {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(MokoScreenTheme.Colors.dataVioletDeep, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(24)
        .background(MokoScreenTheme.Colors.surfaceWhite, in: RoundedRectangle(cornerRadius: 22))
        .sensoryFeedback(.increase, trigger: tick)
        .task {
            if !reduceMotion {
                await reveal()
            } else {
                // In reduce motion mode, skip to final state instantly
                for stat in StatParameter.allCases {
                    fills[stat] = Double(scores[stat] ?? 0) / 100
                }
                let target = scores.values.reduce(0, +) / max(scores.count, 1)
                average = target
            }
        }
    }

    private func reveal() async {
        // Staggered fill animation for each stat bar (250ms delay)
        for stat in StatParameter.allCases {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                fills[stat] = Double(scores[stat] ?? 0) / 100
            }
            tick += 1
        }

        // Count up the average in 20 steps
        let target = scores.values.reduce(0, +) / max(scores.count, 1)
        for step in 1...20 {
            try? await Task.sleep(for: .milliseconds(30))
            average = target * step / 20
        }
    }
}

/// Individual colored stat bar row with title, capsule fill, and numeric value.
struct StatBarRow: View {
    let stat: StatParameter
    let value: Int
    let fill: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(stat.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                .frame(width: 84, alignment: .leading)

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    // Track (light background)
                    Capsule()
                        .fill(stat.trackColor)

                    // Fill (vibrant color)
                    Capsule()
                        .fill(stat.color)
                        .frame(width: g.size.width * fill)
                }
            }
            .frame(height: 12)

            Text(fill > 0 ? "\(value)" : "0")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .contentTransition(.numericText())
                .animation(MokoMotion.snappy, value: fill)
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(stat.color)
        }
    }
}

#Preview {
    ScoreReveal(scores: [
        .courage: 78,
        .clarity: 85,
        .presence: 72,
        .warmth: 88
    ])
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .background(MokoScreenTheme.Colors.canvasTop)
}
