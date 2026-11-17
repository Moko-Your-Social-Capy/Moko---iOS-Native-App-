//
//  MokoActivityAttributes.swift
//  Moko
//
//  The data a Moko Live Activity shows on the Lock Screen and in the
//  Dynamic Island. This file is also compiled into the widget extension so
//  both sides agree on the shape of the activity.
//

import Foundation
import ActivityKit

struct MokoActivityAttributes: ActivityAttributes {
    // The part of the activity that can change while it is running.
    struct ContentState: Codable, Hashable {
        // A short line of text shown under the title.
        var message: String
        // When the activity first started. The timer in the widget counts from here.
        var startedAt: Date
        // The last time the app sent an update.
        var updatedAt: Date
    }

    // The part of the activity that never changes.
    var title: String
}
