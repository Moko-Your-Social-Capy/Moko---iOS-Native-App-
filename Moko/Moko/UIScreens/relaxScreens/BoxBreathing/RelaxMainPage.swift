import SwiftUI

/// Stand-in for the Relax page (designed by someone else).
/// Only the Box Breathing card does something: it calls `onBoxBreathing`.
struct RelaxMainPage: View {
    var onBoxBreathing: () -> Void = {}

    @State private var minutes = 1

    private let columns = [GridItem(.flexible(), spacing: 29), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Relax")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(.black)
                    .padding(.top, 11)

                breathingCard
                    .padding(.top, 19)

                Text("Guided Sessions")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(.black)
                    .padding(.top, 21)

                LazyVGrid(columns: columns, spacing: 19) {
                    GuidedSessionCard(
                        title: "Box Breathing",
                        description: "Breathe in, hold, breathe out, and repeat slowly.",
                        action: onBoxBreathing          // <- the only one that goes anywhere
                    ) {
                        BoxGlyph()
                    }

                    GuidedSessionCard(
                        title: "Grounding",
                        description: "Use senses to focus on the present."
                    ) {
                        Image(systemName: "5.square")
                            .font(.system(size: 46))
                    }

                    GuidedSessionCard(
                        title: "Imagery",
                        description: "Breathing and guided imagery paired together"
                    ) {
                        Image(systemName: "photo.tv")
                            .font(.system(size: 46))
                    }

                    GuidedSessionCard(
                        title: "Mirror",
                        description: "Breathing and guided imagery paired together"
                    ) {
                        Image(systemName: "person.crop.artframe")
                            .font(.system(size: 46))
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(BBColor.background.ignoresSafeArea())
    }

    // MARK: Breathing card (timer stepper)

    private var breathingCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)

            VStack(alignment: .leading, spacing: 0) {
                Text("Breathing")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(BBColor.button)

                Text("Set your own meditation timer for a calmer mind")
                    .font(.system(size: 17))
                    .lineSpacing(3)
                    .foregroundStyle(BBColor.muted)
                    .frame(maxWidth: 235, alignment: .leading)
                    .padding(.top, 7)

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    stepperButton("minus") { minutes = max(1, minutes - 1) }
                    Text("\(minutes) min")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 74)
                    stepperButton("plus") { minutes = min(30, minutes + 1) }
                }
            }
            .padding(.leading, 20)
            .padding(.top, 10)
            .padding(.bottom, 19)
        }
        .frame(height: 182)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.black)
                .padding(.top, 12)
                .padding(.trailing, 20)
        }
        .overlay(alignment: .bottomTrailing) {
            RelaxDotsIcon()
                .padding(.trailing, 28)
                .padding(.bottom, 25)
        }
    }

    private func stepperButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(hex: 0xEDEDED)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "minus" ? "Decrease minutes" : "Increase minutes")
    }
}

// MARK: - Guided session card

private struct GuidedSessionCard<Icon: View>: View {
    let title: String
    let description: String
    var action: (() -> Void)?
    let icon: Icon

    init(title: String,
         description: String,
         action: (() -> Void)? = nil,
         @ViewBuilder icon: () -> Icon) {
        self.title = title
        self.description = description
        self.action = action
        self.icon = icon()
    }

    var body: some View {
        Button { action?() } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(BBColor.button)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.black)
                }
                .padding(.leading, 16)
                .padding(.trailing, 18)
                .padding(.top, 20)

                Spacer(minLength: 0)

                icon
                    .foregroundStyle(BBColor.button)

                Spacer(minLength: 0)

                Text(description)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BBColor.muted)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icons

/// Box Breathing icon: a rounded square with corner marks.
private struct BoxGlyph: View {
    var body: some View {
        ZStack {
            Image(systemName: "viewfinder")
                .font(.system(size: 56, weight: .semibold))
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(lineWidth: 4)
                .frame(width: 25, height: 25)
        }
        .frame(height: 56)
    }
}

/// The dotted pattern on the Breathing card, drawn with circles.
private struct RelaxDotsIcon: View {
    // (x, y, diameter) measured from the centre
    private static let dots: [(CGFloat, CGFloat, CGFloat)] = [
        (0, 0, 12),
        (0, -17.5, 10), (-15, -8.5, 10), (15, -8.5, 10),
        (-15, 8.5, 10), (15, 8.5, 10), (0, 17.5, 10),
        (0, -35, 6.5), (-15, -26.5, 6.5), (15, -26.5, 6.5),
        (-30, -17.5, 6.5), (30, -17.5, 6.5),
        (-30, 0, 6.5), (30, 0, 6.5),
        (-30, 16.5, 6.5), (30, 16.5, 6.5),
        (-15, 26, 6.5), (15, 26, 6.5), (0, 34.5, 6.5)
    ]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for dot in Self.dots {
                let rect = CGRect(x: center.x + dot.0 - dot.2 / 2,
                                  y: center.y + dot.1 - dot.2 / 2,
                                  width: dot.2, height: dot.2)
                context.fill(Path(ellipseIn: rect), with: .color(BBColor.button))
            }
        }
        .frame(width: 72, height: 76)
        .accessibilityHidden(true)
    }
}

#Preview {
    RelaxMainPage()
}
