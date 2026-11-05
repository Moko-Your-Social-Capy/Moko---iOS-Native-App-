import SwiftUI
import SwiftData

struct Overview: View {
    @Binding var selectedTab: MokoTab
    let mission: Quest?
    var onStartDebrief: ((Quest) -> Void)? = nil

    init(selectedTab: Binding<MokoTab> = .constant(.overview), mission: Quest? = nil, onStartDebrief: ((Quest) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.mission = mission
        self.onStartDebrief = onStartDebrief
    }

    @Query private var profiles: [Profile]
    @Query private var insights: [InsightsModel]
    @Query private var calmDowns: [CalmDownModel]
    @Query private var quests: [Quest]
    @AppStorage("moko.selectedCostumeLevel") private var selectedCostumeLevel = 1
    @AppStorage("moko.lastSnackTimestamp") private var lastSnackTimestamp: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showRadarInfo = false
    @State private var openInsights = false
    @State private var showInsights = false
    @State private var showProfile = false
    @State private var showSnackSheet = false
    @State private var showLevelBurst = false

    private var profile: Profile? { profiles.first }
    private var xp: Int { profile?.xp ?? 0 }
    private var level: Int { xp / 400 + 1 }
    private var streak: Int { profile?.currentStreak ?? 0 }
    private var localQuests: [Quest] { quests.filter { $0.ownerID == CurrentUser.localID } }
    private var data: OverviewData { OverviewData(insights: insights, calmDowns: calmDowns) }
    private var name: String {
        let trimmed = profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Welcome back" : "Hi, \(trimmed)"
    }
    private var equippedCostume: MokoCostume { .selected(unlockedAt: level, selection: selectedCostumeLevel) }
    private var snackGivenToday: Bool {
        lastSnackTimestamp > 0 && Calendar.current.isDate(Date(timeIntervalSince1970: lastSnackTimestamp), inSameDayAs: .now)
    }
    private var surface: Color { colorScheme == .dark ? Color(hex: 0x1C2923) : Color(hex: 0xF7F5F2) }
    private var secondary: Color { colorScheme == .dark ? Color(hex: 0xDDD5C9).opacity(0.82) : Color(hex: 0x4A3826).opacity(0.72) }
    private var heading: Color { colorScheme == .dark ? Color(hex: 0xF7F0E6) : Color(hex: 0x4A3826) }
    private var accent: Color { colorScheme == .dark ? Color(hex: 0x83C7D7) : Color(hex: 0x1F7488) }
    private var softGreen: Color { colorScheme == .dark ? Color(hex: 0x264335) : Color(hex: 0xCFE6C4) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerSection
                            .overviewEntrance(order: 0, reduceMotion: reduceMotion)
                        xpSection
                            .padding(.horizontal, 16)
                            .overviewEntrance(order: 1, reduceMotion: reduceMotion)
                        todayQuestSection
                            .padding(.horizontal, 16)
                            .overviewEntrance(order: 2, reduceMotion: reduceMotion)
                        calmDownSection
                            .padding(.horizontal, 16)
                            .overviewEntrance(order: 3, reduceMotion: reduceMotion)
                        snackSection
                            .padding(.horizontal, 16)
                            .overviewEntrance(order: 4, reduceMotion: reduceMotion)
                        insightsSection
                            .padding(.horizontal, 16)
                            .overviewEntrance(order: 5, reduceMotion: reduceMotion)
                    }
                    .padding(.bottom, 30)
                }
            }
            .overlay(alignment: .top) {
                if showLevelBurst {
                    MokoLevelBurstView()
                        .frame(height: 220)
                        .padding(.top, 176)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showInsights) { InsightsView() }
            .sheet(isPresented: $showRadarInfo, onDismiss: {
                if openInsights { openInsights = false; showInsights = true }
            }) {
                RadarInfoSheet(onViewInsights: { openInsights = true })
            }
            .sheet(isPresented: $showProfile) {
                ProfileOverView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSnackSheet) {
                FeedMokoSheet(costume: equippedCostume, alreadyFed: snackGivenToday) {
                    lastSnackTimestamp = Date.now.timeIntervalSince1970
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .task(id: mission?.id) {
                guard let mission, !mission.isCompleted else { return }
                await MokoLiveActivityManager.startTodayQuest(id: mission.id, title: mission.title)
            }
        }
        .tint(accent)
    }

    private var headerSection: some View {
        ZStack(alignment: .bottomTrailing) {
            (colorScheme == .dark ? Color(hex: 0x1E342A) : Color(hex: 0xCFE6C4))
            Image("FoliageBush")
                .renderingMode(.template).resizable().scaledToFit()
                .foregroundStyle(colorScheme == .dark ? Color(hex: 0x6D9870) : Color(hex: 0x8FBF8A))
                .opacity(colorScheme == .dark ? 0.18 : 0.33)
                .frame(width: 270, height: 96)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            Image("FoliageBranch")
                .renderingMode(.template).resizable().scaledToFit()
                .foregroundStyle(colorScheme == .dark ? Color(hex: 0x85A87B) : Color(hex: 0x8FBF8A))
                .opacity(0.24)
                .frame(width: 76, height: 80)
                .rotationEffect(.degrees(-24))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 112)
            Image(equippedCostume.assetName)
                .resizable().scaledToFit()
                .frame(width: 132, height: 132)
                .offset(x: 10, y: 20)
                .accessibilityLabel("Moko peeking in wearing \(equippedCostume.name)")

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Overview")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(heading)
                        Text(name)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(heading)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Button { showProfile = true } label: {
                        Group {
                            if let imageData = profile?.profileImageData, let image = UIImage(data: imageData) {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                Text(profile?.username.prefix(2).uppercased() ?? "MO")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundStyle(heading)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(surface.opacity(0.78), in: Circle())
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.62), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open profile")
                }
                Text("Small steps count. Choose what feels right today.")
                    .font(.subheadline)
                    .foregroundStyle(secondary)
                    .padding(.top, 8)
                    .padding(.trailing, 110)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .frame(height: 192)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var xpSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                Text("Your XP")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(heading)
                Spacer()
                Text("\(xp) total")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(secondary)
            }
            MokoXPProgressView(xp: xp, size: .compact, onLevelUp: playLevelBurst)
            MokoWeeklyXPStrip(quests: localQuests, streak: streak, lastActivityDate: profile?.lastActivityDate)
        }
        .padding(14)
        .background(surface.opacity(colorScheme == .dark ? 0.96 : 0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(softGreen.opacity(0.75), lineWidth: 1))
    }

    private var todayQuestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accent)
                Text("TODAY’S QUEST")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(accent)
                Spacer(minLength: 4)
                if let mission {
                    Text("+\(mission.awardedXP) XP")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(ProfilePalette.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(softGreen, in: Capsule())
                }
            }
            if let mission {
                Text(mission.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(heading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(missionDescription(for: mission))
                    .font(.subheadline)
                    .foregroundStyle(secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    if mission.isCompleted {
                        onStartDebrief?(mission)
                    } else {
                        selectedTab = .quests
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(mission.isCompleted ? "Start debrief" : "Start")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(accent, in: Capsule())
                }
                .buttonStyle(MokoPrimaryButtonStyle())
                .padding(.top, 3)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    Image("profile_empty_moko")
                        .resizable().scaledToFit().frame(width: 78, height: 78)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Pick a quest for today")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(heading)
                        Text("Choose one small step from the library.")
                            .font(.subheadline)
                            .foregroundStyle(secondary)
                        Button("Explore quests") { selectedTab = .search }
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(accent)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(hex: 0x20372E) : Color(hex: 0xE8F0DB), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(colorScheme == .dark ? 0.08 : 0.72), lineWidth: 1))
    }

    private var calmDownSection: some View {
        NavigationLink { SummaryView() } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "wind")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
                    .background(softGreen, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calm Down")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(heading)
                    Text("\(data.calmDownMinutes) min today · take a quiet moment")
                        .font(.subheadline)
                        .foregroundStyle(secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondary)
            }
            .padding(14)
            .background(surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(softGreen.opacity(0.7), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Calm Down. \(data.calmDownMinutes) minutes today")
    }

    private var snackSection: some View {
        Button { showSnackSheet = true } label: {
            HStack(spacing: 14) {
                Image(systemName: snackGivenToday ? "heart.fill" : "carrot.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xA76639))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: 0xF2E4CF), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snack time")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(heading)
                    Text(snackGivenToday ? "Moko enjoyed a little treat today" : "Give Moko a little treat")
                        .font(.subheadline)
                        .foregroundStyle(secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Text(snackGivenToday ? "Done" : "Feed Moko")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 40)
                    .background(softGreen.opacity(0.7), in: Capsule())
            }
            .padding(14)
            .background(surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(softGreen.opacity(0.7), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var insightsSection: some View {
        Button { showRadarInfo = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("Insights")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(heading)
                    Spacer()
                    Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondary)
                }
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(data.insights.warmth.rounded()))")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundStyle(heading)
                        Text("warmth")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(secondary)
                    }
                    Spacer()
                    InsightsRadarChartView(scores: data.insights)
                        .frame(width: 84, height: 84)
                        .accessibilityLabel("Insights radar chart")
                }
                if data.insights.warmth == 0 {
                    Text("Complete a quest to see your first insight")
                        .font(.caption)
                        .foregroundStyle(secondary)
                }
            }
            .padding(16)
            .background(colorScheme == .dark ? Color(hex: 0x243B30) : Color(hex: 0xE4F0DE), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(colorScheme == .dark ? 0.08 : 0.72), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Insights. Warmth score \(Int(data.insights.warmth.rounded()))")
    }

    private func missionDescription(for quest: Quest) -> String {
        "A \(quest.intensity.rawValue.lowercased()) \(quest.category.rawValue.lowercased()) quest. Take your time and go at your pace."
    }

    private func playLevelBurst() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { showLevelBurst = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            withAnimation(.easeOut(duration: 0.22)) { showLevelBurst = false }
        }
    }
}

