import SwiftUI

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        let bg = isDark ? AppColors.Dark.background : AppColors.Light.background
        let surface = isDark ? AppColors.Dark.surface : AppColors.Light.surface
        let textColor = isDark ? AppColors.Dark.primaryText : AppColors.Light.primaryText
        let secondaryColor = isDark ? AppColors.Dark.secondaryText : AppColors.Light.secondaryText

        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Navigation Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textColor)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(surface))
                            .shadow(color: AppColors.Light.cardShadow, radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    Text("Insights & Analytics")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)

                    Spacer()

                    // Balance spacing
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // MARK: - Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - First Viewport: Prominent Radar Chart
                        VStack(alignment: .center, spacing: 16) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("78")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(textColor)

                                Text("warmth score")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(secondaryColor)
                            }
                            .padding(.top, 8)

                            // Large Prominent Radar Chart
                            InsightsRadarChartView()
                                .frame(width: 220, height: 220)
                                .padding(.vertical, 8)

                            Text("Your social balance across four key interaction dimensions based on recent daily reflections and debriefs.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(secondaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(surface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: AppColors.Light.cardShadow, radius: 10, x: 0, y: 3)
                        .padding(.horizontal, 16)

                        // MARK: - Parameter Details Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Parameter Breakdown")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(textColor)
                                .padding(.horizontal, 16)

                            VStack(spacing: 12) {
                                parameterCard(
                                    title: "Warmth",
                                    score: "78",
                                    description: "Genuine connection and conversational warmth during social exchanges.",
                                    trend: "+4pts this week",
                                    surface: surface,
                                    textColor: textColor,
                                    secondaryColor: secondaryColor
                                )

                                parameterCard(
                                    title: "Presence",
                                    score: "66",
                                    description: "Staying anchored, attentive, and engaged in group conversations.",
                                    trend: "Steady",
                                    surface: surface,
                                    textColor: textColor,
                                    secondaryColor: secondaryColor
                                )

                                parameterCard(
                                    title: "Clarity",
                                    score: "75",
                                    description: "Clear and direct expression of thoughts without overthinking.",
                                    trend: "+6pts this week",
                                    surface: surface,
                                    textColor: textColor,
                                    secondaryColor: secondaryColor
                                )

                                parameterCard(
                                    title: "Calm",
                                    score: "70",
                                    description: "Maintaining inner poise and steady breathing during social pauses.",
                                    trend: "+2pts this week",
                                    surface: surface,
                                    textColor: textColor,
                                    secondaryColor: secondaryColor
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 12)
                }
            }
        }
    }

    private func parameterCard(
        title: String,
        score: String,
        description: String,
        trend: String,
        surface: Color,
        textColor: Color,
        secondaryColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)

                    Spacer()

                    Text(trend)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(secondaryColor.opacity(0.12)))
                }

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(secondaryColor)
                    .lineSpacing(2)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(score)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                Text("score")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppColors.Light.cardShadow, radius: 8, x: 0, y: 2)
    }
}
