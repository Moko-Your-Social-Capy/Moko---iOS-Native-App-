import SwiftUI

struct OverviewCopiedView: View {
    @State private var tab: MokoTab = .overview
    @State private var showDebrief = false

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            Group {
                switch tab {
                case .overview:
                    overviewContent
                case .quests:
                    SimpleDestinationView(title: "Quests", subtitle: "Your active and completed quests.", symbol: "list.clipboard")
                case .relax:
                    CalmDownCopiedView()
                case .search:
                    SimpleDestinationView(title: "Search", subtitle: "Find an exercise or quest.", symbol: "magnifyingglass")
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MokoTabBar(selectedTab: $tab)
                .background(LinearGradient(colors: [AppColors.canvas.opacity(0), AppColors.canvas], startPoint: .top, endPoint: .bottom))
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Overview")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Spacer()
                    Text("AJ")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 27, height: 27)
                        .background(Color(red: 150/255, green: 150/255, blue: 150/255), in: Circle())
                }

                Text("Today's Mission")
                    .font(.system(size: 11, weight: .bold))

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Introduce yourself at a new job")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.forest)
                        Text("Make a good first impression, one genuine introduction at a time.")
                            .font(.system(size: 9))
                            .foregroundStyle(AppColors.secondaryInk)
                        Button { showDebrief = true } label: {
                            HStack {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 24, height: 24)
                                    .background(.white, in: Circle())
                                Spacer()
                                Text("Slide to Complete")
                                    .font(.system(size: 10, weight: .semibold))
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(AppColors.forest, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Statistics").font(.system(size: 14, weight: .bold))

                NavigationLink { InsightsCopiedView() } label: {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Insights").font(.system(size: 11, weight: .semibold)).foregroundStyle(AppColors.forest)
                                Spacer()
                                Text("Oct 15  ›").font(.system(size: 8)).foregroundStyle(AppColors.secondaryInk)
                            }
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("78").font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(AppColors.forest)
                                    Text("warmth").font(.system(size: 9, weight: .medium)).foregroundStyle(AppColors.forest)
                                }
                                Spacer()
                                RadarChartView(metrics: DemoMokoData.metrics(for: .week))
                                    .frame(width: 82, height: 72)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                NavigationLink { CalmDownCopiedView() } label: {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Calm Down").font(.system(size: 11, weight: .semibold)).foregroundStyle(AppColors.forest)
                                Spacer()
                                Text("Oct 15  ›").font(.system(size: 8)).foregroundStyle(AppColors.secondaryInk)
                            }
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("18").font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(AppColors.forest)
                                    Text("min").font(.system(size: 9, weight: .medium)).foregroundStyle(AppColors.forest)
                                }
                                Spacer()
                                MiniBarChart(values: [14, 24, 38, 17, 12, 27, 19])
                                    .frame(width: 76, height: 44)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showDebrief) {
            NavigationStack {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(AppColors.forest)
                    Text("Mission completed").font(.title2.bold())
                    Text("This is a placeholder completion sheet. Connect it to your real quest/debrief flow.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.canvas)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDebrief = false }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct MiniBarChart: View {
    let values: [CGFloat]
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(values.indices, id: \.self) { index in
                Capsule()
                    .fill(AppColors.amber)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, values[index]))
            }
        }
        .accessibilityLabel("Calm Down session bar chart preview")
    }
}

private struct SimpleDestinationView: View {
    let title: String
    let subtitle: String
    let symbol: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 30)).foregroundStyle(AppColors.forest)
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }
}

#Preview { NavigationStack { OverviewCopiedView() } }
