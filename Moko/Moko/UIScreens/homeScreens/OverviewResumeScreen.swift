//
//  OverviewResumeScreen.swift
//  Moko
//
//  Overview content only. Avatar opens Profile (sheet), Insights card opens the
//  radar info sheet, Calm Down card pushes the Summary screen.
//

import SwiftUI
import SwiftData

struct OverviewResumeScreen: View {
    /// The quest whose debrief is waiting to be finished.
    var quest: Quest? = nil

    // Insights flow: card -> info sheet -> InsightsView (pushed)
    @State private var showRadarInfo: Bool = false
    @State private var openInsights: Bool = false
    @State private var showInsights: Bool = false

    // Profile is presented as a sheet (it has its own NavigationStack)
    @State private var showProfile: Bool = false

    // Optional callbacks
    var onSlideResume: (() -> Void)? = nil
    var onStartDebrief: (() -> Void)? = nil

    // MARK: - State Properties
    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]

    @State private var slideOffset: CGFloat = 0
    @State private var isResumeCompleted: Bool = false

    private var data: OverviewData {
        OverviewData(insights: insights, calmDowns: calmDowns)
    }

    private var resumeDescription: String {
        "Pick up where you left off and share how it went."
    }

    // Palette matching design specifications
    private let screenBg = MokoTheme.limeBackground // #F6FAE8
    private let primaryGreen = Color(red: 27/255, green: 66/255, blue: 47/255) // #1B422F
    private let micGreen = Color(red: 47/255, green: 79/255, blue: 64/255)
    private let titleDark = MokoTheme.titleBrown // #5C4330
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762

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
                // Mission Title
                Text(quest?.title ?? "Unfinished Debrief")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                // Mission Subtitle / Description
                Text(resumeDescription)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(subtextGray)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                // Action: Slides to resume OR reveals Start Debrief + Mic
                if !isResumeCompleted {
                    slideToResumeWidget
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    startDebriefWidget
                        .padding(.horizontal, 24)
                        .padding(.top, 36)
                        .padding(.bottom, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isResumeCompleted)
        }
    }

    // MARK: - Start Debrief Widget (Shown after sliding to resume)
    private var startDebriefWidget: some View {
        HStack(alignment: .center) {
            Spacer()

            Button(action: {
                onStartDebrief?()
            }) {
                Text("Resume Debrief")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(titleDark)
            }

            Spacer()

            Button(action: {
                onStartDebrief?()
            }) {
                ZStack {
                    Circle()
                        .fill(micGreen)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Resume debrief by voice")
        }
    }

    // MARK: - Slide to Resume Widget
    private var slideToResumeWidget: some View {
        GeometryReader { geo in
            let sliderWidth = geo.size.width
            let knobSize: CGFloat = 43
            let maxDrag = sliderWidth - knobSize - 5

            ZStack(alignment: .leading) {
                // Pill Track
                Capsule()
                    .fill(primaryGreen.opacity(0.88))
                    .frame(height: 48)

                // Centered Label
                HStack {
                    Spacer()
                    Text("Slide to resume")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(height: 48)

                // Draggable Knob with Arrow
                ZStack {
                    Circle()
                        .fill(Color(red: 252/255, green: 248/255, blue: 240/255))
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MokoTheme.titleBrown)
                }
                .offset(x: 2.5 + slideOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !isResumeCompleted else { return }
                            let drag = max(0, min(value.translation.width, maxDrag))
                            slideOffset = drag
                        }
                        .onEnded { _ in
                            guard !isResumeCompleted else { return }
                            if slideOffset > maxDrag * 0.7 {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    slideOffset = maxDrag
                                    isResumeCompleted = true
                                }
                                onSlideResume?()
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    slideOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .frame(height: 48)
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
    OverviewResumeScreen()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
