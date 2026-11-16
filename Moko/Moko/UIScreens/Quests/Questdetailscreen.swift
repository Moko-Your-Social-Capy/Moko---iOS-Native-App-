//
//  QuestDetailScreen.swift
//  Moko
//
//  Opens when a quest card (or its check button) is tapped. A category image, then the
//  quest's title, category, intensity and XP, then a briefing (scene, who, goal) generated
//  on-device through `QuestBriefGenerating` (backed by the AFM quest-card service). Sliding
//  "Slide to debrief" completes the quest and opens the debrief conversation (Questdebrief.swift).
//

import SwiftUI
import SwiftData

// MARK: - Briefing (what the on-device model generates)

/// The three parts of a quest briefing.
struct QuestBrief: Equatable {
    var scene: String
    var who: String
    var goal: String
}

/// Plain values the generator needs. Keeping it separate from the database object
/// makes it easy to hand to a model prompt later.
struct QuestBriefRequest {
    var title: String
    var notes: String
    var category: QuestCategory
    var intensity: QuestIntensity
}

/// Anything that can write a briefing. A protocol, so previews or tests can pass a fake one.
protocol QuestBriefGenerating {
    func brief(for request: QuestBriefRequest) async -> QuestBrief
}

// MARK: - AFM Quest Brief Generator

/// Writes the briefing with Apple Foundation Models (falls back to a template inside `QuestCardService`).
@MainActor
final class AFMQuestBriefGenerator: QuestBriefGenerating {
    func brief(for request: QuestBriefRequest) async -> QuestBrief {
        let input = CustomQuestInput(
            title: request.title,
            notes: request.notes,
            category: request.category,
            difficulty: Difficulty(intensity: request.intensity),
            date: .now
        )
        // `_` ignores the second value (where the card came from), which we don't need here.
        let (card, _) = await QuestCardService.customCard(input)
        return QuestBrief(scene: card.scene, who: card.who, goal: card.goal)
    }
}

// MARK: - Category image
extension QuestCategory {
    /// Name of the image in Assets.xcassets. Add one per category and it covers the placeholder:
    /// quest_work, quest_dating, quest_friends, quest_family, quest_others
    var bannerImageName: String {
        "quest_\(rawValue.lowercased())"
    }
}

/// Gradient colours and an SF Symbol for the drawn placeholder banner of each category.
private struct QuestCategoryArt {
    let top: Color
    let bottom: Color
    let accent: Color
    let symbol: String

    static func art(for category: QuestCategory) -> QuestCategoryArt {
        switch category {
        case .work:
            return QuestCategoryArt(
                top: Color(red: 226/255, green: 238/255, blue: 252/255),
                bottom: Color(red: 190/255, green: 212/255, blue: 240/255),
                accent: Color(red: 52/255, green: 96/255, blue: 150/255),
                symbol: "briefcase.fill"
            )
        case .dating:
            return QuestCategoryArt(
                top: Color(red: 253/255, green: 232/255, blue: 228/255),
                bottom: Color(red: 247/255, green: 200/255, blue: 196/255),
                accent: Color(red: 200/255, green: 80/255, blue: 90/255),
                symbol: "heart.fill"
            )
        case .friends:
            return QuestCategoryArt(
                top: Color(red: 226/255, green: 244/255, blue: 232/255),
                bottom: Color(red: 190/255, green: 226/255, blue: 202/255),
                accent: Color(red: 54/255, green: 110/255, blue: 80/255),
                symbol: "person.2.fill"
            )
        case .family:
            return QuestCategoryArt(
                top: Color(red: 252/255, green: 240/255, blue: 218/255),
                bottom: Color(red: 244/255, green: 220/255, blue: 178/255),
                accent: Color(red: 170/255, green: 112/255, blue: 40/255),
                symbol: "person.3.fill"
            )
        case .others:
            return QuestCategoryArt(
                top: Color(red: 238/255, green: 232/255, blue: 252/255),
                bottom: Color(red: 214/255, green: 204/255, blue: 244/255),
                accent: Color(red: 104/255, green: 84/255, blue: 170/255),
                symbol: "sparkles"
            )
        }
    }
}

// MARK: - Detail screen

struct QuestDetailScreen: View {
    let quest: Quest
    var generator: any QuestBriefGenerating = AFMQuestBriefGenerator()

