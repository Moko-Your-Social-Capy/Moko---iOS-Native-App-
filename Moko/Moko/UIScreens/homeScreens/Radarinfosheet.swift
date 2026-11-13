//
//  RadarInfoSheet.swift
//  Moko
//
//  "How your radar chart works" modal shown when the Insights card is tapped.
//

import SwiftUI

struct RadarInfoSheet: View {
    /// Called when "Continue" is tapped (the sheet then closes itself).
    var onViewInsights: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private let green     = MocoScreenTheme.Colors.dataVioletDeep    // #1B422F
    private let mint      = MocoScreenTheme.Colors.surfaceLavender
    private let titleDark = MocoScreenTheme.Colors.textTitle    // #5C4330
    private let gray      = MocoScreenTheme.Colors.textBody  // #6F6762

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How your radar chart works")
                        .mocoText(MocoScreenTheme.Typeface.title1)
                        .foregroundStyle(titleDark)

                    Text("Four scores, one shape. Here’s how to read it.")
                        .mocoText(MocoScreenTheme.Typeface.body)
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
                        .mocoText(MocoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 25)
                }
                .buttonStyle(.borderedProminent)
                .tint(green)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .padding(.horizontal, MocoScreenTheme.Space.page)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .background { MocoBackdrop() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Illustration

    private var radar: some View {
        VStack(spacing: 8) {
            Text("Courage")

            HStack {
                Text("Clarity")

                MocoRadarChart(scores: InsightsScores(clarity: 65, courage: 85, presence: 72, warmth: 90))
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityHidden(true)

                Text("Presence")
            }

            Text("Warmth")
        }
        .mocoText(MocoScreenTheme.Typeface.caption)
        .foregroundStyle(gray)
        .frame(maxWidth: .infinity)
        .padding(MocoScreenTheme.Space.cardHorizontal)
        .mocoCard()
    }

    // MARK: Row

    private func row(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(green)
                .frame(width: 44, height: 44)
                .background(mint, in: RoundedRectangle(cornerRadius: MocoScreenTheme.Radius.inner, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .mocoText(MocoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(titleDark)
                Text(text)
                    .mocoText(MocoScreenTheme.Typeface.body)
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
