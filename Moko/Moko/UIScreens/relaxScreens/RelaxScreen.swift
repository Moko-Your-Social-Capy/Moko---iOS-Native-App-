//
//  RelaxScreen.swift
//  Moko
//
//  The Relax tab: a "Breathing" timer card on top and a grid of guided sessions.
//
//  How navigation works here (good place to start debugging):
//  1. Tapping a card sets `activeSheet`, which opens a bottom sheet.
//  2. Tapping Continue/Start in the sheet remembers what to open next
//     (`pendingBreathing` / `pendingSessionNavigation`) and closes the sheet.
//  3. When the sheet has fully closed, `onDismiss` pushes that screen onto
//     `navigationPath`. Pushing while the sheet is still open would glitch.
//  4. `routeDestination(_:)` turns each `RelaxRoute` into a real screen.
//

import SwiftUI

/// The four guided sessions shown in the grid.
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

    /// Short text on the grid card.
    var cardDescription: String {
        switch self {
        case .boxBreathing: return "Breathe in, hold, breathe out, and repeat slowly."
        case .grounding:    return "Use senses to focus on the present."
        case .imagery:      return "Breathing and guided imagery paired together"
        case .mirror:       return "Look at yourself kindly and breathe slowly."
        }
    }

    /// Longer text shown in the session sheet.
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

    /// Illustration name in Assets.xcassets. If it is missing, the icon behind it shows instead.
    var bannerImageName: String {
        switch self {
        case .boxBreathing: return "relax_box_breathing"
        case .grounding:    return "relax_grounding"
        case .imagery:      return "relax_imagery"
        case .mirror:       return "relax_mirror"
        }
    }

    /// Top and bottom colours of the sheet banner gradient.
    var bannerColors: (top: Color, bottom: Color) {
        switch self {
        case .boxBreathing:
            return (MokoScreenTheme.Colors.accentBlueTint, MokoScreenTheme.Colors.surfaceLavender)
        case .grounding:
            return (MokoScreenTheme.Colors.canvasTop, MokoScreenTheme.Colors.canvasBottom)
        case .imagery:
            return (MokoScreenTheme.Colors.surfaceWhite, MokoScreenTheme.Colors.canvasBottom)
        case .mirror:
            return (MokoScreenTheme.Colors.surfaceLavender, MokoScreenTheme.Colors.avatarFill)
        }
    }
}

/// Which bottom sheet is open. `Identifiable` lets us use `.sheet(item:)`.
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

/// Every screen you can push from the Relax tab. They all share one NavigationStack.
enum RelaxRoute: Hashable {
    case breathing(Int)                 // minutes
    case boxBreathing(cycles: Int)      // cycles picked in the sheet, carried on the route
    case session(RelaxSession)
    case guideSession(ImageryGuide)
    case guideComplete(ImageryGuide)
    case mirrorPrep(camera: Bool)       // camera: true = front camera, false = real mirror
    case mirrorTimer(camera: Bool)
    case mirrorComplete(camera: Bool)
}

struct RelaxScreen: View {
    // Minutes for the Breathing timer (1–60).
    @State private var minutes: Int = 1
    // Cycles for Box Breathing, picked in its info sheet.
    @State private var boxBreathingCycles: Int = 2
    // The open bottom sheet, or nil when none is open.
    @State private var activeSheet: ActiveRelaxSheet?
    // Screens to push once the sheet has finished closing (see step 3 at the top).
    @State private var pendingBreathing = false
    @State private var pendingSessionNavigation: RelaxSession?
    // The stack of pushed screens. Appending pushes, removing pops.
    @State private var navigationPath: [RelaxRoute] = []
    // Imagery guides store. Created here and shared below with `.environment`.
    @State private var imageryStore = ImageryGuideStore()

