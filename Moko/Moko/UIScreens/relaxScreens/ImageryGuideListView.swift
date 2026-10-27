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

    @State private var selectedTag: String? = nil      // nil = "All"

    private let sage      = Color(hex: 0x365948)
    private let deepGreen = Color(hex: 0x1B422F)
    private let tagColors = Color(hex: 0x51443E)
    private let subtitle  = Color(hex: 0x8A7B68)
    private let tileFill  = Color(hex: 0xE6EFE9)
    private let tags      = ["Cozy", "Peace", "Fresh", "Own"]

    private var visibleGuides: [ImageryGuide] {
        guard let selectedTag else { return ImageryGuide.all }
        return ImageryGuide.all.filter { $0.tag == selectedTag }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Imagery Guide")
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(Color.black)
                .padding(.top, 22)

            Text("Breathing and guided imagery paired together")
                .font(.system(size: 13))
                .foregroundStyle(subtitle)
                .padding(.top, 8)

            chips
                .padding(.top, 42)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14.67) {
                    ForEach(visibleGuides) { guide in
                        Button { onSelect(guide) } label: {
                            card(for: guide)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: 0xF2F2F7).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: selectedTag)
    }

    // MARK: Filter chips

    private var chips: some View {
        HStack(spacing: 10.8) {
            chip(title: "All", isSelected: selectedTag == nil) { selectedTag = nil }
            ForEach(tags, id: \.self) { tag in
                chip(title: tag, isSelected: selectedTag == tag) { selectedTag = tag }
            }
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : deepGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 31)
                .background(Capsule().fill(isSelected ? sage : Color.white))
                .overlay(Capsule().stroke(deepGreen, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Guide card

    private func card(for guide: ImageryGuide) -> some View {
        HStack(alignment: .top, spacing: 18) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tileFill)
                .frame(width: 91, height: 111)
                .overlay(
                    Image(systemName: guide.icon)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(sage)
                )

            VStack(alignment: .leading, spacing: 16) {
                Text(guide.title)
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(Color.black)

                Text(guide.description)
                    .font(.system(size: 15))
                    .lineSpacing(4.5)
                    .foregroundStyle(tagColors)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 28)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 13)
        .padding(.trailing, 14)
        .padding(.vertical, 17.5)
        .frame(height: 146, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
        .overlay(alignment: .topTrailing) {
            Text(guide.tag)
                .font(.system(size: 13))
                .foregroundStyle(tagColors)
                .padding(.top, 10)
                .padding(.trailing, 22)
        }
    }
}

#Preview {
    ImageryGuideListView()
}