private struct FeedMokoSheet: View {
    let costume: MokoCostume
    let alreadyFed: Bool
    let onFeed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fed = false

    var body: some View {
        VStack(spacing: 12) {
            Image(costume.assetName)
                .resizable().scaledToFit()
                .frame(width: 118, height: 118)
                .scaleEffect(fed && !reduceMotion ? 1.04 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.58), value: fed)
                .accessibilityLabel("Moko wearing \(costume.name)")
            Text(fed || alreadyFed ? "Moko says thank you!" : "A little snack break")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(ProfilePalette.text)
            Text(fed || alreadyFed ? "A small treat and a quiet moment." : "Choose a gentle pause and give Moko a treat.")
                .font(.subheadline)
                .foregroundStyle(ProfilePalette.secondary)
                .multilineTextAlignment(.center)
            Button {
                if !alreadyFed { onFeed() }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.58)) { fed = true }
            } label: {
                Text(fed || alreadyFed ? "Done" : "Give a snack")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(ProfilePalette.accent, in: Capsule())
            }
            .buttonStyle(MokoPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 3)
            .disabled(fed || alreadyFed)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
    }
}

private struct OverviewEntranceModifier: ViewModifier {
    let order: Int
    let reduceMotion: Bool
    @State private var visible = false
    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 10)
            .onAppear {
                guard !visible else { return }
                let animation = reduceMotion
                    ? Animation.easeInOut(duration: 0.2)
                    : Animation.spring(response: 0.42, dampingFraction: 0.88).delay(Double(order) * 0.04)
                withAnimation(animation) { visible = true }
            }
    }
}

