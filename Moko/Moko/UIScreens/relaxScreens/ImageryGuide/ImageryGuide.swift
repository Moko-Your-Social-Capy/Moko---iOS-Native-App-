import SwiftUI

// MARK: - Guide

/// One card in the Relax > Imagery guide list. Rows live in the
/// `imagery_guides` table in Supabase.
nonisolated struct ImageryGuide: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let description: String
    /// Matches a row in `imagery_guide_tags`, used by the filter chips.
    let tag: String
    /// SF Symbol name.
    let icon: String
    let detailText: String
    /// Public URL in the `imagery-guide` Supabase Storage bucket.
    let imageURL: String?
    /// Public URL in the `imagery-guide` Supabase Storage bucket for the
    /// looping ambient background music of this session.
    let audioURL: String?
    /// Nudges the full-screen photo left (-) or right (+) to match the design.
    let imageShift: Double
    /// Zooms the full-screen photo in from the top edge to match the design.
    let imageScale: Double
    /// Instructions shown in order while the timer runs.
    let steps: [String]
    let completionText: String
    let durationSeconds: Int
    /// Short duration shown on the card, for example "2 min".
    let durationLabel: String

    var detailDescription: String { detailText }
    var completionMessage: String { completionText }
    var sessionSteps: [String] { steps }

    var artworkURL: URL? {
        guard let imageURL else { return nil }
        return URL(string: imageURL)
    }

    var sessionImageShift: CGFloat { CGFloat(imageShift) }
    var sessionImageScale: CGFloat { CGFloat(imageScale) }

    var sessionAudioURL: URL? {
        guard let audioURL else { return nil }
        return URL(string: audioURL)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case tag
        case icon
        case steps
        case detailText = "detail_text"
        case imageURL = "image_url"
        case audioURL = "audio_url"
        case imageShift = "image_shift"
        case imageScale = "image_scale"
        case completionText = "completion_text"
        case durationSeconds = "duration_seconds"
        case durationLabel = "duration_label"
    }
}

// MARK: - Filter tag

/// A filter chip above the guide list. Rows live in `imagery_guide_tags`.
nonisolated struct ImageryGuideTag: Identifiable, Hashable, Decodable {
    let title: String
    /// SF Symbol name.
    let icon: String

    var id: String { title }
}

// MARK: - Screen copy

/// Shared labels and copy for every Imagery Guide screen. Stored as the single
/// row with `id = 1` in `imagery_guide_screen_content`.
nonisolated struct ImageryGuideScreenContent: Hashable, Decodable {
    let eyebrow: String
    let title: String
    let guidesCountFormat: String
    let allFilterTitle: String
    let allFilterIcon: String
    let errorIcon: String
    let emptyIcon: String
    let cardOpenIcon: String
    let durationIcon: String
    let listAccessibilityHint: String
    let accessibilityLabelFormat: String
    let loadingText: String
    let errorTitle: String
    let errorMessage: String
    let retryButtonTitle: String
    let emptyTitle: String
    let emptyMessage: String
    let sessionStepFormat: String
    let sessionPausedSuffix: String
    let sessionCompleteHeader: String
    let sessionCompleteInstructionFormat: String
    let sessionElapsedFormat: String
    let sessionRemainingFormat: String
    let sessionRestartLabel: String
    let sessionPauseLabel: String
    let sessionPlayLabel: String
    let sessionRestartIcon: String
    let sessionPauseIcon: String
    let sessionPlayIcon: String
    let sessionContinueButton: String
    let completeTitle: String
    let completeSubtitle: String
    let completeHeadline: String
    let completeDoneButton: String
    let completeDefaultMessage: String
    let sessionCompleteNavigationTitle: String

    /// Replaces `{placeholders}` in a Supabase template string.
    func format(_ template: String, _ values: [String: String]) -> String {
        values.reduce(template) { result, pair in
            result.replacingOccurrences(of: "{\(pair.key)}", with: pair.value)
        }
    }

    enum CodingKeys: String, CodingKey {
        case eyebrow
        case title
        case guidesCountFormat = "guides_count_format"
        case allFilterTitle = "all_filter_title"
        case allFilterIcon = "all_filter_icon"
        case errorIcon = "error_icon"
        case emptyIcon = "empty_icon"
        case cardOpenIcon = "card_open_icon"
        case durationIcon = "duration_icon"
        case listAccessibilityHint = "list_accessibility_hint"
        case accessibilityLabelFormat = "accessibility_label_format"
        case loadingText = "loading_text"
        case errorTitle = "error_title"
        case errorMessage = "error_message"
        case retryButtonTitle = "retry_button_title"
        case emptyTitle = "empty_title"
        case emptyMessage = "empty_message"
        case sessionStepFormat = "session_step_format"
        case sessionPausedSuffix = "session_paused_suffix"
        case sessionCompleteHeader = "session_complete_header"
        case sessionCompleteInstructionFormat = "session_complete_instruction_format"
        case sessionElapsedFormat = "session_elapsed_format"
        case sessionRemainingFormat = "session_remaining_format"
        case sessionRestartLabel = "session_restart_label"
        case sessionPauseLabel = "session_pause_label"
        case sessionPlayLabel = "session_play_label"
        case sessionRestartIcon = "session_restart_icon"
        case sessionPauseIcon = "session_pause_icon"
        case sessionPlayIcon = "session_play_icon"
        case sessionContinueButton = "session_continue_button"

        case completeTitle = "complete_title"
        case completeSubtitle = "complete_subtitle"
        case completeHeadline = "complete_headline"
        case completeDoneButton = "complete_done_button"
        case completeDefaultMessage = "complete_default_message"
        case sessionCompleteNavigationTitle = "session_complete_navigation_title"
    }
}

// MARK: - Loaded content

/// Everything the Imagery Guide flow needs from Supabase in one value.
nonisolated struct ImageryGuideContent: Hashable {
    let guides: [ImageryGuide]
    let tags: [ImageryGuideTag]
    let screen: ImageryGuideScreenContent
}

#if DEBUG
extension ImageryGuide {
    /// Preview-only sample. Runtime content always comes from Supabase.
    static let preview = ImageryGuide(
        id: "cozy-room",
        title: "A Cozy Room",
        description: "Imagine yourself in a cozy room where you feel safe, comfortable, and relaxed.",
        tag: "Cozy",
        icon: "sofa",
        detailText: "Imagine a quiet, warm room. Picture the soft sofa beneath you and the gentle light around you.",
        imageURL: nil,
        audioURL: nil,
        imageShift: 0,
        imageScale: 1,
        steps: [
            "Picture a comfortable room. Notice the soft light on the walls.",
            "Notice the soft sofa and the warm blanket. Let your body settle.",
            "Take one slow breath. When you are ready, come back to the room."
        ],
        completionText: "You took a moment to slow down, breathe, and imagine a place where you feel at peace.",
        durationSeconds: 120,
        durationLabel: "2 min"
    )
}
#endif
