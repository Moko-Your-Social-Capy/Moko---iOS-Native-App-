//
//  Onboarding_state.swift
//  Moko
//
//  Remembers how far the user got through onboarding, so the app can skip it
//  next time (or resume at the right question).
//
//  Careful: this is a SwiftData model. Renaming or removing a property changes
//  the saved database and needs a migration.
//

import Foundation
import SwiftData

/// `@Model` tells SwiftData to save this class to the phone's database.
@Model
final class OnboardingState: Identifiable {

    var id: UUID
    /// Index of the onboarding question the user is on (0 = the first one).
    var currentStep: Int
    /// True once the user has finished onboarding.
    var isCompleted: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        currentStep: Int = 0,
        isCompleted: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.currentStep = currentStep
        self.isCompleted = isCompleted
        self.updatedAt = updatedAt
    }
}
