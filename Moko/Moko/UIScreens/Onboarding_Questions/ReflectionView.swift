import SwiftUI

// MARK: - Content

struct ReflectionItem: Identifiable {
    let id: String
    let title: String
    let icon: String          // SF Symbol name
    let detail: String
    var tint: Color = RColor.green
}

extension ReflectionItem {
    static let strengths: [ReflectionItem] = [
        .init(id: "presence",
              title: "Thoughtful Presence",
              icon: "ear",
              detail: "You listen deeply and absorb before reacting, cultivating a grounded atmosphere that eases social friction."),
        .init(id: "loyalty",
              title: "Deep Loyalty",
              icon: "heart",
              detail: "In trusted circles, you show up with candid honesty, consistency, and steadfast emotional safety."),
        // Sample detail – not in the Figma, edit freely.
        .init(id: "intuition",
              title: "Intuitive Perception",
              icon: "eye",
              detail: "You pick up on subtle shifts in tone and mood, often sensing what the people around you feel before a word is said."),
    ]

    // Sample details – not in the Figma, edit freely.
    static let weakSpots: [ReflectionItem] = [
        .init(id: "hesitation",
              title: "Hesitation to calm space",
              icon: "pause.circle",
              detail: "You may hold back in quiet, relaxed moments, waiting for the perfect words instead of sharing what is on your mind.",
              tint: RColor.rust),
        .init(id: "overthinking",
              title: "Post chat overthinking",
              icon: "arrow.triangle.2.circlepath",
              detail: "After a conversation you tend to replay what was said and wonder if you got it right, which can linger long after the moment has passed.",
              tint: RColor.rust),
        .init(id: "boundary",
              title: "Boundary softening",
              icon: "shield.slash",
              detail: "You often soften or delay a firm “no” to keep things comfortable, even when something does not work for you.",
              tint: RColor.rust),
    ]
}

// MARK: - Screen

struct ReflectionView: View {
    @AppStorage("userName") private var storedUserName: String = ""

    var userName: String?
    var onOverview: () -> Void

    init(
        userName: String? = nil,
        onOverview: @escaping () -> Void = {}
    ) {
        self.userName = userName
        self.onOverview = onOverview
    }

    private var displayName: String {
        if let userName = userName?.trimmingCharacters(in: .whitespacesAndNewlines), !userName.isEmpty {
            return userName
        }
        let stored = storedUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty {
            return stored
        }
        return ""
    }

    /// Rows that start open. Use `[]` to start with everything collapsed.
    @State private var expanded: Set<String> = ["presence", "loyalty"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(displayName.isEmpty ? "This is you" : "This is you, \(displayName)")
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(OBColor.ink)
                    .padding(.leading, 13)
                    .padding(.top, 45)

                sectionHeading("Strengths")
                    .padding(.top, 53)

                VStack(alignment: .leading, spacing: 22) {
                    ForEach(ReflectionItem.strengths) { item in row(item) }
                }
                .padding(.top, 21)

                sectionHeading("Weak spots")
                    .padding(.top, 50)

                VStack(alignment: .leading, spacing: 31) {
                    ForEach(ReflectionItem.weakSpots) { item in row(item) }
                }
                .padding(.top, 24)
            }
            .padding(.leading, 37)
            .padding(.trailing, 45)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.white.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PillButton(title: "Overview", action: onOverview)
                .padding(.horizontal, 36)
                .padding(.top, 12)
                .padding(.bottom, 34)
                .background(Color.white)
        }
    }

    private func sectionHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .medium))
            .tracking(-0.4)
            .foregroundStyle(RColor.text)
    }

    // MARK: Expandable row

    private func row(_ item: ReflectionItem) -> some View {
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
                            .foregroundStyle(item.tint)
                    }
                    .frame(width: 28, height: 28)

                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RColor.text)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    // Points down when closed, rotates to point up when open
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RColor.chevron)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")

            if isOpen {
                Text(item.detail)
                    .font(.system(size: 16))
                    .lineSpacing(3.5)
                    .foregroundStyle(RColor.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 43)          // lines up with the title text
                    .transition(.opacity)
            }
        }
    }

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
