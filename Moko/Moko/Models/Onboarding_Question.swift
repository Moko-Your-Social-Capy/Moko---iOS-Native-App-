//
//  Onboarding_Question.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//

import Foundation
import SwiftData

@Model
final class OnboardingQuestion  : Identifiable{
    
    var questionID = UUID()
    var questionText: String
    var options: [String]
    var isRequired: Bool

    init(
        questionID: UUID = UUID(),
        questionText: String,
        
        
        options: [String] = [],
        
        isRequired: Bool = true
    ) {
        self.questionID = questionID
        self.questionText = questionText
        
        
        self.options = options
       
        self.isRequired = isRequired
    }
}
