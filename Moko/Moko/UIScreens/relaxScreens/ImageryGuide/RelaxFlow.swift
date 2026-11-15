//
//  RelaxFlow.swift
//  Moko
//
//  The Imagery Guide flow: guide list → session (timer + photo + music) → done screen.
//  A NavigationStack with a `path` array controls which screen is on top.
//

import SwiftUI

/// The screens that can be pushed on top of the guide list.
/// Each case carries the guide the user picked.
enum RelaxStep: Hashable {
    case session(ImageryGuide)
    case complete(ImageryGuide)
}

struct RelaxFlow: View {
    // Which bottom tab is selected. Passed in from the tab bar.
    @Binding var selectedTab: MokoTab
    // The stack of pushed screens. Appending pushes, `removeAll()` goes back to the list.
    @State private var path: [RelaxStep] = []
    // Loads guides from Supabase. Created once and shared with every screen below.
    @State private var imageryStore = ImageryGuideStore()

    init(selectedTab: Binding<MokoTab> = .constant(.relax)) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack(path: $path) {
            guideList
                // Tells the stack which screen to build for each `RelaxStep`.
                .navigationDestination(for: RelaxStep.self) { step in
                    switch step {
                    case .session(let guide):
                        GuideSessionView(guide: guide) {
                            path.append(.complete(guide))
                        }
                        .nativeBackBarOnly()

                    case .complete(let guide):
                        SessionCompleteView(
                            message: guide.completionMessage,
                            onDone: { path.removeAll() }
                        )
                        .navigationTitle(imageryStore.screen?.sessionCompleteNavigationTitle ?? "")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
        }
        // Puts the store in the environment so child screens can read it with
        // `@Environment(ImageryGuideStore.self)`.
        .environment(imageryStore)
    }

    private var guideList: some View {
        ImageryGuideListView { guide in
            path.append(.session(guide))
        }
    }
}

private extension View {
    /// A see-through navigation bar that only shows the back button.
    func nativeBackBarOnly() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
