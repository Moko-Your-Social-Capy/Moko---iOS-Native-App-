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
        styleSegmentedPickers()
        #if DEBUG
        OnboardingReflectionServiceTests.runAllTests()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
//            MokoLottieDemoView()
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

    /// Colours every segmented `Picker` in the app (lime pill, brown text).
    /// UIKit is used because SwiftUI has no way to change these colours yet.
    private func styleSegmentedPickers() {
        let segments = UISegmentedControl.appearance()
        let lime = UIColor(red: 226 / 255, green: 245 / 255, blue: 177 / 255, alpha: 1)
        let brown = UIColor(red: 92 / 255, green: 67 / 255, blue: 48 / 255, alpha: 1)

        segments.selectedSegmentTintColor = lime
        segments.setTitleTextAttributes([.foregroundColor: brown], for: .selected)
        segments.setTitleTextAttributes([.foregroundColor: brown], for: .normal)
    }
}
