//
//  RelaxScreen.swift
//  Moko
//
//  Relax tab: breathing timer card + guided sessions grid.
//  Session cards open a 75%-height detail sheet; Continue dismisses the sheet and pushes
//  the selected exercise onto the Relax navigation stack.
//

import SwiftUI

enum RelaxSession: String, CaseIterable, Identifiable {
    case boxBreathing
    case grounding
    case imagery
    case mirror

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boxBreathing: return "Box Breathing"
        case .grounding:    return "Grounding"
        case .imagery:      return "Imagery"
        case .mirror:       return "Mirror"
        }
    }

    var cardDescription: String {
        switch self {
        case .boxBreathing: return "Breathe in, hold, breathe out, and repeat slowly."
        case .grounding:    return "Use senses to focus on the present."
        case .imagery:      return "Breathing and guided imagery paired together"
        case .mirror:       return "Breathing and guided imagery paired together"
        }
    }

    /// Paragraph shown in the full-height sheet. Box Breathing matches the design; the rest is placeholder copy.
    var detailText: String {
        switch self {
        case .boxBreathing:
            return "Breathe in for 4 seconds, hold for 4 seconds. Breathe out for 4 seconds, hold for 4 seconds. Repeat this cycle for 2–3 minutes, breathing comfortably at your own pace."
        case .grounding:
            return "Notice 5 things you can see, 4 you can feel, 3 you can hear, 2 you can smell and 1 you can taste. Take your time with each one and breathe slowly."
        case .imagery:
            return "Close your eyes and picture a calm, safe place in detail. Breathe slowly as you explore what you see, hear and feel there."
        case .mirror:
            return "Look at yourself in the mirror and relax your face. Breathe slowly and steadily, and say something kind to yourself."
        }
    }

    /// Name of the illustration in Assets.xcassets (falls back to a placeholder if missing).
    var bannerImageName: String {
        switch self {
        case .boxBreathing: return "relax_box_breathing"
        case .grounding:    return "relax_grounding"
        case .imagery:      return "relax_imagery"
        case .mirror:       return "relax_mirror"
        }
    }

    /// Banner background gradient for the sheet. Change these per session.
    var bannerColors: (top: Color, bottom: Color) {
        switch self {
        case .boxBreathing:
            return (Color(red: 232/255, green: 242/255, blue: 255/255), Color(red: 208/255, green: 226/255, blue: 248/255)) // blue
        case .grounding:
            return (Color(red: 232/255, green: 246/255, blue: 236/255), Color(red: 203/255, green: 230/255, blue: 211/255)) // green
        case .imagery:
            return (Color(red: 255/255, green: 240/255, blue: 228/255), Color(red: 250/255, green: 222/255, blue: 200/255)) // peach
        case .mirror:
            return (Color(red: 240/255, green: 234/255, blue: 252/255), Color(red: 222/255, green: 212/255, blue: 244/255)) // lavender
        }
    }

    // Placeholder copy (no longer used by the session sheet)
    var steps: [String] {
        switch self {
        case .boxBreathing:
            return ["Breathe in for 4 seconds",
                    "Hold for 4 seconds",
                    "Breathe out for 4 seconds",
                    "Hold for 4 seconds, then repeat"]
        case .grounding:
            return ["Notice 5 things you can see",
                    "Notice 4 things you can feel",
                    "Notice 3 things you can hear",
                    "Notice 2 things you can smell, and 1 you can taste"]
        case .imagery:
            return ["Get comfortable and close your eyes",
                    "Picture a calm, safe place in detail",
                    "Breathe slowly as you explore it"]
        case .mirror:
            return ["Look at yourself and relax your face",
                    "Breathe slowly and steadily",
                    "Say something kind to yourself"]
        }
    }
}

private enum ActiveRelaxSheet: Identifiable {
    case breathing
    case session(RelaxSession)

    var id: String {
        switch self {
        case .breathing: return "breathing"
        case .session(let session): return "session-\(session.id)"
        }
    }
}

/// All destinations in the Relax and imagery journey share one NavigationStack.
enum RelaxRoute: Hashable {
    case breathing(Int)
    case session(RelaxSession)
    case guideDetail(ImageryGuide)
    case guideSession(ImageryGuide)
    case guideComplete(ImageryGuide)
    case mirrorPrep(camera: Bool)
    case mirrorTimer(camera: Bool)
    case mirrorComplete(camera: Bool)
}

struct RelaxScreen: View {
    // Optional callbacks fired when the user opens a session
    var onStartBreathing: ((Int) -> Void)? = nil          // chosen minutes
    var onStartSession: ((RelaxSession) -> Void)? = nil

