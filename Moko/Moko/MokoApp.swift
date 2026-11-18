//
//  MokoApp.swift
//  Moko
//
//  Where the app starts. It opens ContentView and sets up the on-phone database.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct MokoApp: App {

    init() {
        // Preload SVG animations so loaders (moonwalk/tick) appear quickly.
        MokoAnimationAssets.preloadCommonSVGs()
        #if DEBUG
        OnboardingReflectionServiceTests.runAllTests()
        // Async debrief checks use a scripted coach, never the live model or user data.
        Task { @MainActor in
            await DebriefRegressionTests.runAllTests()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
//            MokoLottieDemoView()
                .mokoThemeRoot()
        }
        // SwiftData is Apple's storage. It saves these types on the phone
        // and shares them with every screen through the environment.
        .modelContainer(for: [
            OnboardingState.self,
            OnboardingQuestion.self,
            OnboardingResponse.self,
            Profile.self,
            CalmDownModel.self,
            Quest.self,
            ActivityRecord.self,
            InsightsModel.self
        ])
    }

}
