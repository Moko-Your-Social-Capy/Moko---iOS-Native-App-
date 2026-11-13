import SwiftUI

struct ImageryGuideListView: View {
    var onSelect: (ImageryGuide) -> Void = { _ in }

    @Environment(ImageryGuideStore.self) private var store
    @State private var selectedTag: String? = nil      // nil = "All"
    @ScaledMetric(relativeTo: .title2) private var cardHeight: CGFloat = 240

    private let sage      = MocoScreenTheme.Colors.dataVioletDeep
    private let deepGreen = MocoScreenTheme.Colors.dataVioletDeep
    private let ink       = MocoScreenTheme.Colors.textTitle
    private let bodyText  = MocoScreenTheme.Colors.textBody
    private let muted     = MocoScreenTheme.Colors.textBody
    private let mint      = MocoScreenTheme.Colors.surfaceLavender

    private var screen: ImageryGuideScreenContent? { store.screen }

    private var visibleGuides: [ImageryGuide] {
        guard let selectedTag else { return store.guides }
        return store.guides.filter { $0.tag == selectedTag }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.top, 18)

            chips
                .padding(.top, 8)

            guideContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { MocoBackdrop() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let screen {
                    Text(screen.format(screen.guidesCountFormat, ["count": "\(store.guides.count)"]))
                        .mocoText(MocoScreenTheme.Typeface.caption)
                        .tracking(0.7)
                        .foregroundStyle(sage)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(mint))
                }
            }
        }
        .task { await store.loadIfNeeded() }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: selectedTag)
        .sensoryFeedback(.selection, trigger: selectedTag)
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        if let screen {
            VStack(alignment: .leading, spacing: 7) {
                Text(screen.eyebrow)
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .tracking(1.6)
                    .foregroundStyle(sage)

                Text(screen.title)
                    .mocoText(MocoScreenTheme.Typeface.title1)
                    .tracking(-0.7)
                    .foregroundStyle(ink)
            }
        }
    }

    // MARK: Filter chips

    @ViewBuilder
    private var chips: some View {
        if let screen {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    chip(title: screen.allFilterTitle,
                         symbol: screen.allFilterIcon,
                         isSelected: selectedTag == nil) {
                        selectedTag = nil
                    }

                    ForEach(store.tags) { tag in
                        chip(title: tag.title, symbol: tag.icon, isSelected: selectedTag == tag.title) {
                            selectedTag = tag.title
                        }
                    }
                }
                .padding(.horizontal, MocoScreenTheme.Space.page)
            }
            .scrollClipDisabled()
        }
    }

    private func chip(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))

                Text(title)
                    .mocoText(MocoScreenTheme.Typeface.caption)
            }
            .foregroundStyle(MocoScreenTheme.Colors.textTitle)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [MocoScreenTheme.Colors.surfaceLavender, MocoScreenTheme.Colors.surfaceLavender] : [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(Capsule().stroke(isSelected ? sage.opacity(0.22) : Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.03), radius: 7, x: 0, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(ImageryGuidePressStyle())
    }

    // MARK: Content

    @ViewBuilder
    private var guideContent: some View {
        if store.isLoading && store.guides.isEmpty {
            ProgressView(screen?.loadingText ?? "")
                .tint(sage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
        } else if store.guides.isEmpty, let error = store.errorMessage {
            ContentUnavailableView {
                Label(screen?.errorTitle ?? "Couldn't load guides", systemImage: screen?.errorIcon ?? "wifi.exclamationmark")
            } description: {
                Text(screen?.errorMessage ?? error)
            } actions: {
                Button(screen?.retryButtonTitle ?? "Try Again") {
                    Task { await store.load() }
                }
                .buttonStyle(.borderedProminent)
                .tint(sage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        } else if store.guides.isEmpty {
            ContentUnavailableView {
                Label(screen?.emptyTitle ?? "No guides yet", systemImage: screen?.emptyIcon ?? "sparkles")
            } description: {
                Text(screen?.emptyMessage ?? "")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(visibleGuides) { guide in
                        Button {
                            onSelect(guide)
                        } label: {
                            card(for: guide)
                        }
                        .buttonStyle(ImageryGuidePressStyle())
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                                .opacity(phase.isIdentity ? 1 : 0.85)
                        }
                        .accessibilityLabel(accessibilityLabel(for: guide))
                        .accessibilityHint(screen?.listAccessibilityHint ?? "")
                    }
                }
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .padding(.top, 12)
            .refreshable { await store.load() }
        }
    }

    private func accessibilityLabel(for guide: ImageryGuide) -> String {
        guard let screen else {
            return "\(guide.title), \(guide.tag), \(guide.durationLabel)"
        }
        return screen.format(screen.accessibilityLabelFormat, [
            "title": guide.title,
            "tag": guide.tag,
            "duration": guide.durationLabel
        ])
    }

    // MARK: Guide card

    private func card(for guide: ImageryGuide) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background {
                cardImage(for: guide)
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.12), location: 0),
                        .init(color: Color.clear, location: 0.28),
                        .init(color: deepGreen.opacity(0.18), location: 0.58),
                        .init(color: MocoScreenTheme.Colors.dataNode.opacity(0.95), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottom) {
                cardDetails(for: guide)
            }
            .overlay(alignment: .topLeading) {
                tagPill(for: guide)
                    .padding(14)
            }
            .overlay(alignment: .topTrailing) {
                durationPill(for: guide)
                    .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: MocoScreenTheme.Radius.card, style: .continuous))
            .mocoCard()
    }

    @ViewBuilder
    private func cardImage(for guide: ImageryGuide) -> some View {
        if let url = guide.artworkURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ZStack {
                        LinearGradient(
                            colors: [mint, sage.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        ProgressView()
                            .tint(sage)
                    }
                case .failure:
                    iconFallback(for: guide)
                @unknown default:
                    iconFallback(for: guide)
                }
            }
        } else {
            iconFallback(for: guide)
        }
    }

    private func iconFallback(for guide: ImageryGuide) -> some View {
        ZStack {
            LinearGradient(
                colors: [mint, sage.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: guide.icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(sage.opacity(0.6))
        }
    }

    private func cardDetails(for guide: ImageryGuide) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(guide.title)
                    .mocoText(MocoScreenTheme.Typeface.title2)
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(guide.description)
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineSpacing(2)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.16))

                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)

                Image(systemName: screen?.cardOpenIcon ?? "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)
        }
        .padding(18)
    }

    private func tagPill(for guide: ImageryGuide) -> some View {
        let symbol = store.tags.first(where: { $0.title == guide.tag })?.icon ?? guide.icon

        return HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))

            Text(guide.tag)
                .mocoText(MocoScreenTheme.Typeface.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(MocoScreenTheme.Colors.dataNode))
    }

    private func durationPill(for guide: ImageryGuide) -> some View {
        HStack(spacing: 4) {
            Image(systemName: screen?.durationIcon ?? "clock")
                .font(.system(size: 10, weight: .semibold))

            Text(guide.durationLabel)
                .mocoText(MocoScreenTheme.Typeface.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(MocoScreenTheme.Colors.dataNode))
    }

}

private struct ImageryGuidePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        ImageryGuideListView()
    }
    .environment(ImageryGuideStore())
}
