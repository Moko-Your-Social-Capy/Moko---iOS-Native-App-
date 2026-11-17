//
//  MokoActivityAttributes.swift
//  MokoLiveActivity
//
//  A copy of the attributes type that lives in the app. The widget extension
//  is a separate module, so it needs the same shape to decode the activity.
//

import Foundation
import ActivityKit

struct MokoActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var message: String
        var startedAt: Date
        var updatedAt: Date
    }

    var title: String
}
