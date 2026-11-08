import SwiftUI

struct MissionAccordionCard: View {
    let plan: DailyPlan?
    let questTemplate: QuestCardTemplate?
    let onStart: () -> Void
    /// Called by the empty-state button. Falls back to `onStart` so existing callers keep working.
    var onExplore: (() -> Void)? = nil

    @State private var openRow: Int = 0 // 0: Today's step, 1: Why, 2: How, 3: After, -1: none
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Today's template: the plan's saved copy first, then the template passed in.
    private var template: QuestCardTemplate? {
        if let plan, let decoded = decodedTemplate(from: plan.copyJSON) { return decoded }
        return questTemplate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let template {
                // Header notice if viewing tomorrow's plan before midnight
                if let plan, plan.date > Calendar.current.startOfDay(for: Date()) {
                    Text("Tomorrow's plan is ready")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DebriefStyle.subtext)
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 0) {
                    // Row 1: Today's step (open by default)
                    accordionRow(0, title: template.title, titleSize: 18, bold: true) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(template.situation)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(DebriefStyle.title)
                            Text(template.step)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DebriefStyle.deepGreen)
                            HStack {
                                Label(template.timeEstimate, systemImage: "clock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DebriefStyle.subtext)
                                Spacer()
                            }
                            Button(action: onStart) {
                                Text("Start")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(DebriefStyle.deepGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Start quest: \(template.title)")
                        }
                    }

                    Divider().padding(.vertical, 8)

                    // Row 2: Why this quest
                    accordionRow(1, title: "Why this quest") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let weakSkill = plan?.weakSkill {
                                chip("Your lowest skill this week: \(weakSkill)")
                            }
                            if let theme = plan?.onboardingTheme, !theme.isEmpty {
                                chip("From your onboarding: \(Self.stageName(theme))")
                            }
                            if plan?.weakSkill == nil && (plan?.onboardingTheme ?? "").isEmpty {
                                chip("A gentle place to start")
                            }
                        }
                    }

                    Divider().padding(.vertical, 8)

                    // Row 3: How to start
                    accordionRow(2, title: "How to start") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Try saying: \"\(template.tryThis)\"")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(DebriefStyle.deepGreen)
                            Text("Tip: Take your time and keep your shoulders relaxed.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(DebriefStyle.subtext)
                        }
                    }

                    Divider().padding(.vertical, 8)

                    // Row 4: After you try
                    accordionRow(3, title: "After you try") {
                        Text("You'll reflect for 2 minutes, then Moko updates your scores.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(DebriefStyle.subtext)
                    }
                }
                .padding(16)
                .background(DebriefStyle.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))
            } else {
                // Empty state
                VStack(alignment: .leading, spacing: 12) {
                    Text("No mission scheduled")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DebriefStyle.title)
                    Text("Pick a quest from Explore to begin your practice.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(DebriefStyle.subtext)
                    Button(action: { (onExplore ?? onStart)() }) {
                        Text("Pick a quest from Explore")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(DebriefStyle.deepGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(DebriefStyle.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(DebriefStyle.border, lineWidth: 1))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: openRow)
    }

    // MARK: Helpers

    /// One accordion row. Opening a row closes the others; tapping the open row closes it.
    private func accordionRow<Content: View>(
        _ index: Int,
        title: String,
        titleSize: CGFloat = 16,
        bold: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { openRow == index },
            set: { openRow = $0 ? index : -1 }
        )) {
            content().padding(.vertical, index == 0 ? 12 : 8)
        } label: {
            Text(title)
                .font(.system(size: titleSize, weight: bold ? .bold : .semibold))
                .foregroundColor(DebriefStyle.title)
                .frame(minHeight: 44, alignment: .leading)
        }
        .tint(DebriefStyle.deepGreen)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DebriefStyle.mint.opacity(0.4))
            .clipShape(Capsule())
    }

    private static func stageName(_ stage: String) -> String {
        switch stage {
        case "closeCircle": return "Close circle"
        case "newGroups": return "New groups"
        case "withinGroup": return "Within a group"
        case "family": return "Family"
        default: return stage
        }
    }

    private func decodedTemplate(from json: String) -> QuestCardTemplate? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(QuestCardTemplate.self, from: data)
    }
}
