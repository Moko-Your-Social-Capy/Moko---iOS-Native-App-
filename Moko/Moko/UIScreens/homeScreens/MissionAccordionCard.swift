import SwiftUI

struct MissionAccordionCard: View {
    let plan: DailyPlan?
    let questTemplate: QuestCardTemplate?
    let onStart: () -> Void

    @State private var openRow: Int = 0 // 0: Today's step, 1: Why, 2: How, 3: After
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let plan, let template = decodedTemplate(from: plan.copyJSON) {
                // Header notice if viewing tomorrow's plan before midnight
                if plan.date > Calendar.current.startOfDay(for: Date()) {
                    Text("Tomorrow's plan is ready")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DebriefStyle.subtext)
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 0) {
                    // Row 1: Today's step (open by default)
                    DisclosureGroup(isExpanded: Binding(
                        get: { openRow == 0 },
                        set: { if $0 { openRow = 0 } }
                    )) {
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
                        .padding(.vertical, 12)
                    } label: {
                        Text(template.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(DebriefStyle.title)
                            .frame(height: 44, alignment: .leading)
                    }
                    .accentColor(DebriefStyle.deepGreen)

                    Divider().padding(.vertical, 8)

                    // Row 2: Why this quest
                    DisclosureGroup(isExpanded: Binding(
                        get: { openRow == 1 },
                        set: { if $0 { openRow = 1 } }
                    )) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let weakSkill = plan.weakSkill {
                                Text("Your lowest skill this week: \(weakSkill)")
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DebriefStyle.mint.opacity(0.4))
                                    .clipShape(Capsule())
                            }
                            Text("From your onboarding: \(plan.onboardingTheme)")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DebriefStyle.mint.opacity(0.4))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Why this quest")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DebriefStyle.title)
                            .frame(height: 44, alignment: .leading)
                    }
                    .accentColor(DebriefStyle.deepGreen)

                    Divider().padding(.vertical, 8)

                    // Row 3: How to start
                    DisclosureGroup(isExpanded: Binding(
                        get: { openRow == 2 },
                        set: { if $0 { openRow = 2 } }
                    )) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Try saying: \"\(template.tryThis)\"")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(DebriefStyle.deepGreen)
                            Text("Tip: Take your time and keep your shoulders relaxed.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(DebriefStyle.subtext)
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("How to start")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DebriefStyle.title)
                            .frame(height: 44, alignment: .leading)
                    }
                    .accentColor(DebriefStyle.deepGreen)

                    Divider().padding(.vertical, 8)

                    // Row 4: After you try
                    DisclosureGroup(isExpanded: Binding(
                        get: { openRow == 3 },
                        set: { if $0 { openRow = 3 } }
                    )) {
                        Text("You'll reflect for 2 minutes, then Moko updates your scores.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(DebriefStyle.subtext)
                            .padding(.vertical, 8)
                    } label: {
                        Text("After you try")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DebriefStyle.title)
                            .frame(height: 44, alignment: .leading)
                    }
                    .accentColor(DebriefStyle.deepGreen)
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
                    Button(action: onStart) {
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

    private func decodedTemplate(from json: String) -> QuestCardTemplate? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(QuestCardTemplate.self, from: data)
    }
}