    // Reads the user's text size so the grid can drop to one column for very large text.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let accent = MokoScreenTheme.Colors.dataVioletDeep
    private let ink = MokoScreenTheme.Colors.textTitle
    private let bodyText = MokoScreenTheme.Colors.textBody
    private let stepperFill = MokoScreenTheme.Colors.surfaceLavender

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: MokoScreenTheme.Space.gapCard),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
        )
    }

    var body: some View {
        // `path:` lets us push and pop screens from code by editing `navigationPath`.
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    breathingCard
                        .padding(.horizontal, MokoScreenTheme.Space.page)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Guided Sessions")
                            .mokoText(MokoScreenTheme.Typeface.title2)
                            .foregroundStyle(ink)

                        LazyVGrid(columns: gridColumns, spacing: MokoScreenTheme.Space.gapCard) {
                            ForEach(RelaxSession.allCases) { session in
                                sessionCard(session)
                            }
                        }
                    }
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                }
                .padding(.bottom, 24)
            }
            .background { MokoBackdrop() }
            // Same header style as the Overview, Quests and Quest Library tabs.
            .navigationTitle("Relax")
            .toolbar(.hidden, for: .navigationBar)
            // Opens whenever `activeSheet` is set. `onDismiss` runs after it has fully closed.
            .sheet(item: $activeSheet, onDismiss: pushPendingScreen) { sheet in
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
                .presentationDetents([.fraction(0.80)])   // sheet covers 80% of the screen
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            // Tells the stack which screen to build for each `RelaxRoute`.
            .navigationDestination(for: RelaxRoute.self) { route in
                routeDestination(route)
            }
        }
        .tint(accent)
        // Lets every Imagery screen read the same store with `@Environment(ImageryGuideStore.self)`.
        .environment(imageryStore)
    }

    // MARK: - Navigation

    /// Runs after a sheet closes. Pushes the screen the user asked for, if any.
    private func pushPendingScreen() {
        if pendingBreathing {
            pendingBreathing = false
            navigationPath.append(.breathing(minutes))
        }
        if let session = pendingSessionNavigation {
            pendingSessionNavigation = nil
            if session == .boxBreathing {
                // The picked cycle count travels on the route itself, so the session
                // always starts with exactly the number the sheet showed.
                navigationPath.append(.boxBreathing(cycles: boxBreathingCycles))
            } else {
                navigationPath.append(.session(session))
            }
        }
    }

    /// Builds the screen for one route.
    @ViewBuilder
    private func routeDestination(_ route: RelaxRoute) -> some View {
        switch route {
        case .breathing(let duration):
            BreathingSessionScreen(minutes: duration, onFinish: { popRelaxRoute() })

        case .boxBreathing(let cycles):
            BoxBreathingView(
                initialCycles: cycles,
                onComplete: { popRelaxRoute() }
            )

        case .session(let session):
            switch session {
            case .imagery:
                ImageryGuideListView { guide in
                    navigationPath.append(.guideSession(guide))
                }

            case .boxBreathing:
                // Box breathing is pushed via `.boxBreathing(cycles:)` above; kept only
                // so the switch stays exhaustive.
                BoxBreathingView(
                    initialCycles: boxBreathingCycles,
                    onComplete: { popRelaxRoute() }
                )

            case .grounding:
                GroundingExerciseScreen(onContinue: { popRelaxRoute() })

            case .mirror:
                MirrorReflectionScreen(onSelectOption: { option in
                    navigationPath.append(.mirrorPrep(camera: option == .camera))
                })
                .navigationBarTitleDisplayMode(.inline)
            }

        case .guideSession(let guide):
            GuideSessionView(guide: guide) {
                navigationPath.append(.guideComplete(guide))
            }
            .navigationTitle(guide.title)
            .navigationBarTitleDisplayMode(.inline)

        case .guideComplete(let guide):
            SessionCompleteView(message: guide.completionMessage) {
                // Pop the "complete" and "session" screens to land back on the Imagery list.
                popRelaxRoutes(2)
            }
            .navigationTitle(imageryStore.screen?.sessionCompleteNavigationTitle ?? "")
            .navigationBarTitleDisplayMode(.inline)

        case .mirrorPrep(let camera):
            mirrorPrepDestination(camera: camera)
                .navigationBarTitleDisplayMode(.inline)

        case .mirrorTimer(let camera):
            Group {
                if camera {
                    CameraTimerScreen(
                        onContinue: { navigationPath.append(.mirrorComplete(camera: true)) }
                    )
                } else {
                    MirrorTimerScreen(
                        onContinue: { navigationPath.append(.mirrorComplete(camera: false)) }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)

        case .mirrorComplete:
            MirrorCompletionScreen(onDone: {
                // Pop complete, timer and prep to land back on the Mirror options screen.
                popRelaxRoutes(3)
            })
            .navigationTitle("Completed")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// The "get ready" checklist before the mirror timer. Text depends on camera vs mirror.
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
                onContinue: { navigationPath.append(.mirrorTimer(camera: false)) }
            ) { level in
                MirrorHero(level: level)
                    .scaleEffect(0.72)
                    .frame(height: 220)
            }
        }
    }

    /// Goes back one screen.
    private func popRelaxRoute() {
        popRelaxRoutes(1)
    }

    /// Goes back `count` screens. If there are fewer, goes back to the Relax tab itself.
    private func popRelaxRoutes(_ count: Int) {
        if navigationPath.count >= count {
            navigationPath.removeLast(count)
        } else {
            navigationPath.removeAll()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Relax")
            .mokoText(MokoScreenTheme.Typeface.title1)
            .foregroundStyle(ink)
            .padding(.horizontal, MokoScreenTheme.Space.page)
            .padding(.top, 14)
    }

    // MARK: - Breathing card

    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tapping the title or text opens the breathing sheet.
            Button {
                activeSheet = .breathing
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        Text("Breathing")
                            .mokoText(MokoScreenTheme.Typeface.section)
                            .foregroundStyle(accent)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ink)
                    }

                    Text("Set your own meditation timer for a calmer mind")
                        .mokoText(MokoScreenTheme.Typeface.body)
                        .foregroundStyle(bodyText)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 240, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Makes the empty space inside the label tappable too.
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // The stepper sits outside the button above, so tapping + or − never opens the sheet.
            minutesStepper(style: MokoScreenTheme.Typeface.slider, labelWidth: 44)
                .padding(.top, 20)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomTrailing) {
            BreathingDotsIcon(color: accent)
                .frame(width: 56, height: 56)
                .padding(20)
                .allowsHitTesting(false)   // decoration only: taps pass through it
        }
        .mokoCard()
    }

    /// The "−  5 min  +" control. Used on the card and in the breathing sheet.
    private func minutesStepper(style: MokoScreenTheme.TextStyle, labelWidth: CGFloat) -> some View {
        HStack(spacing: 18) {
            stepperButton(systemName: "minus", enabled: minutes > 1) {
                minutes = max(1, minutes - 1)
            }

            Text("\(minutes) min")
                .mokoText(style)
                .foregroundStyle(ink)
                .monospacedDigit()   // digits all the same width, so the text does not jump
                .frame(minWidth: labelWidth)

            stepperButton(systemName: "plus", enabled: minutes < 60) {
                minutes = min(60, minutes + 1)
            }
        }
    }

    private func stepperButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? ink : MokoScreenTheme.Colors.textMuted)
                .frame(width: 44, height: 44)
                .background(Circle().fill(stepperFill))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(systemName == "minus" ? "Decrease minutes" : "Increase minutes")
    }

    // MARK: - Session card

    private func sessionCard(_ session: RelaxSession) -> some View {
        Button {
            activeSheet = .session(session)
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(session.title)
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(accent)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ink)
                }

                Spacer(minLength: 8)

                RelaxSessionIcon(session: session, color: accent)
                    .frame(height: 44)

                Spacer(minLength: 8)

                Text(session.cardDescription)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(bodyText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    // Lets the text wrap onto more lines instead of being cut off with "…".
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, minHeight: 190)
            .mokoCard()
        }
        .buttonStyle(.plain)
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
            onStart: { pendingBreathing = true },
            icon: { BreathingDotsIcon(color: accent).frame(width: 64, height: 64) },
            extra: { minutesStepper(style: MokoScreenTheme.Typeface.cardTitle, labelWidth: 60) }
        )
    }
}