    /// When this quest was opened from the Quest Library, the artwork URL from
    /// the library card, so the detail shows the same image instead of the
    /// category placeholder. Nil for custom quests opened from the Quests tab.
    var libraryArtworkURL: URL? = nil

    // Pops this screen off the navigation stack.
    @Environment(\.dismiss) private var dismiss
    // SwiftData's "save box". Completing the quest writes through it.
    @Environment(\.modelContext) private var modelContext
    // Switches the Overview tab after the debrief. Provided by MokoRootView (see MokoNavigation.swift).
    @Environment(\.openOverview) private var openOverview

    // The generated briefing. nil while it is loading (grey placeholder lines show).
    @State private var brief: QuestBrief?
    // false = briefing, true = debrief chat. Both live on this one screen.
    @State private var showingDebrief = false
    // Practice is separate from the real event and never awards XP.
    @State private var showingSimulation = false

    // Timeline colours: lavender + violet for the scene and goal, blue for who.
    private let sceneFill = MokoScreenTheme.Colors.surfaceLavender
    private let sceneIcon = MokoScreenTheme.Colors.dataVioletDeep
    private let whoFill = MokoScreenTheme.Colors.accentBlueTint
    private let whoIcon = MokoScreenTheme.Colors.countdownValue
    private let goalFill = MokoScreenTheme.Colors.surfaceLavender
    private let goalIcon = MokoScreenTheme.Colors.dataVioletDeep

