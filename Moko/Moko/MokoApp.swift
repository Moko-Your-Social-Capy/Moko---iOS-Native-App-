//
//  MokoApp.swift
//  Moko
//
//  Premium Apple-native social wellness and self-improvement application.

import SwiftUI
import SwiftData
import UIKit

@main
struct MokoApp: App {

    init() {
        // Warm the local vector loader while the static splash is shown; the
        // floss animation is only presented by actual loading states.
        MokoFlossLoadingView.prewarm()

        let segments = UISegmentedControl.appearance()
        segments.selectedSegmentTintColor = UIColor(
            red: 226.0 / 255.0,
            green: 245.0 / 255.0,
            blue: 177.0 / 255.0,
            alpha: 1
        )
        let brown = UIColor(red: 92.0 / 255.0, green: 67.0 / 255.0, blue: 48.0 / 255.0, alpha: 1)
        segments.setTitleTextAttributes([.foregroundColor: brown], for: .selected)
        segments.setTitleTextAttributes([.foregroundColor: brown], for: .normal)
    }

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
            InsightsModel.self,
            DebriefSession.self,
            DebriefTurn.self,
            SkillScore.self,
            ScoreReport.self,
            MissionResult.self
        ])
    }
}
