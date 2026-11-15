//
//  InsightsModel.swift
//  Moko
//
//  One saved debrief result: the four parameter scores (0...100) and when it happened.
//  Saved when a quest debrief finishes; read by the Insights and Overview screens.
//

import Foundation
import SwiftData

// `@Model` turns this class into a SwiftData table, so it is saved on the device.
@Model
final class InsightsModel {
    var courage: Int
    var clarity: Int
    var presence: Int
    var warmth: Int
    var date: Date

    init(courage: Int, clarity: Int, presence: Int, warmth: Int, date: Date) {
        self.courage = courage
        self.clarity = clarity
        self.presence = presence
        self.warmth = warmth
        self.date = date
    }
}
