//
//  Onboarding_Response.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//

import Foundation
import SwiftData

@Model
final class OnboardingResponse {
    @Attribute(.unique)
    var id: UUID

    var userID: String
    var questionID: String
    var userResponse : String

    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userID: String,
        questionID: String,
        userResponse: String = "",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.questionID = questionID
        self.userResponse = userResponse
        self.updatedAt = updatedAt
    }
}