    var body: some View {
        ZStack {
            // Swap between the briefing and the debrief with a sideways slide.
            if showingDebrief {
                QuestDebriefScreen(quest: quest) { outcome in
                    finishDebrief(outcome)
                }
                .transition(.move(edge: .trailing))
            } else {
                detail
                    .transition(.move(edge: .leading))
            }
        }
        .background(MokoBackdrop())
        .fullScreenCover(isPresented: $showingSimulation) {
            NavigationStack {
                SimulationScreen(questTitle: quest.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close", systemImage: "xmark") { showingSimulation = false }
                        }
                    }
            }
        }
        // The NavigationStack supplies the default back button on the detail; the debrief is
        // chat-only, so no bar (and no back button) sits above its conversation.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showingDebrief ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        // `.task` runs when the screen appears. It loads the briefing from the on-device model.
        .task {
            // Only once: coming back from the debrief must not generate a new briefing.
            guard brief == nil else { return }
            let request = QuestBriefRequest(
                title: quest.title,
                notes: quest.notes,
                category: quest.category,
                intensity: quest.intensity
            )
            let result = await generator.brief(for: request)
            withAnimation(.easeOut(duration: 0.4)) {
                brief = result
            }
        }
    }

    // MARK: Detail content
    private var detail: some View {
        ZStack {
            MokoBackdrop()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Quest")
                        .mokoText(MokoScreenTheme.Typeface.title1)
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 8)

                    card
                        .padding(.horizontal, MokoScreenTheme.Space.page)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Practice first", systemImage: "bubble.left.and.bubble.right")
                            .font(.headline)
                        Text("Rehearse with Moko before the real event. Practice does not complete your quest or award XP.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Practice with Moko", systemImage: "play.fill") {
                            showingSimulation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MokoScreenTheme.Colors.forest)
                        .controlSize(.large)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mokoCard()
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            QuestSlideButton(title: "Slide to debrief") {
                markCompleted()
                withAnimation(.easeInOut(duration: 0.35)) {
                    showingDebrief = true
                }
            }
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.bottom, 12)
        }
    }

    /// Where the debrief sends the user: Continue, Finish Later and Leave each open a
    /// different version of the Overview tab, then this whole screen closes.
    private func finishDebrief(_ outcome: DebriefOutcome) {
        switch outcome {
        case .completed:
            PendingDebriefStore.clear()
            // Play the success sound for both custom quests and Quest Library quests.
            DebriefSoundPlayer.shared.playSuccess()
            openOverview?(.debriefDone)
        case .finishLater:
            PendingDebriefStore.save(quest)
            openOverview?(.resume)
        case .leave:
            PendingDebriefStore.clear()
            openOverview?(.todo)
        }
        dismiss()
    }

    /// Sliding to debrief is what completes the quest and awards its XP/streak.
    private func markCompleted() {
        QuestProgress.complete(quest, in: modelContext)
    }

    // MARK: Card
    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            banner

            VStack(alignment: .leading, spacing: 0) {
                // Title + XP
                HStack(alignment: .top, spacing: 12) {
                    Text(quest.title)
                        .mokoText(MokoScreenTheme.Typeface.title2)
                        .foregroundStyle(QuestStyle.titleBrown)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(quest.awardedXP) XP")
                            .mokoText(MokoScreenTheme.Typeface.slider)
                    }
                    .foregroundStyle(QuestStyle.xpColor(for: quest.awardedXP))
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(QuestStyle.chipSelectedFill))
                }

                // Category + intensity
                HStack(spacing: 8) {
                    tag(icon: quest.category.symbol, text: quest.category.rawValue, dot: nil)
                    tag(icon: nil, text: quest.intensity.rawValue, dot: intensityColor)
                }
                .padding(.top, 14)

                Rectangle()
                    .fill(QuestStyle.divider)
                    .frame(height: 1)
                    .padding(.top, 20)
                    .padding(.bottom, 22)

                // Briefing label
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Briefing")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                }
                .foregroundStyle(QuestStyle.accent)
                .padding(.bottom, 18)

                timelineRow(
                    icon: "mappin.and.ellipse",
                    fill: sceneFill, iconColor: sceneIcon,
                    label: "The scene",
                    text: brief?.scene,
                    lineTo: whoFill
                )

                timelineRow(
                    icon: "person.2.fill",
                    fill: whoFill, iconColor: whoIcon,
                    label: "Who",
                    text: brief?.who,
                    lineTo: goalFill
                )

                timelineRow(
                    icon: "target",
                    fill: goalFill, iconColor: goalIcon,
                    label: "Your goal",
                    text: brief?.goal,
                    lineTo: nil
                )
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: MokoScreenTheme.Radius.card, style: .continuous))
        .mokoCard()
    }

    // MARK: Card artwork
    @ViewBuilder
    private var banner: some View {
        if let url = libraryArtworkURL {
            // Quest opened from the Quest Library: show the card's own artwork
            // instead of the category placeholder.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .overlay {
                    // AsyncImage downloads the picture. `phase` tells us loading / done / failed.
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ZStack {
                                Color.white.opacity(0.25)
                                MokoLoadingView()
                                    .frame(width: 44, height: 44)
                            }
                        case .failure:
                            categoryPlaceholder
                        @unknown default:
                            categoryPlaceholder
                        }
                    }
                }
                .clipped()
        } else {
            categoryPlaceholder
        }
    }

    /// The category placeholder art shown for custom quests (opened from the
    /// Quests tab), and as a fallback when a library quest's artwork fails to
    /// load.
    private var categoryPlaceholder: some View {
        let art = QuestCategoryArt.art(for: quest.category)

        // The base view fixes the size; the artwork sits in overlays so a large
        // image can never make the card wider than the screen.
        return Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .background {
                LinearGradient(colors: [art.top, art.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            // Placeholder art, different for each category.
            .overlay {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 170, height: 170)
                        .offset(x: -110, y: 50)

                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 120, height: 120)
                        .offset(x: 120, y: -50)

                    Image(systemName: art.symbol)
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(art.accent)
                        .frame(width: 108, height: 108)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: art.accent.opacity(0.22), radius: 14, x: 0, y: 8)
                        )
                }
            }
            // The real image, once it's in Assets. A missing image draws nothing, so the art above shows.
            .overlay {
                Image(quest.category.bannerImageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }

    private var intensityColor: Color {
        switch quest.intensity {
        case .easy:   return MokoScreenTheme.Colors.dataViolet
        case .medium: return Color(red: 232/255, green: 176/255, blue: 76/255)
        case .hard:   return Color(red: 222/255, green: 108/255, blue: 92/255)
        }
    }

    /// A small capsule label with either an icon or a coloured dot in front.
    private func tag(icon: String?, text: String, dot: Color?) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            if let dot {
                Circle().fill(dot).frame(width: 8, height: 8)
            }
            Text(text)
                .mokoText(MokoScreenTheme.Typeface.caption)
        }
        .foregroundStyle(QuestStyle.title)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(Capsule().fill(QuestStyle.screenBg))
    }

    /// One step of the vertical timeline: a round icon on the left, text on the right.
    /// `lineTo` is the next step's colour; pass nil on the last step (no line below).
    /// Shows grey placeholder lines until the text arrives.
    private func timelineRow(icon: String,
                             fill: Color,
                             iconColor: Color,
                             label: String,
                             text: String?,
                             lineTo nextFill: Color?) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                // Round node with a soft white ring and a two-tone symbol.
                ZStack {
                    Circle()
                        .fill(fill)

                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 1.5)
                        .padding(3)

                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 52, height: 52)
                .shadow(color: iconColor.opacity(0.2), radius: 7, x: 0, y: 3)

                // The line that joins this step to the next one.
                if let nextFill {
                    Capsule()
                        .fill(LinearGradient(colors: [fill, nextFill], startPoint: .top, endPoint: .bottom))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 6)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .mokoText(MokoScreenTheme.Typeface.caption)
                    .foregroundStyle(iconColor)

                if let text {
                    Text(text)
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(QuestStyle.title)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                } else {
                    QuestSkeletonLines()
                }
            }
            .padding(.top, 6)
            .padding(.bottom, nextFill == nil ? 0 : 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Loading placeholder

/// Three grey bars that gently pulse while the briefing loads.
struct QuestSkeletonLines: View {
    // The phone setting "Reduce Motion". If it is on, the bars stay still.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Flipped once on appear. `repeatForever` then fades the bars in and out on its own.
    @State private var dim = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 5).frame(height: 12)
            RoundedRectangle(cornerRadius: 5).frame(height: 12)
            RoundedRectangle(cornerRadius: 5).frame(width: 120, height: 12)
        }
        .foregroundStyle(Color.black.opacity(0.08))
        .opacity(dim ? 0.45 : 1)
        .accessibilityLabel("Loading")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                dim = true
            }
        }
    }
}

