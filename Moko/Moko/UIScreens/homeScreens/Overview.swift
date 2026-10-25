//
//  TodoOverviewScreen.swift
//  Moko
//
//  Overview content only. Includes the floating MokoTabBar.
//

import SwiftUI

struct Overview: View {
    @Binding var selectedTab: MokoTab

    // Optional navigation callback when debrief starts
    var onStartDebrief: (() -> Void)? = nil

    init(selectedTab: Binding<MokoTab> = .constant(.overview), onStartDebrief: (() -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.onStartDebrief = onStartDebrief
    }

    // MARK: - State Properties
    @State private var slideOffset: CGFloat = 0
    @State private var isMissionCompleted: Bool = false
    @State private var showInsights: Bool = false
    @State private var showCalmDown: Bool = false

    // Custom Palette based on design specs
    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let primaryGreen = Color(red: 27/255, green: 66/255, blue: 47/255) // #1B422F
    private let micGreen = Color(red: 47/255, green: 79/255, blue: 64/255)
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255) // #2F2A28
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762

    var body: some View {
        ZStack(alignment: .bottom) {
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
                        .padding(.bottom, 120) // space for floating tab bar
                }
            }

            // MARK: - Floating Tab Bar
            MokoTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
        .fullScreenCover(isPresented: $showInsights) {
            NavigationStack {
                InsightsCopiedView()
            }
        }
        .sheet(isPresented: $showCalmDown) {
            NavigationStack {
                CalmDownCopiedView()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Overview")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            // Avatar Circle
            ZStack {
                Circle()
                    .fill(Color(red: 68/255, green: 68/255, blue: 68/255).opacity(0.6))
                    .frame(width: 47, height: 47)

                Text("AJ")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Today's Mission Section
    private var todaysMissionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today’s Mission")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(titleDark)

            VStack(alignment: .leading, spacing: 0) {
                // Mission Title
                Text("Introduce yourself at a new job")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                // Mission Subtitle / Description
                Text("Make a good first impression, one genuine introduction at a time.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(subtextGray)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                // Action: Slides to complete OR reveals Start Debrief + Mic
                if !isMissionCompleted {
                    slideToCompleteWidget
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
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isMissionCompleted)
        }
    }

    // MARK: - Start Debrief Widget (Shown after sliding)
    private var startDebriefWidget: some View {
        HStack(alignment: .center) {
            Spacer()

            Button(action: {
                onStartDebrief?()
            }) {
                Text("Start Debrief")
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
        }
    }

    // MARK: - Slide to Complete Widget
    private var slideToCompleteWidget: some View {
        GeometryReader { geo in
            let sliderWidth = geo.size.width
            let knobSize: CGFloat = 43
            let maxDrag = sliderWidth - knobSize - 5

            ZStack(alignment: .leading) {
                // Pill Background
                Capsule()
                    .fill(primaryGreen.opacity(0.88))
                    .frame(height: 48)

                // Centered Label
                HStack {
                    Spacer()
                    Text("Slide to Complete")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(height: 48)

                // Draggable White Knob with Arrow
                ZStack {
                    Circle()
                        .fill(Color(red: 252/255, green: 248/255, blue: 240/255))
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                .offset(x: 2.5 + slideOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !isMissionCompleted else { return }
                            let drag = max(0, min(value.translation.width, maxDrag))
                            slideOffset = drag
                        }
                        .onEnded { value in
                            guard !isMissionCompleted else { return }
                            if slideOffset > maxDrag * 0.7 {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    slideOffset = maxDrag
                                    isMissionCompleted = true
                                }
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
            Text("Statistics")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(titleDark)

            // Insights Card
            insightsCard

            // Calm Down Card
            calmDownCard
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
                    Text("Oct 15")
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
                    Text("78")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(primaryGreen)

                    Text("warmth")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(primaryGreen)
                }
                .padding(.bottom, 6)

                Spacer()

                // Radar / Diamond Shape Chart
                InsightsRadarChartView()
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
        .onTapGesture {
            showInsights = true
        }
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
                    Text("Oct 15")
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
                    Text("18")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(primaryGreen)

                    Text("min")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(primaryGreen)
                }
                .padding(.bottom, 6)

                Spacer()

                // Bar Chart Visual
                CalmDownBarChartView()
                    .frame(height: 72)
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
        .onTapGesture {
            showCalmDown = true
        }
    }
}

// MARK: - Insights Radar Chart Component
struct InsightsRadarChartView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let center = CGPoint(x: w / 2, y: h / 2)

            ZStack {
                // Background Outer Diamond
                DiamondShape()
                    .stroke(Color(red: 227/255, green: 232/255, blue: 227/255), lineWidth: 1.6)
                    .frame(width: w * 0.94, height: h * 0.94)

                // Inner Guide Diamond
                DiamondShape()
                    .stroke(Color(red: 227/255, green: 232/255, blue: 227/255), lineWidth: 1.2)
                    .frame(width: w * 0.47, height: h * 0.47)

                // Cross axes
                Path { path in
                    // Vertical axis
                    path.move(to: CGPoint(x: center.x, y: center.y - (h * 0.47)))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + (h * 0.47)))

                    // Horizontal axis
                    path.move(to: CGPoint(x: center.x - (w * 0.47), y: center.y))
                    path.addLine(to: CGPoint(x: center.x + (w * 0.47), y: center.y))
                }
                .stroke(Color(red: 203/255, green: 211/255, blue: 203/255), lineWidth: 1.4)

                // Data Polygon (Top: 66%, Right: 78%, Bottom: 75%, Left: 70%)
                let topPt = CGPoint(x: center.x, y: center.y - (h * 0.33))
                let rightPt = CGPoint(x: center.x + (w * 0.39), y: center.y)
                let bottomPt = CGPoint(x: center.x, y: center.y + (h * 0.375))
                let leftPt = CGPoint(x: center.x - (w * 0.35), y: center.y)

                Path { path in
                    path.move(to: topPt)
                    path.addLine(to: rightPt)
                    path.addLine(to: bottomPt)
                    path.addLine(to: leftPt)
                    path.closeSubpath()
                }
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 127/255, green: 163/255, blue: 140/255).opacity(0.18),
                            Color(red: 78/255, green: 122/255, blue: 95/255).opacity(0.58)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.5
                    )
                )

                Path { path in
                    path.move(to: topPt)
                    path.addLine(to: rightPt)
                    path.addLine(to: bottomPt)
                    path.addLine(to: leftPt)
                    path.closeSubpath()
                }
                .stroke(Color(red: 62/255, green: 92/255, blue: 74/255), lineWidth: 2.4)

                // Vertex Circles
                ForEach([topPt, rightPt, bottomPt, leftPt], id: \.x) { pt in
                    Circle()
                        .fill(Color(red: 62/255, green: 92/255, blue: 74/255))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(pt)
                }
            }
        }
    }
}

// MARK: - Diamond Shape
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Calm Down Bar Chart Component
struct CalmDownBarChartView: View {
    // Bar heights: [36, 57, 71, 36, 18, 46]
    private let barData: [(height: CGFloat, width: CGFloat)] = [
        (36, 5.7),
        (57, 5.7),
        (71, 5.7),
        (36, 5.7),
        (18, 5.7),
        (46, 5.7)
    ]

    private let barColor = Color(red: 27/255, green: 66/255, blue: 47/255)

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<barData.count, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor)
                    .frame(width: barData[idx].width, height: barData[idx].height)
            }
        }
    }
}

#Preview {
    Overview()
}