    @Binding var selectedTab: MokoTab

    init(selectedTab: Binding<MokoTab> = .constant(.relax), onStartBreathing: ((Int) -> Void)? = nil, onStartSession: ((RelaxSession) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.onStartBreathing = onStartBreathing
        self.onStartSession = onStartSession
    }

    @State private var minutes: Int = 1
    @State private var boxBreathingCycles: Int = 2
    @State private var activeSheet: ActiveRelaxSheet?
    @State private var pendingBreathing = false   // push the timer only after the sheet has closed
    @State private var pendingSessionNavigation: RelaxSession?
    @State private var navigationPath: [RelaxRoute] = []

    // Palette matching design specifications
    private let screenBg = Color(red: 246/255, green: 250/255, blue: 232/255) // pale lime
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)   // #365948
    private let titleBrown = Color(red: 92/255, green: 67/255, blue: 48/255)
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762
    private let stepperBg = Color(red: 237/255, green: 237/255, blue: 237/255)  // #EDEDED

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    breathingCard

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Guided Sessions")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(titleBrown)

                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            ForEach(RelaxSession.allCases) { session in
                                sessionCard(session)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(screenBg)
            .navigationTitle("Relax")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $activeSheet, onDismiss: {
                if pendingBreathing {
                    pendingBreathing = false
                    navigationPath.append(.breathing(minutes))
                }
                if let session = pendingSessionNavigation {
                    pendingSessionNavigation = nil
                    navigationPath.append(.session(session))
                }
            }) { sheet in
                Group {
                    switch sheet {
                    case .breathing:
                        breathingSheet
                    case .session(let session):
                        RelaxSessionSheet(
                            session: session,
                            boxBreathingCycles: $boxBreathingCycles,
                            onContinue: {
                                pendingSessionNavigation = session
                                activeSheet = nil
                            }
                        )
                    }
                }
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .navigationDestination(for: RelaxRoute.self) { route in
                routeDestination(route)
            }
        }
        .tint(cardGreen)
    }

    @ViewBuilder
    private func routeDestination(_ route: RelaxRoute) -> some View {
        switch route {
        case .breathing(let duration):
            BreathingSessionScreen(minutes: duration, onFinish: { popRelaxRoute() })

        case .session(let session):
            switch session {
            case .imagery:
                ImageryGuideListView { guide in
                    navigationPath.append(.guideDetail(guide))
                }

            case .boxBreathing:
                BoxBreathingView(
                    initialCycles: boxBreathingCycles,
                    onComplete: { popRelaxRoute() }
                )

            case .grounding:
                GroundingExerciseScreen(
                    onExit: { popRelaxRoute() },
                    onContinue: { popRelaxRoute() }
                )

            case .mirror:
                MirrorReflectionScreen(onSelectOption: { option in
                    navigationPath.append(.mirrorPrep(camera: option == .camera))
                })
                .navigationTitle("Mirror Reflection")
                .navigationBarTitleDisplayMode(.inline)
            }

        case .guideDetail(let guide):
            ImageryGuideDetailView(guide: guide)
                .navigationBarTitleDisplayMode(.inline)

        case .guideSession(let guide):
            GuideSessionView(guide: guide) {
                navigationPath.append(.guideComplete(guide))
            }
            .navigationTitle(guide.title)
            .navigationBarTitleDisplayMode(.inline)

        case .guideComplete(let guide):
            SessionCompleteView(message: guide.completionMessage) {
                // Keep the imagery gallery on the stack and return to it.
                if navigationPath.count >= 3 {
                    navigationPath.removeLast(3)
                } else {
                    navigationPath.removeAll()
                }
            }
            .navigationTitle("Session complete")
            .navigationBarTitleDisplayMode(.inline)

        case .mirrorPrep(let camera):
            mirrorPrepDestination(camera: camera)
                .navigationTitle("Get ready")
                .navigationBarTitleDisplayMode(.inline)

        case .mirrorTimer(let camera):
            if camera {
                CameraTimerScreen(
                    onBack: {},
                    onContinue: { navigationPath.append(.mirrorComplete(camera: true)) }
                )
                .navigationTitle("Mirror Reflection")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                MirrorTimerScreen(
                    onBack: {},
                    onContinue: { navigationPath.append(.mirrorComplete(camera: false)) }
                )
                .navigationTitle("Mirror Reflection")
                .navigationBarTitleDisplayMode(.inline)
            }

        case .mirrorComplete(_):
            MirrorCompletionScreen(onDone: {
                if navigationPath.count >= 3 { navigationPath.removeLast(3) }
                else { navigationPath.removeAll() }
            })
                .navigationTitle("Completed")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func mirrorPrepDestination(camera: Bool) -> some View {
        if camera {
            MirrorPrepScreen(
                title: "Get ready with your iPhone",
                listTitle: "Your setup",
                items: [
                    "Find a comfortable spot",
                    "Hold your phone comfortably",
                    "Look at yourself gently",
                    "Let go of judgement"
                ],
                onBack: {},
                onContinue: { navigationPath.append(.mirrorTimer(camera: true)) }
            ) { level in
                CameraPhoneHero(level: level)
                    .scaleEffect(0.72)
                    .frame(height: 230)
            }
        } else {
            MirrorPrepScreen(
                title: "Arrive in Front of Your Mirror",
                items: [
                    "Find a comfortable spot",
                    "Take a gentle breath",
                    "Look at yourself kindly",
                    "Let go of judgement"
                ],
                onBack: {},
                onContinue: { navigationPath.append(.mirrorTimer(camera: false)) }
            ) { level in
                MirrorHero(showCaption: false, level: level)
                    .scaleEffect(0.72)
                    .frame(height: 220)
            }
        }
    }

    private func popRelaxRoute() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    // MARK: - Breathing Card
    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Tapping the title / text area opens the breathing sheet
            Button {
                activeSheet = .breathing
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        Text("Breathing")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(cardGreen)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }

                    Text("Set your own meditation timer for a calmer mind")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(subtextGray)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 240, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Minutes stepper (outside the link, so +/- never navigate)
            HStack(spacing: 18) {
                stepperButton(systemName: "minus", enabled: minutes > 1) {
                    minutes = max(1, minutes - 1)
                }

                Text("\(minutes) min")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .monospacedDigit()
                    .frame(minWidth: 44)

                stepperButton(systemName: "plus", enabled: minutes < 60) {
                    minutes = min(60, minutes + 1)
                }
            }
            .padding(.top, 20)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(alignment: .bottomTrailing) {
            BreathingDotsIcon(color: cardGreen)
                .frame(width: 80, height: 80)
                .padding(20)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private func stepperButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(enabled ? .black : .black.opacity(0.3))
                .frame(width: 38, height: 38)
                .background(Circle().fill(stepperBg))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Session Card
    private func sessionCard(_ session: RelaxSession) -> some View {
        Button {
            activeSheet = .session(session)
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(session.title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(cardGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }

                Spacer(minLength: 8)

                sessionIcon(session)
                    .frame(height: 44)

                Spacer(minLength: 8)

                Text(session.cardDescription)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(subtextGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, minHeight: 190)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sessionIcon(_ session: RelaxSession) -> some View {
        RelaxSessionIcon(session: session, color: cardGreen)
    }


    // MARK: - Breathing sheet
    private var breathingSheet: some View {
        RelaxDetailSheet(
            title: "Breathing",
            subtitle: "Set your own meditation timer for a calmer mind",
            steps: ["Sit comfortably and relax your shoulders",
                    "Breathe in slowly through your nose",
                    "Breathe out gently and let go of tension"],
            buttonTitle: "Start",
            onStart: {
                pendingBreathing = true
                onStartBreathing?(minutes)
            },
            icon: { BreathingDotsIcon(color: cardGreen).frame(width: 64, height: 64) },
            extra: {
                HStack(spacing: 18) {
                    stepperButton(systemName: "minus", enabled: minutes > 1) {
                        minutes = max(1, minutes - 1)
                    }
                    Text("\(minutes) min")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .frame(minWidth: 60)
                    stepperButton(systemName: "plus", enabled: minutes < 60) {
                        minutes = min(60, minutes + 1)
                    }
                }
            }
        )
    }
}

// MARK: - Bottom sheet content
struct RelaxDetailSheet<Icon: View, Extra: View>: View {
    let title: String
    let subtitle: String
    let steps: [String]
    let buttonTitle: String
    let onStart: () -> Void
    private let icon: Icon
    private let extra: Extra

    @Environment(\.dismiss) private var dismiss

    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let primaryGreen = Color(red: 27/255, green: 66/255, blue: 47/255)
    private let titleBrown = Color(red: 92/255, green: 67/255, blue: 48/255)
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)

    init(title: String,
         subtitle: String,
         steps: [String],
         buttonTitle: String,
         onStart: @escaping () -> Void,
         @ViewBuilder icon: () -> Icon,
         @ViewBuilder extra: () -> Extra) {
        self.title = title
        self.subtitle = subtitle
        self.steps = steps
        self.buttonTitle = buttonTitle
        self.onStart = onStart
        self.icon = icon()
        self.extra = extra()
    }

    var body: some View {
        VStack(spacing: 0) {
            icon
                .frame(height: 64)
                .padding(.top, 28)

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(titleBrown)
                .padding(.top, 14)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(subtextGray)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .padding(.horizontal, 24)

            extra
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(cardGreen))
                        Text(step)
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.horizontal, 28)

            Spacer(minLength: 12)

            Button {
                onStart()
                dismiss()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(primaryGreen))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session detail sheet (illustration, text, Continue / Not now)

struct RelaxSessionSheet: View {
    let session: RelaxSession
    @Binding var boxBreathingCycles: Int
    var onContinue: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private let primaryGreen = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)

    var body: some View {
        Group {
            if session == .boxBreathing {
                BoxBreathingInfoView(
                    cycles: $boxBreathingCycles,
                    onContinue: onContinue,
                    onNotNow: { dismiss() }
                )
            } else {
                standardContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var standardContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                banner

                Text(session.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(red: 92/255, green: 67/255, blue: 48/255))
                    .padding(.top, 24)

                Text(session.detailText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(subtextGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.top, 14)
                    .padding(.horizontal, 28)

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(primaryGreen))
                }
                .buttonStyle(.plain)
                .padding(.top, 32)
                .padding(.horizontal, 28)

                Button {
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(primaryGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.white)
        .ignoresSafeArea(edges: .top)      // banner runs under the transparent back-button bar
    }

    private var banner: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background {
                LinearGradient(
                    colors: [session.bannerColors.top, session.bannerColors.bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                RelaxSessionIcon(session: session, color: primaryGreen.opacity(0.6), size: 96)
            }
            .overlay {
                Image(session.bannerImageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }
}

// Stand-in for the sessions whose screens aren't built yet
struct RelaxSessionPlaceholderScreen: View {
    let session: RelaxSession

    private let screenBg = Color(red: 246/255, green: 250/255, blue: 232/255)
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let titleDark = Color(red: 92/255, green: 67/255, blue: 48/255)
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)
    private let mint = Color(red: 226/255, green: 245/255, blue: 177/255)

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(mint.opacity(0.7))
                        .frame(width: 140, height: 140)
                    RelaxSessionIcon(session: session, color: cardGreen, size: 56)
                }

                Text(session.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(titleDark)
                    .padding(.top, 28)

                Text("This practice is coming soon.")
                    .font(.system(size: 16))
                    .foregroundColor(subtextGray)
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Icon for each session (used by the card and the sheet banner)
struct RelaxSessionIcon: View {
    let session: RelaxSession
    var color: Color
    var size: CGFloat = 38

    var body: some View {
        switch session {
        case .boxBreathing:
            BoxBreathingIcon(color: color)
                .scaleEffect(size / 38)
        case .grounding:
            Image(systemName: "5.square")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color)
        case .imagery:
            Image(systemName: "photo.tv")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color)
        case .mirror:
            Image(systemName: "person.crop.square")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color)
        }
    }
}

// MARK: - Box Breathing Icon (rounded square inside corner brackets)
struct BoxBreathingIcon: View {
    var color: Color

    var body: some View {
        ZStack {
            Image(systemName: "viewfinder")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(color)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color, lineWidth: 3)
                .frame(width: 20, height: 20)
        }
    }
}

// MARK: - Breathing Dot Pattern (concentric rings of dots)
struct BreathingDotsIcon: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let unit = min(geo.size.width, geo.size.height) / 80

            ZStack {
                dot(size: 11 * unit, at: c)

                ForEach(Array(0..<6), id: \.self) { i in
                    dot(size: 9 * unit, at: point(center: c, radius: 17 * unit, index: i, count: 6))
                }

                ForEach(Array(0..<12), id: \.self) { i in
                    dot(size: (i % 2 == 0 ? 6.5 : 4.5) * unit,
                        at: point(center: c, radius: 33 * unit, index: i, count: 12))
                }
            }
        }
    }

    private func dot(size: CGFloat, at p: CGPoint) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(p)
    }

    private func point(center: CGPoint, radius: CGFloat, index: Int, count: Int) -> CGPoint {
        let angle = (Double(index) / Double(count)) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
        )
    }
}

#Preview {
    RelaxScreen()
}
