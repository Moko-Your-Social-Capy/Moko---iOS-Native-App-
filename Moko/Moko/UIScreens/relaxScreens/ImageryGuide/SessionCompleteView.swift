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

    private let accent = Color(hex: 0x365948)
    private let titleBrown = Color(hex: 0x5C4330)

    var body: some View {
        Group {
            if let screen = store.screen {
                content(screen)
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
        .background(Color(hex: 0xF6FAE8).ignoresSafeArea())
        // Stays immersive until Done returns to the guide list.
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadIfNeeded() }
    }

    private func content(_ screen: ImageryGuideScreenContent) -> some View {
        VStack(spacing: 0) {
            Text(screen.completeTitle)
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 10)

            Text(screen.completeSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x8A7B68))
                .padding(.top, 4)

            MokoCompletionAnimation(ringDiameter: 190)
                .padding(.top, 18)

            Text(screen.completeHeadline)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 54)

            Text(resolvedMessage(screen))
                .font(.system(size: 18, weight: .light))
                .lineSpacing(12)
                .foregroundStyle(MokoTheme.titleBrown)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 52)
                .padding(.top, 24)

            Spacer(minLength: 24)

            Button(action: onDone) {
                Text(screen.completeDoneButton)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 244, height: 61)
                    .background(accent, in: Capsule())
            }
            .padding(.bottom, 12)
        }
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
