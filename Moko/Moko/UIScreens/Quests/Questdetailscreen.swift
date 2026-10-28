//
//  QuestDetailScreen.swift
//  Moko
//
//  Opens when a quest card is tapped. Title and XP come from the quest; the briefing
//  (scene, who, goal) comes from a QuestBriefGenerating object. For now that is a
//  dummy generator; swap in an Apple Foundation Models one later.
//  Sliding "Slide to debrief" opens the debrief page.
//

import SwiftUI

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

// MARK: - Detail screen
struct QuestDetailScreen: View {
    let quest: Quest
    var generator: any QuestBriefGenerating = DummyQuestBriefGenerator()

    @Environment(\.dismiss) private var dismiss

    @State private var brief: QuestBrief?
    @State private var showingDebrief = false

    // Timeline colours
    private let sandBg = Color(red: 236/255, green: 228/255, blue: 214/255)
    private let sandIcon = Color(red: 112/255, green: 94/255, blue: 74/255)
    private let sandLabel = Color(red: 128/255, green: 112/255, blue: 92/255)
    private let roseBg = Color(red: 243/255, green: 218/255, blue: 212/255)
    private let roseIcon = Color(red: 200/255, green: 76/255, blue: 66/255)
    private let roseLabel = Color(red: 190/255, green: 84/255, blue: 70/255)
    private let lineColor = Color(red: 214/255, green: 204/255, blue: 188/255)

    var body: some View {
        ZStack {
            if showingDebrief {
                QuestDebriefScreen(quest: quest) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showingDebrief = false
                    }
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
                withAnimation(.easeInOut(duration: 0.35)) {
                    showingDebrief = true
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }

    private var card: some View {
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
                    Text("\(quest.intensity.xp) XP")
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

            // When
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(QuestFormat.dateText(quest.date)) · \(QuestFormat.timeText(quest.date))")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(QuestStyle.subtext)
            .padding(.top, 12)

            if !quest.notes.isEmpty {
                Text(quest.notes)
                    .font(.system(size: 14))
                    .italic()
                    .foregroundColor(QuestStyle.subtext)
                    .lineLimit(3)
                    .padding(.top, 10)
            }

            Rectangle()
                .fill(QuestStyle.divider)
                .frame(height: 1)
                .padding(.top, 20)
                .padding(.bottom, 22)

            // Briefing label
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Your briefing")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(QuestStyle.green)
            .padding(.bottom, 18)

            timelineRow(
                icon: "mappin.and.ellipse",
                iconBg: sandBg, iconColor: sandIcon,
                label: "THE SCENE", labelColor: sandLabel,
                text: brief?.scene, showLine: true
            )

            timelineRow(
                icon: "person.2.fill",
                iconBg: sandBg, iconColor: sandIcon,
                label: "WHO", labelColor: sandLabel,
                text: brief?.who, showLine: true
            )

            timelineRow(
                icon: "target",
                iconBg: roseBg, iconColor: roseIcon,
                label: "YOUR GOAL", labelColor: roseLabel,
                text: brief?.goal, showLine: false
            )
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
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
                             iconBg: Color,
                             iconColor: Color,
                             label: String,
                             labelColor: Color,
                             text: String?,
                             showLine: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(iconBg)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .frame(width: 48, height: 48)

                if showLine {
                    Capsule()
                        .fill(lineColor)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 6)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(labelColor)

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
            .padding(.top, 4)
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

// MARK: - Debrief page (placeholder until it's designed)
struct QuestDebriefScreen: View {
    let quest: Quest
    var onBack: () -> Void

    @State private var pulse = false

    private let micGreen = Color(red: 47/255, green: 79/255, blue: 64/255)

    var body: some View {
        ZStack {
            QuestStyle.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
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

                Text("Debrief")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                Text(quest.title)
                    .font(.system(size: 15))
                    .foregroundColor(QuestStyle.subtext)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                Spacer()

                ZStack {
                    Circle()
                        .fill(micGreen.opacity(0.14))
                        .frame(width: 190, height: 190)
                        .scaleEffect(pulse ? 1.08 : 0.94)

                    Circle()
                        .fill(micGreen)
                        .frame(width: 110, height: 110)
                        .shadow(color: micGreen.opacity(0.35), radius: 14, x: 0, y: 8)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }

                Text("Your debrief is coming soon")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(QuestStyle.title)
                    .padding(.top, 32)

                Text("This is where you’ll share how it went.")
                    .font(.system(size: 15))
                    .foregroundColor(QuestStyle.subtext)
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}