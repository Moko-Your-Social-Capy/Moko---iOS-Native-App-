//
//  OverviewNoActiveQuestScreen.swift
//  Moko
//
//  Overview content only. Avatar opens Profile (sheet), Insights card opens the
//  radar info sheet, Calm Down card pushes the Summary screen.
//

import SwiftUI
import SwiftData

struct OverviewDebriefDone: View {
    // Insights flow: card -> info sheet -> InsightsView (pushed)
    @State private var showRadarInfo: Bool = false
    @State private var openInsights: Bool = false
    @State private var showInsights: Bool = false

    // Profile is presented as a sheet (it has its own NavigationStack)
    @State private var showProfile: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DailyPlan.date) private var plans: [DailyPlan]

    /// Library quests the planner can fall back on when there are no insights yet.
    var availableQuests: [LibraryQuestItem] = []
    /// Called once when the clock passes midnight, so the parent can load the new day's quest.
    var onNewDay: (() -> Void)? = nil
    /// The day this screen is showing. When it stops matching today, a new day has started.
    @State private var shownDay = Calendar.current.startOfDay(for: .now)

    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]

    private var data: OverviewData {
        OverviewData(insights: insights, calmDowns: calmDowns)
    }

    // MARK: - Next day

    private var tomorrowPlan: DailyPlan? {
        plans.first { Calendar.current.isDateInTomorrow($0.date) }
    }

    private var tomorrowTemplate: QuestCardTemplate? {
        guard let plan = tomorrowPlan, let data = plan.copyJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(QuestCardTemplate.self, from: data)
    }

    private func secondsUntilNextDay(from now: Date = .now) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return max(0, Int(next.timeIntervalSince(now)))
    }

    private func countdownText(_ total: Int) -> String {
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return "\(hours) \(hours == 1 ? "hr" : "hrs") \(minutes) \(minutes == 1 ? "min" : "mins")"
        }
        return "\(minutes) \(minutes == 1 ? "min" : "mins") \(seconds) sec"
    }

    /// Builds (or refreshes) tomorrow's quest from today's lowest-scoring skill.
    @MainActor
    private func planTomorrow() async {
        await DailyQuestPlanner.generateTomorrowPlan(modelContext: modelContext, availableQuests: availableQuests)
    }

    /// Sleeps until midnight, then starts the new day.
    @MainActor
    private func waitForNextDay() async {
        try? await Task.sleep(for: .seconds(secondsUntilNextDay() + 1))
        guard !Task.isCancelled else { return }
        await startNewDay()
    }

    @MainActor
    private func startNewDay() async {
        shownDay = Calendar.current.startOfDay(for: .now)
        await DailyQuestPlanner.promotePlanIfNeeded(modelContext: modelContext, availableQuests: availableQuests)
        onNewDay?()
    }

    // Palette matching design specifications
    private let screenBg = MokoTheme.limeBackground // #F6FAE8
    private let primaryGreen = Color(red: 27/255, green: 66/255, blue: 47/255) // #1B422F
    private let titleDark = MokoTheme.titleBrown // #5C4330
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762
    private let timerBlue = Color(red: 10/255, green: 132/255, blue: 255/255) // #0A84FF

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                screenBg
                    .ignoresSafeArea()

                // Scrollable Content Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: - Header
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 14)

                        // MARK: - Today's Mission Section
                        todaysMissionSection
                            .padding(.top, 28)
                            .padding(.horizontal, 16)

                        // MARK: - Statistics Section
                        statisticsSection
                            .padding(.top, 28)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
                .sheet(isPresented: $showProfile) {
                    ProfileOverView()
                }
            }
            // This screen keeps its own header; pushed screens get the default bar and back button
            .toolbar(.hidden, for: .navigationBar)
            .task { await planTomorrow() }
            // New insights saved (e.g. after a debrief) can change the lowest skill
            .onChange(of: insights.count) { _, _ in
                Task { await planTomorrow() }
            }
            // Coming back to the app after midnight
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, !Calendar.current.isDate(shownDay, inSameDayAs: .now) {
                    Task { await startNewDay() }
                }
            }
            .navigationDestination(isPresented: $showInsights) {
                InsightsView()
            }
            .sheet(isPresented: $showRadarInfo, onDismiss: {
                // Push Insights only after the sheet has fully closed
                if openInsights {
                    openInsights = false
                    showInsights = true
                }
            }) {
                RadarInfoSheet(onViewInsights: { openInsights = true })
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Overview")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(MokoTheme.titleBrown)

            Spacer()

            // Avatar Circle: opens the Profile screen as a sheet
            Button {
                showProfile = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 68/255, green: 68/255, blue: 68/255).opacity(0.6))
                        .frame(width: 47, height: 47)

                    if let name = profiles.first?.username, !name.isEmpty {
                        Text(String(name.prefix(2)).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open profile")
        }
    }

    // MARK: - Today's Mission Section
    private var todaysMissionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mission")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(titleDark)

            VStack(alignment: .leading, spacing: 0) {

                // Card Header
                Text("No Active Quest")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                // Completion Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(
                        Color(red: 0.20, green: 0.55, blue: 0.38)
                    )
                    .padding(12)
                    .background(
                        Color(red: 0.20, green: 0.55, blue: 0.38)
                            .opacity(0.10),
                        in: Circle()
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                // Main Message
                Text("All quests completed!")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(titleDark)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Description
                Text("You've finished today's quests. Discover more interesting challenges in the quest library.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(subtextGray)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.horizontal, 24)

                // Tomorrow's quest, made from today's lowest-scoring skill
                if let template = tomorrowTemplate {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Tomorrow's quest", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(subtextGray)
                        Text(template.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(primaryGreen)
                        if let skill = tomorrowPlan?.weakSkill {
                            Text("Focus: \(skill), your lowest score today")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(subtextGray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        Color(red: 0.886, green: 0.945, blue: 0.863),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Countdown Footer
                HStack(spacing: 7) {
                    Image(systemName: "clock")
                        .font(.system(size: 14, weight: .medium))

                    Text("New quests in")
                        .font(.system(size: 14, weight: .regular))

                    // Live countdown to midnight, when tomorrow's quest unlocks
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(countdownText(secondsUntilNextDay(from: context.date)))
                            .font(.system(size: 14, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(timerBlue)
                            .contentTransition(.numericText())
                    }
                }
                .foregroundColor(subtextGray)
                .task(id: shownDay) { await waitForNextDay() }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Color(red: 0.96, green: 0.96, blue: 0.97),
                    in: RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
                .padding(.horizontal, 20)
                .padding(.top, 26)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.035), lineWidth: 1)
            }
            .shadow(
                color: Color.black.opacity(0.045),
                radius: 12,
                x: 0,
                y: 4
            )
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Growth")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(titleDark)

            // Insights Card (opens the radar chart info sheet)
            insightsCard
                .onTapGesture {
                    showRadarInfo = true
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Insights")

            // Calm Down Card (pushes the Summary screen)
            NavigationLink {
                SummaryView()
            } label: {
                calmDownCard
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Insights Card
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Top Row
            HStack(alignment: .center) {
                Text("Insights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryGreen)

                Spacer()

                HStack(spacing: 4) {
                    Text(Date.now.formatted(
                        .dateTime
                            .locale(Locale(identifier: "en_US"))
                            .month(.abbreviated)
                            .day()
                    ))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(titleDark)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(titleDark)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            // Card Content: Number + Radar Chart
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(Int(data.insights.warmth.rounded()))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(primaryGreen)

                    Text("warmth")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(primaryGreen)
                }
                .padding(.bottom, 6)

                Spacer()

                // Radar / Diamond Shape Chart
                InsightsRadarChartView(scores: data.insights)
                    .frame(width: 106, height: 106)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Calm Down Card
    private var calmDownCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Top Row
            HStack(alignment: .center) {
                Text("Calm Down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryGreen)

                Spacer()

                HStack(spacing: 4) {
                    Text(Date.now.formatted(
                        .dateTime
                            .locale(Locale(identifier: "en_US"))
                            .month(.abbreviated)
                            .day()
                    ))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(titleDark)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(titleDark)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            // Card Content: Number + Bar Chart
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(data.calmDownMinutes)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(primaryGreen)

                    Text("min")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(primaryGreen)
                }
                .padding(.bottom, 6)

                Spacer()

                // Bar Chart Visual
                CalmDownBarChartView(minutes: data.calmDownBars)
                    .frame(width: 106, height: 72)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    OverviewDebriefDone()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
