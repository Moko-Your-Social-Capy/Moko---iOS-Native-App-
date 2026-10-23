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

    // Placeholder copy for the sheets; replace with your final text.
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

struct RelaxScreen: View {
    // Optional callbacks fired when the user taps Start in a sheet
    var onStartBreathing: ((Int) -> Void)? = nil          // chosen minutes
    var onStartSession: ((RelaxSession) -> Void)? = nil

    // MARK: - State Properties
    @State private var selectedTab: MokoTab = .relax
    @State private var minutes: Int = 1
    @State private var activeSheet: RelaxSheet?

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
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
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

            Text("Set your timer for a calmer mind")
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

    @ViewBuilder
    private func sessionIcon(_ session: RelaxSession) -> some View {
        switch session {
        case .boxBreathing:
            BoxBreathingIcon(color: cardGreen)
        case .grounding:
            Image(systemName: "5.square")
                .font(.system(size: 38, weight: .regular))
                .foregroundColor(cardGreen)
        case .imagery:
            Image(systemName: "photo.tv")
                .font(.system(size: 38, weight: .regular))
                .foregroundColor(cardGreen)
        case .mirror:
            Image(systemName: "person.crop.square")
                .font(.system(size: 38, weight: .regular))
                .foregroundColor(cardGreen)
        }
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
                onStart: { onStartBreathing?(minutes) },
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
            RelaxDetailSheet(
                title: session.title,
                subtitle: session.cardDescription,
                steps: session.steps,
                buttonTitle: "Start",
                onStart: { onStartSession?(session) },
                icon: { sessionIcon(session) },
                extra: { EmptyView() }
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
