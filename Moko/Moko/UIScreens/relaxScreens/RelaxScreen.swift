//
//  RelaxScreen.swift
//  Moko
//
//  Relax tab: breathing timer card + guided sessions grid.
//  The breathing card and every session card open a bottom sheet.
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

private enum RelaxSheet: Identifiable {
    case breathing
    case session(RelaxSession)

    var id: String {
        switch self {
        case .breathing:        return "breathing"
        case .session(let s):   return s.id
        }
    }
}

private enum RelaxFullScreen: Identifiable {
    case breathing

    var id: String {
        switch self {
        case .breathing: return "breathing"
        }
    }
}

struct RelaxScreen: View {
    // Optional callbacks fired when the user taps Start in a sheet
    var onStartBreathing: ((Int) -> Void)? = nil          // chosen minutes
    var onStartSession: ((RelaxSession) -> Void)? = nil

    // MARK: - State Properties
    @State private var selectedTab: MokoTab = .relax
    @State private var minutes: Int = 1
    @State private var activeSheet: RelaxSheet?
    @State private var pendingFullScreen: RelaxFullScreen?
    @State private var fullScreen: RelaxFullScreen?

    // Palette matching design specifications
    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)   // #365948
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762
    private let stepperBg = Color(red: 237/255, green: 237/255, blue: 237/255)  // #EDEDED

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            screenBg
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    Text("Relax")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // MARK: - Breathing Timer Card
                    breathingCard
                        .padding(.top, 20)
                        .padding(.horizontal, 16)

                    // MARK: - Guided Sessions
                    Text("Guided Sessions")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 28)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(RelaxSession.allCases) { session in
                            sessionCard(session)
                        }
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110) // space for floating tab bar
                }
            }

            // MARK: - Floating Tab Bar
            MokoTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
        .sheet(item: $activeSheet, onDismiss: {
            // Open the next screen only after the sheet has fully closed
            if let next = pendingFullScreen {
                pendingFullScreen = nil
                fullScreen = next
            }
        }) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $fullScreen) { destination in
            switch destination {
            case .breathing:
                BreathingSessionScreen(minutes: minutes)
            }
        }
    }

    // MARK: - Breathing Card
    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                .frame(maxWidth: 240, alignment: .leading)
                .padding(.top, 10)

            // Minutes stepper: + increases, - decreases
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
            .padding(.top, 22)
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
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Tapping the card opens the sheet; the +/- buttons take priority over this
        .onTapGesture {
            activeSheet = .breathing
        }
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
            .frame(maxWidth: .infinity)
            .frame(height: 190)
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

    // MARK: - Bottom sheets
    @ViewBuilder
    private func sheetContent(for sheet: RelaxSheet) -> some View {
        switch sheet {
        case .breathing:
            RelaxDetailSheet(
                title: "Breathing",
                subtitle: "Set your own meditation timer for a calmer mind",
                steps: ["Sit comfortably and relax your shoulders",
                        "Breathe in slowly through your nose",
                        "Breathe out gently and let go of tension"],
                buttonTitle: "Start \(minutes) min session",
                onStart: {
                    pendingFullScreen = .breathing
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

        case .session(let session):
            RelaxSessionSheet(
                session: session,
                onContinue: { onStartSession?(session) },
                onFinishFlow: { activeSheet = nil }
            )
        }
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
                .foregroundColor(primaryGreen)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: - Full-height session sheet (illustration, text, Continue / Not now)
struct RelaxSessionSheet: View {
    let session: RelaxSession
    var onContinue: () -> Void
    /// Called when a flow reaches its end (e.g. Done). The parent closes this sheet.
    var onFinishFlow: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var showNext = false

    private let primaryGreen = Color(red: 54/255, green: 89/255, blue: 72/255)   // #365948
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)  // #6F6762

    var body: some View {
        VStack(spacing: 0) {
            banner

            Text(session.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 80)

            Text(session.detailText)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(subtextGray)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 18)
                .padding(.horizontal, 40)

            Button {
                onContinue()
                // Slide the next screen over the sheet instead of closing the sheet first
                showNext = true
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(primaryGreen))
            }
            .buttonStyle(.plain)
            .padding(.top, 36)
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
            .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        // Opens tall, to just under the status bar, like the design
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showNext) {
            RelaxSessionDestination(
                session: session,
                onExit: { showNext = false },
                // Close the sheet itself, so the flow and the sheet go away together
                onFinish: { onFinishFlow() }
            )
        }
    }

    private var banner: some View {
        // The base view fixes the banner's size. The artwork sits in overlays,
        // so a large illustration can't make the sheet's layout wider than the screen.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .background {
                LinearGradient(
                    colors: [session.bannerColors.top, session.bannerColors.bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            // Placeholder art, different for each session; the illustration
            // named in `bannerImageName` covers it once it's in Assets
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

// MARK: - Where "Continue" leads for each session
// Plug each session's real screen in here as you build it.
struct RelaxSessionDestination: View {
    let session: RelaxSession
    /// Backed out of the flow's first screen
    var onExit: () -> Void = {}
    /// Reached the end of the flow
    var onFinish: () -> Void = {}

    var body: some View {
        switch session {
        case .mirror:
            MirrorFlowView(onExit: onExit, onFinish: onFinish)
        case .boxBreathing, .grounding, .imagery:
            RelaxSessionPlaceholderScreen(session: session)
        }
    }
}

// Stand-in for the sessions whose screens aren't built yet
struct RelaxSessionPlaceholderScreen: View {
    let session: RelaxSession

    @Environment(\.dismiss) private var dismiss

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255)
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)
    private let chipBg = Color(red: 237/255, green: 237/255, blue: 237/255)
    private let mint = Color(red: 203/255, green: 230/255, blue: 211/255)

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(chipBg))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

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

                ForEach(0..<6, id: \.self) { i in
                    dot(size: 9 * unit, at: point(center: c, radius: 17 * unit, index: i, count: 6))
                }

                ForEach(0..<12, id: \.self) { i in
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