// MARK: - Slide to confirm

/// A "slide to …" track. Drag the knob past 80% of the way to confirm;
/// let go earlier and it springs back. VoiceOver users can double-tap instead.
struct QuestSlideButton: View {
    let title: String
    var onComplete: () -> Void

    // How far the knob has been dragged, in points.
    @State private var drag: CGFloat = 0
    // True right after a successful slide. Shows a checkmark and plays a success buzz.
    @State private var completed = false

    private let height = MokoScreenTheme.Control.trackHeight
    private let knob = MokoScreenTheme.Control.knob
    private let inset = MokoScreenTheme.Control.knobInset

    var body: some View {
        // GeometryReader tells us the track width, so we know how far the knob can go.
        GeometryReader { geo in
            let maxDrag = max(1, geo.size.width - knob - inset * 2)
            let fraction = min(1, max(0, drag / maxDrag))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MokoScreenTheme.Colors.accentBlue)

                // Lighter trail behind the knob.
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: inset * 2 + knob + drag)

                // The title fades out as the knob moves over it.
                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.slider)
                    .foregroundStyle(Color.white.opacity(1 - 0.7 * Double(fraction)))
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knob * 0.5)

                ZStack {
                    Circle()
                        .fill(MokoScreenTheme.Colors.surfaceWhite)
                        .shadow(color: MokoScreenTheme.Elevation.knobColor, radius: MokoScreenTheme.Elevation.knobRadius, x: 0, y: MokoScreenTheme.Elevation.knobOffset)

                    Image(systemName: completed ? "checkmark" : "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                }
                .frame(width: knob, height: knob)
                .offset(x: inset + drag)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !completed else { return }
                            drag = min(max(0, value.translation.width), maxDrag)
                        }
                        .onEnded { _ in
                            guard !completed else { return }
                            if drag > maxDrag * 0.8 {
                                finish(maxDrag: maxDrag)
                            } else {
                                // Not far enough: spring back to the start.
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    drag = 0
                                }
                            }
                        }
                )
            }
        }
        .frame(height: height)
        .sensoryFeedback(.success, trigger: completed)
        // VoiceOver can't drag, so read the track as one button and let a double-tap confirm.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onComplete() }
    }

    /// Snaps the knob to the end, reports success, then quietly resets.
    private func finish(maxDrag: CGFloat) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            drag = maxDrag
            completed = true
        }
        onComplete()

        // Reset while the next page is covering the screen.
        // `Task.sleep` waits 0.8s without freezing the app.
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            drag = 0
            completed = false
        }
    }
}
