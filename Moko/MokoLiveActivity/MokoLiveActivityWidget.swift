//
//  MokoLiveActivityWidget.swift
//  MokoLiveActivity
//
//  Draws the Moko Live Activity on the Lock Screen and in the Dynamic
//  Island. iOS decides where and when it appears; the app only supplies the
//  content. The Dynamic Island is shown only on supported iPhone models.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct MokoLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        MokoLiveActivityWidget()
    }
}

struct MokoLiveActivityWidget: Widget {
    private let forest = Color(red: 37 / 255, green: 76 / 255, blue: 60 / 255)
    private let sage = Color(red: 203 / 255, green: 230 / 255, blue: 211 / 255)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MokoActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(forest)
                    Text(context.attributes.title)
                        .font(.headline)
                        .foregroundStyle(forest)
                    Spacer()
                    Text(context.state.startedAt, style: .timer)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(forest)
                }

                Text(context.state.message)
                    .font(.subheadline)
                    .foregroundStyle(forest.opacity(0.75))
                    .lineLimit(2)
            }
            .padding()
            .activityBackgroundTint(sage)
            .activitySystemActionForegroundColor(forest)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Moko", systemImage: "leaf.fill")
                        .font(.headline)
                        .foregroundStyle(sage)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startedAt, style: .timer)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(sage)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(sage)
            } compactTrailing: {
                Text(context.state.startedAt, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(sage)
            } minimal: {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(sage)
            }
            .keylineTint(sage)
        }
    }
}

#Preview("Lock Screen", as: .content, using: MokoActivityAttributes(title: "Moko session")) {
    MokoLiveActivityWidget()
} contentStates: {
    MokoActivityAttributes.ContentState(
        message: "Your Moko session is active.",
        startedAt: .now,
        updatedAt: .now
    )
}
