//
//  QuestDetailScreen.swift
//  Moko
//
//  Opens when a quest card (or its check button) is tapped. A category image, then the
//  quest's title, category, intensity and XP, then a briefing (scene, who, goal) from a
//  QuestBriefGenerating object. For now that is a dummy generator; swap in an Apple
//  Foundation Models one later. Sliding "Slide to debrief" completes the quest and opens
//  the debrief conversation (QuestDebrief.swift).
//

import SwiftUI
import SwiftData

// MARK: - Briefing (what the on-device model will generate)
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

protocol QuestBriefGenerating {
    func brief(for request: QuestBriefRequest) async -> QuestBrief
}

/// Placeholder content. To use Apple Foundation Models, write another type that
/// conforms to QuestBriefGenerating and pass it to QuestDetailScreen(generator:).
struct DummyQuestBriefGenerator: QuestBriefGenerating {
    func brief(for request: QuestBriefRequest) async -> QuestBrief {
        // Pretend it takes a moment, like a real model would
        try? await Task.sleep(for: .milliseconds(1100))

        let scene: String
        let who: String
        switch request.category {
        case .work:
            scene = "A professional moment where this comes up. Keep the tone calm, clear and kind to yourself."
            who = "You and the people involved at work."
        case .dating:
            scene = "A relaxed, low-pressure moment together. No agenda, just time to talk and get to know each other."
            who = "Your date and you."
        case .friends:
            scene = "A casual hangout with someone you trust. No pressure, just time to catch up."
            who = "Your friend and you."
        case .family:
            scene = "A familiar, comfortable setting. Slow down and really talk."
            who = "Your family member and you."
        case .others:
            scene = "A new or unfamiliar situation. Take your time and settle in before you begin."
            who = "You and the people involved."
        }

        let goal: String
        switch request.intensity {
        case .easy:
            goal = "Take one small step: start the conversation and listen for one thing worth following up on."
        case .medium:
            goal = "Open with one question, then ask a follow-up on something they said and let the conversation flow naturally."
        case .hard:
            goal = "Share something real about yourself, then ask a deeper question and stay with the answer."
        }

        return QuestBrief(scene: scene, who: who, goal: goal)
    }
}

