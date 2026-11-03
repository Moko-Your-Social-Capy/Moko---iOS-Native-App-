import SwiftUI

struct ImageryGuideDetailView: View {
    let guide: ImageryGuide

    @Environment(ImageryGuideStore.self) private var store

    private let accent = Color(hex: 0x365948)
    private let tileFill = Color(hex: 0xE2F5B1)
    private let ink = Color(hex: 0x5C4330)
    private let bodyText = Color(hex: 0x51443E)
    private let caption = Color(hex: 0x6F6762)

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
        .navigationBarTitleDisplayMode(.inline)
        // Keep the tab bar hidden on the info screen too, so returning from a
        // session doesn't animate it back in after a delay.
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadIfNeeded() }
    }

    private func content(_ screen: ImageryGuideScreenContent) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .frame(width: 160, height: 160)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tileFill)
                        .frame(width: 136, height: 136)
                        .overlay {
                            Image(systemName: guide.icon)
                                .font(.system(size: 52, weight: .semibold))
                                .foregroundStyle(accent)
                        }
                }
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)

            Text(guide.title)
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(ink)
                .padding(.top, 24)

            Text(guide.detailDescription)
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)
                .padding(.top, 18)

            NavigationLink(value: RelaxRoute.guideSession(guide)) {
                Text(screen.detailStartButton)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 244, height: 61)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 44)

            Text(screen.detailCaption)
                .font(.system(size: 15))
                .tracking(0.3)
                .foregroundStyle(caption)
                .padding(.top, 18)

            Spacer(minLength: 24)
        }
    }
}

#Preview {
    NavigationStack {
        ImageryGuideDetailView(guide: .preview)
    }
    .environment(ImageryGuideStore())
}
