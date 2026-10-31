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