// MARK: - Breathing sheet layout

/// A sheet with an icon, title, subtitle, a custom `extra` view, numbered steps and a button.
/// `Icon` and `Extra` are generic, so the caller can pass any view without `AnyView`.
struct RelaxDetailSheet<Icon: View, Extra: View>: View {
    let title: String
    let subtitle: String
    let steps: [String]
    let buttonTitle: String
    let onStart: () -> Void
    private let icon: Icon
    private let extra: Extra

    // Closes this sheet.
    @Environment(\.dismiss) private var dismiss

    private let accent = MokoScreenTheme.Colors.dataVioletDeep

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
        ScrollView {
            VStack(spacing: 0) {
                icon
                    .frame(height: 64)
                    .padding(.top, 28)

                Text(title)
                    .mokoText(MokoScreenTheme.Typeface.title2)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    .padding(.top, 14)

                Text(subtitle)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, MokoScreenTheme.Space.page)

                extra
                    .padding(.top, 16)

                // Numbered steps: a small filled circle with the number, then the text.
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .mokoText(MokoScreenTheme.Typeface.caption)
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(accent))
                            Text(step)
                                .mokoText(MokoScreenTheme.Typeface.body)
                                .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.horizontal, MokoScreenTheme.Space.page)

                Spacer(minLength: 12)

                Button {
                    onStart()
                    dismiss()
                } label: {
                    Text(buttonTitle)
                        .mokoText(MokoScreenTheme.Typeface.slider)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: MokoScreenTheme.Control.trackHeight)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .background { MokoBackdrop() }
    }
}

