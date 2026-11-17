//
//  ImageryGuideListView.swift
//  Moko
//
//  Relax → Imagery: filter chips on top and a list of big photo cards.
//  Tapping a card calls `onSelect`, and RelaxFlow pushes the session screen.
//

import SwiftUI

struct ImageryGuideListView: View {
    // What to do when a card is tapped. RelaxFlow passes this in.
    var onSelect: (ImageryGuide) -> Void = { _ in }

    // The shared store that RelaxFlow put in the environment.
    @Environment(ImageryGuideStore.self) private var store
    // The chip the user picked. `nil` means "All".
    @State private var selectedTag: String? = nil
    // @ScaledMetric makes the card taller when the user picks a bigger text size.
    @ScaledMetric(relativeTo: .title2) private var cardHeight: CGFloat = 240

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let ink = MokoScreenTheme.Colors.textTitle
    private let lavender = MokoScreenTheme.Colors.surfaceLavender

    private var screen: ImageryGuideScreenContent? { store.screen }

    /// The guides that match the selected chip.
    private var visibleGuides: [ImageryGuide] {
        guard let selectedTag else { return store.guides }
        return store.guides.filter { $0.tag == selectedTag }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 18)

            chips
                .padding(.top, 8)

            guideContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { MokoBackdrop() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let screen {
                    Text(screen.format(screen.guidesCountFormat, ["count": "\(store.guides.count)"]))
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .tracking(0.7)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(lavender))
                }
            }
        }
        // `.task` runs when the screen appears: download the guides the first time.
        .task { await store.loadIfNeeded() }
        // Animate the list whenever the selected chip changes.
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: selectedTag)
        // A light tap on the phone (haptic) when a chip is picked.
        .sensoryFeedback(.selection, trigger: selectedTag)
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        if let screen {
            VStack(alignment: .leading, spacing: 7) {
                Text(screen.eyebrow)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .tracking(1.6)
                    .foregroundStyle(accent)

                Text(screen.title)
                    .mokoText(MokoScreenTheme.Typeface.title1)
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
                .padding(.horizontal, MokoScreenTheme.Space.page)
            }
            .scrollClipDisabled()
        }
    }

    /// One filter chip. The picked chip is lavender, the others white.
    private func chip(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))

                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.caption)
            }
            .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Capsule().fill(isSelected ? lavender : Color.white))
            .overlay(Capsule().stroke(isSelected ? accent.opacity(0.22) : Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.03), radius: 7, x: 0, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(ImageryGuidePressStyle())
    }

    // MARK: Content

    /// Four states: loading, error, no guides, or the list of cards.
    @ViewBuilder
    private var guideContent: some View {
        if store.isLoading && store.guides.isEmpty {
            VStack(spacing: 12) {
                MokoInlineLoader(size: 48, tint: accent)
                if let text = screen?.loadingText, !text.isEmpty {
                    Text(text)
                        .mokoText(MokoScreenTheme.Typeface.caption)
                        .foregroundStyle(MokoScreenTheme.Colors.textBody)
                }
            }
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
                .tint(accent)
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
                        // Cards shrink and fade a little as they scroll off the edge.
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                                .opacity(phase.isIdentity ? 1 : 0.85)
                        }
                        .accessibilityLabel(accessibilityLabel(for: guide))
                        .accessibilityHint(screen?.listAccessibilityHint ?? "")
                    }
                }
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .padding(.top, 12)
            // Pull down on the list to download the guides again.
            .refreshable { await store.load() }
        }
    }

    /// What VoiceOver reads for a card, e.g. "A Cozy Room, Cozy, 2 min".
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

    /// One big card: photo, dark fade at the bottom, title, and two pills on top.
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
                        .init(color: accent.opacity(0.18), location: 0.58),
                        .init(color: MokoScreenTheme.Colors.dataNode.opacity(0.95), location: 1)
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
            .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card, style: .continuous))
            .mokoCard()
    }

    /// The card photo. AsyncImage downloads it and gives us a `phase`:
    /// `.empty` = still loading, `.success` = got it, `.failure` = could not load.
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
                            colors: [lavender, accent.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        MokoInlineLoader(size: 24, tint: accent)
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

    /// Shown when a guide has no photo: a soft gradient with its SF Symbol.
    private func iconFallback(for guide: ImageryGuide) -> some View {
        ZStack {
            LinearGradient(
                colors: [lavender, accent.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: guide.icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(accent.opacity(0.6))
        }
    }

    private func cardDetails(for guide: ImageryGuide) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(guide.title)
                    .mokoText(MokoScreenTheme.Typeface.title2)
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(guide.description)
                    .mokoText(MokoScreenTheme.Typeface.caption)
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
        // Use the chip's icon for this tag, or the guide's own icon if the tag is unknown.
        let symbol = store.tags.first(where: { $0.title == guide.tag })?.icon ?? guide.icon

        return HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))

            Text(guide.tag)
                .mokoText(MokoScreenTheme.Typeface.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(MokoScreenTheme.Colors.dataNode))
    }

    private func durationPill(for guide: ImageryGuide) -> some View {
        HStack(spacing: 4) {
            Image(systemName: screen?.durationIcon ?? "clock")
                .font(.system(size: 10, weight: .semibold))

            Text(guide.durationLabel)
                .mokoText(MokoScreenTheme.Typeface.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(MokoScreenTheme.Colors.dataNode))
    }
}

/// Makes a button shrink slightly while a finger is on it.
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
