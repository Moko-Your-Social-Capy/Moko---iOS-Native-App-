import Foundation
import SwiftData

@Model
final class OnboardingState : Identifiable{
    
    var id: UUID
    var currentStep: Int
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
