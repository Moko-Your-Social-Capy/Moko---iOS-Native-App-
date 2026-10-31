import SwiftUI

struct ImageryGuideListView: View {
    var onSelect: (ImageryGuide) -> Void = { _ in }

    @State private var selectedTag: String? = nil      // nil = "All"

    private let sage      = Color(hex: 0x365948)
    private let deepGreen = Color(hex: 0x1B422F)
    private let ink       = Color(hex: 0x5C4330)
    private let bodyText  = Color(hex: 0x51443E)
    private let muted     = Color(hex: 0x6F6762)
    private let mint      = Color(hex: 0xE2F5B1)
    private let screenBg  = Color(hex: 0xF6FAE8)
    private let tags      = ["Cozy", "Peace", "Fresh", "Own"]

    private var visibleGuides: [ImageryGuide] {
        guard let selectedTag else { return ImageryGuide.all }
        return ImageryGuide.all.filter { $0.tag == selectedTag }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)

            chips
                .padding(.top, 8)

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
                        .accessibilityLabel("\(guide.title), \(guide.tag), 2 minute guided imagery")
                        .accessibilityHint("Opens the guide")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(background.ignoresSafeArea())
        .navigationTitle("Imagery Guide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(ImageryGuide.all.count) GUIDES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(sage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(mint))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: selectedTag)
        .sensoryFeedback(.selection, trigger: selectedTag)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("GUIDED IMAGERY")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(sage)

            Text("Imagery Guide")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.7)
                .foregroundStyle(ink)
        }
    }

    // MARK: Filter chips

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                chip(title: "All", symbol: "square.grid.2x2.fill", isSelected: selectedTag == nil) {
                    selectedTag = nil
                }

                ForEach(tags, id: \.self) { tag in
                    chip(title: tag, symbol: symbol(for: tag), isSelected: selectedTag == tag) {
                        selectedTag = tag
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollClipDisabled()
    }

    private func chip(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(deepGreen)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [Color(hex: 0xE4F4AC), Color(hex: 0xCFEA83)] : [Color.white, Color.white],
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

    // MARK: Guide card

    private func card(for guide: ImageryGuide) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 212)
            .background {
                cardImage(for: guide)
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.12), location: 0),
                        .init(color: Color.clear, location: 0.28),
                        .init(color: deepGreen.opacity(0.18), location: 0.58),
                        .init(color: deepGreen.opacity(0.9), location: 1)
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
                durationPill
                    .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private func cardImage(for guide: ImageryGuide) -> some View {
        if let imageName = guide.sessionImage {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
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
    }

    private func cardDetails(for guide: ImageryGuide) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(guide.title)
                    .font(.system(size: 23, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(guide.description)
                    .font(.system(size: 13))
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

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)
        }
        .padding(18)
    }

    private func tagPill(for guide: ImageryGuide) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol(for: guide.tag))
                .font(.system(size: 10, weight: .semibold))

            Text(guide.tag)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(height: 27)
        .background(Capsule().fill(Color.black.opacity(0.32)))
        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
    }

    private var durationPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .semibold))

            Text("2 min")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(height: 27)
        .background(Capsule().fill(Color.black.opacity(0.32)))
        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
    }

    private func symbol(for tag: String) -> String {
        switch tag {
        case "Cozy":  return "sofa"
        case "Peace": return "leaf.fill"
        case "Fresh": return "wind"
        case "Own":   return "heart.fill"
        default:      return "sparkles"
        }
    }

    private var background: some View {
        screenBg
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
}
