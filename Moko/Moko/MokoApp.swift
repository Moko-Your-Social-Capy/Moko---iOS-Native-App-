//
//  MokoApp.swift
//  Moko
//
//  Created by user@42 on 22/10/26.
//

import SwiftUI
import SwiftData

@main
struct MokoApp: App {
    

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for:[OnboardingState.self, OnboardingQuestion.self, OnboardingResponse.self, Profile.self])
    }
}
