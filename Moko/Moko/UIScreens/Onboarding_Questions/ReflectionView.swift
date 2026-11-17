//
//  ReflectionView.swift
//  Moko
//
//  "This is you" — shown after the swipe questions. Lists the user's 4 strengths
//  and 4 areas to grow as rows that open and close when tapped.
//  Deterministically calculated and persisted during onboarding.
//

import SwiftUI

// MARK: - Content

/// One expandable row (a strength or an area to grow).
struct ReflectionItem: Identifiable, Equatable {
    /// Unique category identifier.
    let id: String
    let title: String
    /// SF Symbol name.
    let icon: String
    let detail: String
    var tint: Color = RColor.green
}

extension ReflectionItem {
    /// All 16 predefined categories from the deterministic onboarding assessment.
    static let allDefined: [String: ReflectionItem] = [
        // Q1: Self-expression
        "unexpressed_thoughts": .init(
            id: "unexpressed_thoughts",
            title: "Unexpressed Thoughts",
            icon: "bubble.left.and.exclamationmark.bubble.right",
            detail: "You often hold back thoughts you wish you had shared with close friends or family, waiting for the right moment that never comes.",
            tint: RColor.brown
        ),
        "honest_expression": .init(
            id: "honest_expression",
            title: "Honest Expression",
            icon: "bubble.left.fill",
            detail: "You speak openly with the people close to you, sharing what is on your mind rather than letting thoughts linger unsaid.",
            tint: RColor.green
        ),

        // Q2: Emotional openness
        "emotional_guardedness": .init(
            id: "emotional_guardedness",
            title: "Emotional Guardedness",
            icon: "lock.shield",
            detail: "When something is bothering you, you tend to keep it contained inside even around those you trust most.",
            tint: RColor.brown
        ),
        "trusted_vulnerability": .init(
            id: "trusted_vulnerability",
            title: "Trusted Vulnerability",
            icon: "heart.fill",
            detail: "You feel secure opening up to people you trust when going through a difficult moment, inviting genuine support.",
            tint: RColor.green
        ),

        // Q3: Group participation
        "hesitant_participation": .init(
            id: "hesitant_participation",
            title: "Hesitant Participation",
            icon: "pause.circle",
            detail: "In group discussions, you tend to hold back and wait for others to speak first before offering your own thoughts.",
            tint: RColor.brown
        ),
        "thoughtful_presence": .init(
            id: "thoughtful_presence",
            title: "Thoughtful Presence",
            icon: "ear",
            detail: "You listen deeply and absorb before reacting, cultivating a grounded atmosphere that eases social friction.",
            tint: RColor.green
        ),

        // Q4: Social initiative
        "social_hesitation": .init(
            id: "social_hesitation",
            title: "Social Hesitation",
            icon: "person.crop.circle.badge.questionmark",
            detail: "You sometimes skip joining groups or social events out of fear of not fitting in, missing chances to connect.",
            tint: RColor.brown
        ),
        "social_initiative": .init(
            id: "social_initiative",
            title: "Social Initiative",
            icon: "person.2.fill",
            detail: "You take bold steps to join new groups and communities, welcoming unfamiliar spaces with curiosity and confidence.",
            tint: RColor.green
        ),

        // Q5: Friendship honesty
        "conflict_avoidance": .init(
            id: "conflict_avoidance",
            title: "Conflict Avoidance",
            icon: "hand.raised.slash",
            detail: "Within your friend circle, you avoid speaking hard truths to sidestep awkwardness, sometimes leaving underlying issues unaddressed.",
            tint: RColor.brown
        ),
        "deep_loyalty": .init(
            id: "deep_loyalty",
            title: "Deep Loyalty",
            icon: "heart",
            detail: "In trusted circles, you show up with candid honesty, consistency, and steadfast emotional safety.",
            tint: RColor.green
        ),

        // Q6: Personal boundaries
        "boundary_softening": .init(
            id: "boundary_softening",
            title: "Boundary Softening",
            icon: "shield.slash",
            detail: "You often soften or delay a firm “no” to keep things comfortable, even when something does not work for you.",
            tint: RColor.brown
        ),
        "boundary_awareness": .init(
            id: "boundary_awareness",
            title: "Boundary Awareness",
            icon: "shield.checkmark",
            detail: "You hold healthy boundaries with clarity and respect, knowing that saying no when necessary preserves genuine relationships.",
            tint: RColor.green
        ),

        // Q7: Conversation confidence
        "post_chat_overthinking": .init(
            id: "post_chat_overthinking",
            title: "Post-Chat Overthinking",
            icon: "arrow.triangle.2.circlepath",
            detail: "After a conversation you tend to replay what was said and wonder if you got it right, which can linger long after the moment has passed.",
            tint: RColor.brown
        ),
        "present_moment_confidence": .init(
            id: "present_moment_confidence",
            title: "Present-Moment Confidence",
            icon: "sparkles",
            detail: "You trust how you showed up in conversations, moving forward freely without replaying moments or second-guessing yourself.",
            tint: RColor.green
        ),

        // Q8: Family communication
        "emotional_suppression": .init(
            id: "emotional_suppression",
            title: "Emotional Suppression",
            icon: "speaker.slash",
            detail: "When there is tension at home, you tend to stay silent rather than express how you feel, carrying the stress quietly.",
            tint: RColor.brown
        ),
        "calm_self_expression": .init(
            id: "calm_self_expression",
            title: "Calm Self-Expression",
            icon: "waveform",
            detail: "When tensions rise, you communicate with grounded composure, speaking your truth while keeping the environment calm.",
            tint: RColor.green
        )
    ]

