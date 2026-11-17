//
//  SessionCompleteView.swift
//  Moko
//
//  Brief completion overlay after an imagery session, then returns to Relax home.
//

import SwiftUI

struct SessionCompleteView: View {
    // The guide's own title/message context isn't required by overlay spec; show exercise title.
    var message: String = ""
    var exerciseTitle: String = "Guided Imagery"
    // Runs when the overlay auto-dismisses.
    var onDone: () -> Void = {}

    @Environment(ImageryGuideStore.self) private var store

    var body: some View {
        // Completion overlay appears briefly and automatically returns to Relax home.
        RelaxCompletionScreen(exerciseTitle: exerciseTitle, onContinue: onDone)
            .task { await store.loadIfNeeded() }
    }
}

#Preview {
    SessionCompleteView()
        .environment(ImageryGuideStore())
}