// MARK: - Session sheet (illustration, text, Continue / Not now)

/// The sheet for a guided session. Box Breathing has its own sheet with a cycle picker.
struct RelaxSessionSheet: View {
    let session: RelaxSession
    // @Binding: the cycle count lives in RelaxScreen, so it survives the sheet closing.
    @Binding var boxBreathingCycles: Int
    var onContinue: () -> Void = {}

    // Closes this sheet.
    @Environment(\.dismiss) private var dismiss

    private let accent = MokoScreenTheme.Colors.dataVioletDeep

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
                    .mokoText(MokoScreenTheme.Typeface.title2)
                    .foregroundStyle(MokoScreenTheme.Colors.textTitle)
                    .padding(.top, 24)

                Text(session.detailText)
                    .mokoText(MokoScreenTheme.Typeface.body)
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.top, 14)
                    .padding(.horizontal, 28)

                Button(action: onContinue) {
                    Text("Continue")
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 32)
                .padding(.horizontal, 28)

                Button {
                    dismiss()
                } label: {
                    Text("Not now")
                        .mokoText(MokoScreenTheme.Typeface.cardTitle)
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        // Only bounce when the content is taller than the sheet.
        .scrollBounceBehavior(.basedOnSize)
        .background { MokoBackdrop() }
        // Let the banner run up to the very top edge of the sheet.
        .ignoresSafeArea(edges: .top)
    }

    /// Gradient + icon, with the illustration on top. If the image is missing, the icon shows through.
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
                RelaxSessionIcon(session: session, color: accent.opacity(0.6), size: 96)
            }
            .overlay {
                Image(session.bannerImageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }
}

// MARK: - Session icons

/// The icon for each session. Used on the grid card and in the sheet banner.
struct RelaxSessionIcon: View {
    let session: RelaxSession
    var color: Color
    var size: CGFloat = 38

    var body: some View {
        switch session {
        case .boxBreathing:
            BoxBreathingIcon(color: color)
                .scaleEffect(size / 38)   // the icon is drawn at 38 pt, so scale it to `size`
        case .grounding:
            symbol("5.square")
        case .imagery:
            symbol("photo.tv")
        case .mirror:
            symbol("person.crop.square")
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(color)
    }
}

/// A small rounded square inside corner brackets.
struct BoxBreathingIcon: View {
    var color: Color

    var body: some View {
        ZStack {
            Image(systemName: "viewfinder")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(color)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color, lineWidth: 3)
                .frame(width: 20, height: 20)
        }
    }
}

/// One dot in the middle, a ring of 6 dots and an outer ring of 12 dots.
struct BreathingDotsIcon: View {
    var color: Color

    var body: some View {
        // GeometryReader gives us the space we have, so the pattern scales to any frame.
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            // The pattern was designed on an 80 x 80 grid. `unit` scales it to the real size.
            let unit = min(geo.size.width, geo.size.height) / 80

            ZStack {
                dot(size: 11 * unit, at: center)

                ForEach(0..<6, id: \.self) { i in
                    dot(size: 9 * unit, at: point(center: center, radius: 17 * unit, index: i, count: 6))
                }

                ForEach(0..<12, id: \.self) { i in
                    dot(size: (i % 2 == 0 ? 6.5 : 4.5) * unit,
                        at: point(center: center, radius: 33 * unit, index: i, count: 12))
                }
            }
        }
    }

    private func dot(size: CGFloat, at position: CGPoint) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(position)
    }

    /// Point number `index` of `count` points spaced evenly on a circle, starting at the top.
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
