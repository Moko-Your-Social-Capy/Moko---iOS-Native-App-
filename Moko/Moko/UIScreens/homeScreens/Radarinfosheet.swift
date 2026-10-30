//
//  RadarInfoSheet.swift
//  Moko
//
//  "How your radar chart works" modal shown when the Insights card is tapped.
//

import SwiftUI

struct RadarInfoSheet: View {
    /// Called when "View my insights" is tapped (the sheet then closes itself).
    var onViewInsights: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private let green     = Color(red: 27/255, green: 66/255, blue: 47/255)    // #1B422F
    private let mint      = Color(red: 203/255, green: 230/255, blue: 211/255)
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255)    // #2F2A28
    private let gray      = Color(red: 111/255, green: 103/255, blue: 98/255)  // #6F6762

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How your radar chart works")
                        .font(.title.bold())
                        .foregroundStyle(titleDark)

                    Text("Four scores, one shape. Here’s how to read it.")
                        .font(.subheadline)
                        .foregroundStyle(gray)
                }

                radar

                row(icon: "diamond",
                    title: "Four corners",
                    text: "Each corner is one parameter: Clarity, Courage, Warmth and Presence.")

                row(icon: "diamond.inset.filled",
                    title: "Your shape",
                    text: "The further a point sits from the center, the higher that score. Rings mark 25, 50, 75 and 100.")

                row(icon: "text.alignleft",
                    title: "Scroll for the why",
                    text: "Under the chart, each parameter explains what shaped its score.")

                Button {
                    onViewInsights()
                    dismiss()
                } label: {
                    Text("View my insights")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 25)
                }
                .buttonStyle(.borderedProminent)
                .tint(green)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Illustration

    private var radar: some View {
        VStack(spacing: 8) {
            Text("Courage")

            HStack {
                Text("Clarity")

                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let radius = min(geo.size.width, geo.size.height) / 2 * 0.7
                    let points = [
                        CGPoint(x: center.x, y: center.y - radius),
                        CGPoint(x: center.x + radius, y: center.y),
                        CGPoint(x: center.x, y: center.y + radius),
                        CGPoint(x: center.x - radius, y: center.y)
                    ]

                    ZStack {
                        DiamondShape()
                            .stroke(green.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        DiamondShape()
                            .stroke(green.opacity(0.25), lineWidth: 1)
                            .scaleEffect(0.5)

                        Path { path in
                            path.addLines(points)
                            path.closeSubpath()
                        }
                        .fill(green.opacity(0.25))

                        Path { path in
                            path.addLines(points)
                            path.closeSubpath()
                        }
                        .stroke(green, lineWidth: 2)

                        ForEach(points.indices, id: \.self) { index in
                            Circle()
                                .fill(green)
                                .frame(width: 8, height: 8)
                                .position(points[index])
                        }
                    }
                }
                .frame(width: 170, height: 170)

                Text("Presence")
            }

            Text("Warmth")
        }
        .font(.footnote)
        .foregroundStyle(gray)
        .frame(maxWidth: .infinity)
    }

    // MARK: Row

    private func row(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(green)
                .frame(width: 64, height: 64)
                .background(mint.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(titleDark)
                Text(text)
                    .font(.subheadline)
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
