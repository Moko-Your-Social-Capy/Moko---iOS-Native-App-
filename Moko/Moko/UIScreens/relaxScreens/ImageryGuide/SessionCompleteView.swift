//
//  SessionCompleteView.swift
//  Moko
//
//  The "well done" screen after an imagery session. All the text comes from
//  Supabase through `ImageryGuideStore`, so it shows a spinner or an error
//  if that text has not loaded yet.
//

import SwiftUI

struct SessionCompleteView: View {
    // The guide's own goodbye message. Empty means "use the default text".
    var message: String = ""
    // Runs when the user taps Done (goes back to the guide list).
    var onDone: () -> Void = {}

    // The shared store that RelaxFlow put in the environment.
    @Environment(ImageryGuideStore.self) private var store

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let titleBrown = MokoScreenTheme.Colors.textTitle

    var body: some View {
        Group {
            // Three states: text loaded, still loading, or failed.
            if let screen = store.screen {
                ScrollView {
                    content(screen)
                }
            } else if store.isLoading {
                ProgressView()
                    .tint(accent)
            } else {
                ContentUnavailableView {
                    Label(store.screen?.errorTitle ?? "Couldn't load guides", systemImage: store.screen?.errorIcon ?? "wifi.exclamationmark")
                } description: {
                    Text(store.errorMessage ?? "")
                } actions: {
                    Button(store.screen?.retryButtonTitle ?? "Try Again") {
                        Task { await store.load() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MokoBackdrop())
        // Celebrate only when the goodbye text is ready, never over an error.
        .mokoCompletionReveal(isPresented: store.screen != nil)
        // Stays immersive until Done returns to the guide list.
        .toolbar(.hidden, for: .tabBar)
        // `.task` runs when the screen appears. Loads the text only if it is not loaded yet.
        .task { await store.loadIfNeeded() }
    }

    private func content(_ screen: ImageryGuideScreenContent) -> some View {
        VStack(spacing: 0) {
            Text(screen.completeTitle)
                .mokoText(MokoScreenTheme.Typeface.title2)
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 10)

            Text(screen.completeSubtitle)
                .mokoText(MokoScreenTheme.Typeface.caption)
                .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                .padding(.top, 4)

            MokoCompletionAnimation(ringDiameter: 190)
                .padding(.top, 18)

            Text(screen.completeHeadline)
                .mokoText(MokoScreenTheme.Typeface.title1)
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 54)

            Text(resolvedMessage(screen))
                .mokoText(MokoScreenTheme.Typeface.body)
                .foregroundStyle(MokoScreenTheme.Colors.textBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 24)

            Spacer(minLength: 24)

            Button(action: onDone) {
                Text(screen.completeDoneButton)
                    .mokoText(MokoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: MokoScreenTheme.Control.trackHeight)
                    .background(accent, in: Capsule())
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.bottom, 12)
        }
        .multilineTextAlignment(.center)
    }

    /// The guide's message, or the default one if the guide has none.
    private func resolvedMessage(_ screen: ImageryGuideScreenContent) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? screen.completeDefaultMessage : trimmed
    }
}

#Preview {
    SessionCompleteView()
        .environment(ImageryGuideStore())
}
