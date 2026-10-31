import SwiftUI

// MARK: - Model

struct ImageryGuide: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let tag: String        // matches a filter chip
    let icon: String       // SF Symbol name
    var detailText: String? = nil       // longer text for the detail screen
    var sessionImage: String? = nil     // full-screen photo for the timer screen
    var sessionImageShift: CGFloat = 0  // nudges the photo left (-) or right (+) to match the design
    var sessionImageScale: CGFloat = 1  // zooms the photo in from the top edge to match the design
    var steps: [String]? = nil          // instructions shown during the 2 minutes
    var detailSubtitle: String? = nil   // subtitle on the detail screen
    var completionText: String? = nil   // message on the "You did it!" screen

    var detailDescription: String { detailText ?? description }
    var detailHeaderSubtitle: String { detailSubtitle ?? "Breathing and guided imagery paired together" }
    var completionMessage: String {
        completionText ?? "You took a moment to slow down, breathe, and imagine a place where you feel at peace."
    }

    /// Three instructions that change while the timer runs.
    var sessionSteps: [String] {
        steps ?? [
            "Picture \(title.lowercased()). Notice the colors and shapes around you.",
            "Notice how it feels to be there. Let your body settle.",
            "Take one slow breath. When you are ready, come back to the present."
        ]
    }

    static let all: [ImageryGuide] = [
        ImageryGuide(id: "cozy-room",
                     title: "A Cozy Room",
                     description: "Imagine yourself in a cozy room where you feel safe, comfortable, and relaxed.",
                     tag: "Cozy", icon: "sofa",
                     detailText: "Imagine a quiet, warm room. Picture the soft sofa beneath you and the gentle light around you. You can listen to the guidance or simply explore the scene in your own way.",
                     sessionImage: "cozy_room",
                     sessionImageShift: -66.5,
                     steps: [
                        "Picture a comfortable room. Notice the soft light on the walls.",
                        "Notice the soft sofa and the warm blanket. Let your body settle.",
                        "Take one slow breath. When you are ready, come back to the room."
                     ],
                     detailSubtitle: "A gentle guided visualization"),
        ImageryGuide(id: "calm-garden",
                     title: "A Calm Garden",
                     description: "Imagine a peaceful garden with gentle sounds, fresh air, and greenery all around you.",
                     tag: "Peace", icon: "tree",
                     detailText: "Imagine a peaceful garden, fresh flowers, and a gentle breeze. Take a deep breath and let yourself relax.",
                     sessionImage: "calm_garden",
                     steps: [
                        "Picture a quiet garden. Notice the green around you and the gentle sounds.",
                        "Feel the fresh air and the soft breeze. Let your shoulders relax.",
                        "Take one slow breath. When you are ready, come back to the garden."
                     ],
                     completionText: "You took a moment to slow down, breathe, and picture a calm garden where you feel at peace."),
        ImageryGuide(id: "misty-hill",
                     title: "A Misty Hill Station",
                     description: "Imagine cool mountain air, misty green hills, and peaceful morning around you.",
                     tag: "Fresh", icon: "mountain.2",
                     detailText: "We\u{2019}re about to take you to a peaceful, misty hill station. Picture yourself surrounded by cool air, green hills, and soft clouds drifting by. Get ready to unwind.",
                     sessionImage: "misty_hill",
                     steps: [
                        "Picture cool mountain air and soft mist over green hills.",
                        "Watch the clouds drift slowly by. Let each breath feel cool and light.",
                        "Take one slow breath. When you are ready, come back to the hills."
                     ],
                     completionText: "You took a moment to slow down, breathe, and picture a misty hill station where you feel at peace."),
        ImageryGuide(id: "childhood-memory",
                     title: "A Childhood Memory",
                     description: "Imagine a happy childhood moment that makes you feel safe, warm, and at peace.",
                     tag: "Own", icon: "teddybear",
                     detailText: "Imagine a happy childhood memory, filled with familiar faces, warm smiles, and simple joys. Take a deep breath and let yourself feel safe, calm, and relaxed.",
                     sessionImage: "childhood_memory",
                     sessionImageScale: 1.061,
                     steps: [
                        "Picture a happy childhood moment. Notice who is with you and how it feels.",
                        "Notice the warm evening light and the comfort of being together.",
                        "Take one slow breath. When you are ready, come back to the present."
                     ],
                     completionText: "You took a moment to slow down, breathe, and revisit a childhood memory that makes you feel safe and at peace.")
    ]
}

// MARK: - Screen

struct ImageryGuideListView: View {
    var onSelect: (ImageryGuide) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTag: String? = nil      // nil = "All"

    private let sage      = Color(hex: 0x365948)
    private let deepGreen = Color(hex: 0x1B422F)
    private let ink       = Color(hex: 0x292B26)
    private let bodyText  = Color(hex: 0x51443E)
    private let muted     = Color(hex: 0x6F6762)
    private let mint      = Color(hex: 0xE6EFE9)
    private let screenBg  = Color(hex: 0xF2F2F7)
    private let tags      = ["Cozy", "Peace", "Fresh", "Own"]

    private var visibleGuides: [ImageryGuide] {
        guard let selectedTag else { return ImageryGuide.all }
        return ImageryGuide.all.filter { $0.tag == selectedTag }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

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
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: selectedTag)
        .sensoryFeedback(.selection, trigger: selectedTag)
    }

    // MARK: Header

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))

                Text("\(ImageryGuide.all.count) GUIDES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.7)
            }
            .foregroundStyle(sage)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Capsule().fill(mint))
            .overlay(Capsule().stroke(sage.opacity(0.08), lineWidth: 1))
        }
    }

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
            .foregroundStyle(isSelected ? Color.white : deepGreen)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [sage, deepGreen] : [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.03), radius: 7, x: 0, y: 3)
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