    /// Resolves a category ID with backward-compatible aliases for legacy identifiers.
    static func item(for id: String) -> ReflectionItem? {
        if let found = allDefined[id] {
            return found
        }
        // Aliases for legacy identifiers
        switch id {
        case "presence": return allDefined["thoughtful_presence"]
        case "loyalty": return allDefined["deep_loyalty"]
        case "hesitation": return allDefined["hesitant_participation"]
        case "overthinking": return allDefined["post_chat_overthinking"]
        case "boundary": return allDefined["boundary_softening"]
        default: return nil
        }
    }

    /// Default 4 strengths when no saved assessment is present (e.g. previews).
    static let defaultStrengths: [ReflectionItem] = [
        allDefined["thoughtful_presence"]!,
        allDefined["deep_loyalty"]!,
        allDefined["social_initiative"]!,
        allDefined["present_moment_confidence"]!
    ]

    /// Default 4 areas to grow when no saved assessment is present (e.g. previews).
    static let defaultAreasToGrow: [ReflectionItem] = [
        allDefined["hesitant_participation"]!,
        allDefined["post_chat_overthinking"]!,
        allDefined["boundary_softening"]!,
        allDefined["unexpressed_thoughts"]!
    ]
}

// MARK: - Screen

struct ReflectionView: View {
    /// The name saved during onboarding; used when no name is passed in.
    @AppStorage("userName") private var storedUserName: String = ""

    var userName: String?
    /// Called when the user taps "Overview".
    var onOverview: () -> Void

    init(
        userName: String? = nil,
        onOverview: @escaping () -> Void = {}
    ) {
        self.userName = userName
        self.onOverview = onOverview
    }

    /// Passed-in name first, then the saved one, else "" (title drops the name).
    private var displayName: String {
        let candidates = [userName ?? "", storedUserName]
        return candidates
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    /// IDs of the rows that are open. Starts completely empty so ALL categories are closed by default.
    @State private var expanded: Set<String> = []

    /// Saved deterministic assessment result from onboarding.
    private var savedResult: OnboardingReflectionResult? {
        OnboardingReflectionService.loadResult()
    }

    /// Exactly 4 strengths derived from the saved assessment.
    private var strengths: [ReflectionItem] {
        if let savedResult {
            let items = savedResult.strengthCategoryIDs.compactMap { ReflectionItem.item(for: $0) }
            if items.count == 4 { return items }
        }
        return ReflectionItem.defaultStrengths
    }

    /// Exactly 4 areas of growth derived from the saved assessment.
    private var areasToGrow: [ReflectionItem] {
        if let savedResult {
            let items = savedResult.developmentCategoryIDs.compactMap { ReflectionItem.item(for: $0) }
            if items.count == 4 { return items }
        }
        return ReflectionItem.defaultAreasToGrow
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Screen Title (aligned with Strengths and Areas to Grow headings)
                Text(displayName.isEmpty ? "This is you" : "This is you, \(displayName)")
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(OBColor.ink)
                    .padding(.top, 28)

                // Strengths Section (gap reduced from 53 to 20 for tight, clean spacing)
                sectionHeading("Strengths")
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(strengths) { item in row(item, isStrength: true) }
                }
                .padding(.top, 16)

                // Areas to Grow Section (standardized label, well-spaced)
                sectionHeading("Areas to Grow")
                    .padding(.top, 32)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(areasToGrow) { item in row(item, isStrength: false) }
                }
                .padding(.top, 16)
            }
            .padding(.leading, 37)
            .padding(.trailing, 45)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(MokoBackdrop())
        // Pins the button to the bottom; the scroll content stops above it instead of under it.
        // Transparent background so the full gradient-themed backdrop flows through continuously.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PillButton(title: "Overview", action: onOverview)
                .padding(.horizontal, 36)
                .padding(.top, 12)
                .padding(.bottom, 34)
        }
    }

    private func sectionHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .medium))
            .tracking(-0.4)
            .foregroundStyle(RColor.text)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Expandable row

    private func row(_ item: ReflectionItem, isStrength: Bool) -> some View {
        let isOpen = expanded.contains(item.id)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.28)) { toggle(item.id) }
            } label: {
                HStack(spacing: 15) {
                    ZStack {
                        Circle().fill(OBColor.cardFill)
                        Image(systemName: item.icon)
                            .font(.system(size: 14, weight: .medium))
                            // Strengths SF symbols are always green; areas to grow (weaknesses) are always brown.
                            .foregroundStyle(isStrength ? RColor.green : RColor.brown)
                    }
                    .frame(width: 28, height: 28)

                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RColor.text)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    // Points down when closed, rotates to point up when open.
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RColor.chevron)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                // Makes the empty space in the row tappable too.
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")

            if isOpen {
                Text(item.detail)
                    .font(.system(size: 16))
                    .lineSpacing(3.5)
                    .foregroundStyle(RColor.body)
                    // Let the text wrap onto as many lines as it needs.
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 43)               // lines up with the title text
                    .transition(.opacity)
            }
        }
    }

    /// Opens the row if closed, closes it if open.
    private func toggle(_ id: String) {
        if expanded.contains(id) {
            expanded.remove(id)
        } else {
            expanded.insert(id)
        }
    }
}

#Preview {
    ReflectionView(userName: "Aditi")
}
