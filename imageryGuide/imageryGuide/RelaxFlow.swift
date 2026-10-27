//
//  RelaxFlow.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

enum RelaxStep: Hashable {
    case guideList
    case guideDetail(ImageryGuide)
    case session(ImageryGuide)       // the 2-minute timer
    case complete(ImageryGuide)      // "You did it!"
}

struct RelaxFlow: View {
    @State private var path: [RelaxStep] = []
    @State private var showIntro = false              // Imagery Guide intro sheet
    @State private var continueAfterDismiss = false

    var body: some View {
        NavigationStack(path: $path) {
            // Relax home: the list of relaxation types
            RelaxHomeView(
                onSelectImageryGuide: { showIntro = true }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RelaxStep.self) { step in
                switch step {
                case .guideList:
                    // Uses iOS's own glass back button
                    ImageryGuideListView(
                        onSelect: { guide in path.append(.guideDetail(guide)) }
                    )
                    .nativeBackBarOnly()

                case .guideDetail(let guide):
                    ImageryGuideDetailView(
                        guide: guide,
                        onStart: { path.append(.session(guide)) }
                    )
                    .nativeBackBarOnly()

                case .session(let guide):
                    GuideSessionView(
                        guide: guide,
                        onContinue: { path.append(.complete(guide)) }
                    )
                    .nativeBackBarOnly()

                case .complete(let guide):
                    SessionCompleteView(
                        message: guide.completionMessage,
                        onDone: { path.removeAll() }         // back to Relax home
                    )
                    .navigationBarBackButtonHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
                    .toolbar(.hidden, for: .tabBar)
                }
            }
        }
        // Imagery Guide intro: modal sheet over the Relax home
        .sheet(isPresented: $showIntro, onDismiss: {
            if continueAfterDismiss {
                continueAfterDismiss = false
                path.append(.guideList)
            }
        }) {
            ImageryGuideView(
                onContinue: {
                    continueAfterDismiss = true
                    showIntro = false
                },
                onNotNow: { showIntro = false }              // back to Relax home
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
}

private extension View {
    /// Shows only iOS's own back button (glass on iOS 26): no title, no bar
    /// background, and no tab bar underneath.
    func nativeBackBarOnly() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    RelaxFlow()
}
