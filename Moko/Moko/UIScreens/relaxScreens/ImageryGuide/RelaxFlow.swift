import SwiftUI

enum RelaxStep: Hashable {
    case session(ImageryGuide)
    case complete(ImageryGuide)
}

struct RelaxFlow: View {
    @Binding var selectedTab: MokoTab
    @State private var path: [RelaxStep] = []
    @State private var imageryStore = ImageryGuideStore()

    init(selectedTab: Binding<MokoTab> = .constant(.relax)) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack(path: $path) {
            guideList
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
        .environment(imageryStore)
    }

    private var guideList: some View {
        ImageryGuideListView { guide in
            path.append(.session(guide))
        }
    }
}

private extension View {
    func nativeBackBarOnly() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