// MARK: - Category image (placeholder until the artwork is added)
extension QuestCategory {
    /// Name of the image in Assets.xcassets. Add one per category and it covers the placeholder:
    /// quest_work, quest_dating, quest_friends, quest_family, quest_others
    var bannerImageName: String {
        "quest_\(rawValue.lowercased())"
    }
}

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
    var generator: any QuestBriefGenerating = DummyQuestBriefGenerator()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openOverview) private var openOverview

    @State private var brief: QuestBrief?
    @State private var showingDebrief = false

    // Timeline colours: warm sand for the scene, sky blue for who, green for the goal
    private let sceneTop = Color(red: 250/255, green: 240/255, blue: 218/255)
    private let sceneBottom = Color(red: 238/255, green: 214/255, blue: 170/255)
    private let sceneIcon = Color(red: 160/255, green: 104/255, blue: 34/255)

    private let whoTop = Color(red: 226/255, green: 238/255, blue: 252/255)
    private let whoBottom = Color(red: 186/255, green: 210/255, blue: 240/255)
    private let whoIcon = Color(red: 52/255, green: 96/255, blue: 150/255)

    private let goalTop = Color(red: 214/255, green: 238/255, blue: 222/255)
    private let goalBottom = Color(red: 156/255, green: 205/255, blue: 176/255)
    private let goalIcon = Color(red: 27/255, green: 66/255, blue: 47/255)

    var body: some View {
        ZStack {
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
        .background(QuestStyle.screenBg.ignoresSafeArea())
        .task {
            // Runs once, not each time you come back from the debrief
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
            QuestStyle.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(Color(red: 237/255, green: 237/255, blue: 237/255)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Text("Quest")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    card
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
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
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }

    /// Where the debrief sends the user: Continue, Finish Later and Leave each open a
    /// different version of the Overview tab, then this whole screen closes.
    private func finishDebrief(_ outcome: DebriefOutcome) {
        switch outcome {
        case .completed:
            PendingDebriefStore.clear()
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

    /// Sliding to debrief is what completes the quest
    private func markCompleted() {
        guard !quest.isCompleted else { return }
        quest.isCompleted = true
        try? modelContext.save()
    }

    // MARK: Card
    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            banner

            VStack(alignment: .leading, spacing: 0) {
                // Title + XP
                HStack(alignment: .top, spacing: 12) {
                    Text(quest.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(QuestStyle.title)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(quest.awardedXP) XP")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(QuestStyle.green)
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
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(QuestStyle.green)
                .padding(.bottom, 18)

                timelineRow(
                    icon: "mappin.and.ellipse",
                    top: sceneTop, bottom: sceneBottom, iconColor: sceneIcon,
                    label: "THE SCENE",
                    lineTo: whoTop,
                    text: brief?.scene, showLine: true
                )

                timelineRow(
                    icon: "person.2.fill",
                    top: whoTop, bottom: whoBottom, iconColor: whoIcon,
                    label: "WHO",
                    lineTo: goalTop,
                    text: brief?.who, showLine: true
                )

                timelineRow(
                    icon: "target",
                    top: goalTop, bottom: goalBottom, iconColor: goalIcon,
                    label: "YOUR GOAL",
                    lineTo: goalTop,
                    text: brief?.goal, showLine: false
                )
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: Category image
    private var banner: some View {
        let art = QuestCategoryArt.art(for: quest.category)

        // The base view fixes the size; the artwork sits in overlays so a large
        // image can never make the card wider than the screen.
        return Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .background {
                LinearGradient(colors: [art.top, art.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            // Placeholder art, different for each category
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
            // The real image, once it's in Assets
            .overlay {
                Image(quest.category.bannerImageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }

    private var intensityColor: Color {
        switch quest.intensity {
        case .easy:   return Color(red: 120/255, green: 165/255, blue: 140/255)
        case .medium: return Color(red: 232/255, green: 176/255, blue: 76/255)
        case .hard:   return Color(red: 222/255, green: 108/255, blue: 92/255)
        }
    }

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
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(QuestStyle.title)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(Capsule().fill(QuestStyle.screenBg))
    }

    // One step of the vertical timeline. Shows a shimmering placeholder until the text arrives.
    private func timelineRow(icon: String,
                             top: Color,
                             bottom: Color,
                             iconColor: Color,
                             label: String,
                             lineTo: Color,
                             text: String?,
                             showLine: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                // Gradient node with a soft ring and a depth-shaded symbol
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing))

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

                if showLine {
                    Capsule()
                        .fill(LinearGradient(colors: [bottom, lineTo], startPoint: .top, endPoint: .bottom))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 6)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(iconColor)

                if let text {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(QuestStyle.title)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                } else {
                    QuestSkeletonLines()
                }
            }
            .padding(.top, 6)
            .padding(.bottom, showLine ? 24 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Loading placeholder
struct QuestSkeletonLines: View {
    @State private var dim = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 5).frame(height: 12)
            RoundedRectangle(cornerRadius: 5).frame(height: 12)
            RoundedRectangle(cornerRadius: 5).frame(width: 120, height: 12)
        }
        .foregroundColor(Color.black.opacity(0.08))
        .opacity(dim ? 0.45 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                dim = true
            }
        }
    }
}

// MARK: - Slide to confirm
struct QuestSlideButton: View {
    let title: String
    var onComplete: () -> Void

    @State private var drag: CGFloat = 0
    @State private var completed = false

    private let height: CGFloat = 60
    private let knob: CGFloat = 50
    private let inset: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let maxDrag = max(1, geo.size.width - knob - inset * 2)
            let fraction = min(1, max(0, drag / maxDrag))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(QuestStyle.deepGreen)

                // Lighter trail behind the knob
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: inset * 2 + knob + drag)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(1 - 0.7 * Double(fraction)))
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knob * 0.5)

                ZStack {
                    Circle()
                        .fill(Color(red: 252/255, green: 248/255, blue: 240/255))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

                    Image(systemName: completed ? "checkmark" : "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
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
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    drag = maxDrag
                                    completed = true
                                }
                                onComplete()

                                // Reset while the next page is covering the screen
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    drag = 0
                                    completed = false
                                }
                            } else {
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
    }
}