private extension View {
    func overviewEntrance(order: Int, reduceMotion: Bool) -> some View {
        modifier(OverviewEntranceModifier(order: order, reduceMotion: reduceMotion))
    }
}

private struct MokoLevelBurstView: View {
    private let colors: [Color] = [ProfilePalette.accent, ProfilePalette.success, ProfilePalette.midGreen, Color(hex: 0xD9A441)]
    @State private var burst = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<28, id: \.self) { index in
                    let angle = Double(index) * 2.399
                    let distance = proxy.size.width * (0.30 + Double(index % 4) * 0.045)
                    Image(systemName: index.isMultiple(of: 4) ? "leaf.fill" : "sparkle")
                        .font(.system(size: index.isMultiple(of: 3) ? 15 : 10, weight: .bold))
                        .foregroundStyle(colors[index % colors.count])
                        .offset(
                            x: burst ? cos(angle) * distance : 0,
                            y: burst ? sin(angle) * 56 - 14 : 0
                        )
                        .rotationEffect(.degrees(burst ? angle * 38 : 0))
                        .opacity(burst ? 0 : 1)
                        .animation(.spring(response: 0.54, dampingFraction: 0.72).delay(Double(index % 7) * 0.012), value: burst)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { burst = true }
    }
}

// MARK: - Insights Radar Chart Component
struct InsightsRadarChartView: View {
    /// Today's real scores. Top = courage, right = presence,
    /// bottom = warmth, left = clarity.
    var scores: InsightsScores = .zero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let radiusX = w * 0.47
            let radiusY = h * 0.47

            // Data points from the real scores (100 = outer diamond)
            let topPt = CGPoint(x: center.x, y: center.y - radiusY * ratio(scores.courage))
            let rightPt = CGPoint(x: center.x + radiusX * ratio(scores.presence), y: center.y)
            let bottomPt = CGPoint(x: center.x, y: center.y + radiusY * ratio(scores.warmth))
            let leftPt = CGPoint(x: center.x - radiusX * ratio(scores.clarity), y: center.y)
            let points = [topPt, rightPt, bottomPt, leftPt]

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
                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 62/255, green: 92/255, blue: 74/255))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(points[index])
                }
            }
        }
    }

    private func ratio(_ score: Double) -> CGFloat {
        CGFloat(max(0, min(100, score)) / 100)
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
    /// Minutes for each bar, oldest first. The bars scale to the tallest day.
    var minutes: [Double] = Array(repeating: 0, count: 6)

    private let barColor = Color(red: 27/255, green: 66/255, blue: 47/255)
    private let barWidth: CGFloat = 5.7

    var body: some View {
        GeometryReader { geo in
            let peak = max(minutes.max() ?? 0, 1)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(minutes.indices, id: \.self) { index in
                    let value = minutes[index]

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor.opacity(value > 0 ? 1 : 0.15))
                        .frame(
                            width: barWidth,
                            height: barHeight(for: value, peak: peak, available: geo.size.height)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func barHeight(for value: Double, peak: Double, available: CGFloat) -> CGFloat {
        guard value > 0 else { return 2 }
        return max(2, available * CGFloat(value / peak))
    }
}

#Preview {
    Overview()
        .modelContainer(
            for: [Profile.self, Quest.self, InsightsModel.self, CalmDownModel.self],
            inMemory: true
        )
}
