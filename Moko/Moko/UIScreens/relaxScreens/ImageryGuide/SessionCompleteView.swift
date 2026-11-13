//
//  SessionCompleteView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

struct SessionCompleteView: View {
    var message: String = ""
    var onDone: () -> Void = {}

    @Environment(ImageryGuideStore.self) private var store

    private let accent = MocoScreenTheme.Colors.dataVioletDeep
    private let titleBrown = MocoScreenTheme.Colors.textTitle

    var body: some View {
        Group {
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
        .background(MocoBackdrop())
        // Stays immersive until Done returns to the guide list.
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadIfNeeded() }
    }

    private func content(_ screen: ImageryGuideScreenContent) -> some View {
        VStack(spacing: 0) {
            Text(screen.completeTitle)
                .mocoText(MocoScreenTheme.Typeface.title2)
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 10)

            Text(screen.completeSubtitle)
                .mocoText(MocoScreenTheme.Typeface.caption)
                .foregroundStyle(MocoScreenTheme.Colors.textMuted)
                .padding(.top, 4)

            MokoCompletionAnimation(ringDiameter: 190)
                .padding(.top, 18)

            Text(screen.completeHeadline)
                .mocoText(MocoScreenTheme.Typeface.title1)
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 54)

            Text(resolvedMessage(screen))
                .mocoText(MocoScreenTheme.Typeface.body)
                .foregroundStyle(MocoScreenTheme.Colors.textBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.top, 24)

            Spacer(minLength: 24)

            Button(action: onDone) {
                Text(screen.completeDoneButton)
                    .mocoText(MocoScreenTheme.Typeface.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: MocoScreenTheme.Control.trackHeight)
                    .background(accent, in: Capsule())
            }
            .padding(.horizontal, MocoScreenTheme.Space.page)
            .padding(.bottom, 12)
        }
        .multilineTextAlignment(.center)
    }

    private func resolvedMessage(_ screen: ImageryGuideScreenContent) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? screen.completeDefaultMessage : trimmed
    }
}

#Preview {
    SessionCompleteView()
        .environment(ImageryGuideStore())
}
