import SwiftUI

extension View {
    /// Parts two mint panels once when a milestone appears; controls stay usable.
    func mokoCompletionReveal(isPresented: Bool = true) -> some View {
        overlay {
            if isPresented {
                MokoCompletionReveal()
            }
        }
    }
}

struct MokoCompletionReveal: View {
    // The phone's accessibility choice replaces the sliding panels with a fade.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Remembers that the curtain has opened so redraws do not replay it.
    @State private var isOpen = false

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                panel
                    .offset(x: isOpen && !reduceMotion ? -geometry.size.width / 2 : 0)
                panel
                    .offset(x: isOpen && !reduceMotion ? geometry.size.width / 2 : 0)
            }
            .opacity(isOpen && reduceMotion ? 0 : 1)
        }
        .ignoresSafeArea()
        .clipped()
        // This is decoration, never a barrier between the user and Done.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // Wait for the first frame, then open; leaving cancels this work.
        .task {
            guard !isOpen else { return }
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? MokoScreenTheme.Motion.crossfade : MokoScreenTheme.Motion.completionReveal) {
                isOpen = true
            }
        }
    }

    private var panel: some View {
        Rectangle()
            .fill(MokoScreenTheme.Colors.canvasTop)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
