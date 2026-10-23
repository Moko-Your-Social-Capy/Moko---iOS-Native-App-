//
//  OverviewNoActiveQuestScreen.swift
//  Moko
//
//  Adheres to modern iOS and SwiftUI standards.
//

import SwiftUI

struct OverviewNoActiveQuestScreen: View {
    // MARK: - State Properties
    @State private var selectedTab: MokoTab = .overview
    
    // Palette matching design specifications
    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let primaryGreen = Color(red: 27/255, green: 66/255, blue: 47/255) // #1B422F
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255) // #2F2A28
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762
    private let timerBlue = Color(red: 10/255, green: 132/255, blue: 255/255) // #0A84FF
    private let pillActiveBg = Color(red: 237/255, green: 237/255, blue: 237/255) // #EDEDED
    private let activeTabIcon = Color(red: 54/255, green: 89/255, blue: 72/255) // #365948
    
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
                        .padding(.bottom, 120) // Bottom spacing for floating tab bar
                }
            }
            
            // MARK: - Floating Bottom Navigation Bar
            MokoFloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 21)
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
                Text("No Active Quest")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                
                // Mission Subtitle / Description
                Text("You can find more interesting quests to\nlevel up in quest library.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(subtextGray)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                
                // Bottom Timer Line: "New quest in 12 hrs 48 mins"
                HStack(spacing: 4) {
                    Spacer()
                    
                    Text("New quest in")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(subtextGray)
                    
                    Text("12 hrs 48 mins")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(timerBlue)
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
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
    }
}

#Preview {
    OverviewNoActiveQuestScreen()
}
