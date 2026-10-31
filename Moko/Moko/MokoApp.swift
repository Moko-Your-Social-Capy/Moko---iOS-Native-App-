//
//  MokoApp.swift
//  Moko
//
//  Premium Apple-native social wellness and self-improvement application.

import SwiftUI
import SwiftData

@main
struct MokoApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            OnboardingState.self,
            OnboardingQuestion.self,
            OnboardingResponse.self,
            Profile.self,
            CalmDownModel.self,
            Quest.self,
            InsightsModel.self
        ])
    }
}
