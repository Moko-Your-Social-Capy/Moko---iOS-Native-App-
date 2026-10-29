//
//  CalmDownModel.swift
//  Moko
//
//  Created by user@42 on 28/10/26.
//

import Foundation
import SwiftData

/// One finished calm down exercise (Box Breathing, Gentle Breathing, Grounding, ...).
@Model
final class CalmDownModel: Identifiable {
    var exerciseId = UUID()
    var exerciseTitle: String
    /// Time spent in seconds (stopwatch from start to finish)
    var exerciseTime: TimeInterval
    var date: Date

    init(exerciseTitle: String, exerciseTime: TimeInterval, date: Date) {
        self.exerciseTitle = exerciseTitle
        self.exerciseTime = exerciseTime
        self.date = date
    }
}

extension ModelContext {
    /// Call this once when a calm down exercise finishes. The Summary screen reads these.
    func logCalmDown(_ title: String, seconds: TimeInterval) {
        insert(CalmDownModel(exerciseTitle: title, exerciseTime: max(0, seconds), date: Date()))
        do {
            try save()
        } catch {
            print("Calm down save failed:", error)
        }
    }
}
