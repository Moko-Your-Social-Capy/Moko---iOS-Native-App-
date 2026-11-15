//
//  RadarInfoSheet.swift
//  Moko
//
//  "How your radar chart works" modal shown when the Insights card is tapped.
//  "Continue" closes it; the Overview then pushes the full Insights screen.
//

import SwiftUI

struct RadarInfoSheet: View {
    /// Called when "Continue" is tapped (the sheet then closes itself).
    var onViewInsights: () -> Void = {}

    // Closes this sheet.
    @Environment(\.dismiss) private var dismiss

    private let accent    = MokoScreenTheme.Colors.dataVioletDeep
    private let soft      = MokoScreenTheme.Colors.surfaceLavender
    private let titleDark = MokoScreenTheme.Colors.textTitle
    private let gray      = MokoScreenTheme.Colors.textBody

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How your radar chart works")
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(titleDark)

                    Text("Four scores, one shape. Here’s how to read it.")
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(gray)
                }

                radar

                row(icon: "diamond",
                    title: "Four Corners",
                    text: "Each corner is one parameter: Clarity, Courage, Warmth and Presence.")

                row(icon: "diamond.inset.filled",
                    title: "Score Pattern",
                    text: "The further a point sits from the center, the higher that score. The outer ring represents 100.")

                row(icon: "text.alignleft",
                    title: "Closer Look",
                    text: "Under the chart, each parameter explains what shaped its score.")

                Button {
                    onViewInsights()
                    dismiss()
                } label: {
                    Text("Continue")
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 25)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .background { MokoBackdrop() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Illustration

    /// A sample radar chart with fixed scores, labelled on all four sides.
    private var radar: some View {
        VStack(spacing: 8) {
            Text("Courage")

            HStack {
                Text("Clarity")

                MokoRadarChart(scores: InsightsScores(clarity: 65, courage: 85, presence: 72, warmth: 90))
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityHidden(true)

                Text("Presence")
            }

            Text("Warmth")
        }
        .mokoText(MokoScreenTheme.Typeface.caption)
        .foregroundStyle(gray)
        .frame(maxWidth: .infinity)
        .padding(MokoScreenTheme.Space.cardHorizontal)
        .mokoCard()
    }

    // MARK: Row

    /// Icon tile on the left, title and explanation on the right.
    private func row(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 44, height: 44)
                .background(soft, in: RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.inner, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(titleDark)
                Text(text)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(gray)
            }
        }
    }
}

#Preview {
    Text("Overview")
        .sheet(isPresented: .constant(true)) {
            RadarInfoSheet()
        }
}
