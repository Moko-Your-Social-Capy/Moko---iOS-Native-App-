//
//  MokoTabBar.swift
//  Moko
//
//  Native iOS floating tab bar adhering exactly to the design specifications.
//

import SwiftUI

enum MokoTab: CaseIterable {
    case overview
    case quests
    case relax
}

struct MokoFloatingTabBar: View {
    @Binding var selectedTab: MokoTab
    var onSearchTap: (() -> Void)? = nil
    
    // Palette
    private let activePillBg = Color(red: 237/255, green: 237/255, blue: 237/255) // #EDEDED
    private let activeGreen = Color(red: 54/255, green: 89/255, blue: 72/255) // #365948
    private let inactiveColor = Color.black
    
    var body: some View {
        HStack(spacing: 16) {
            // Main 3-Tab Segmented Capsule
            HStack(spacing: 0) {
                // Overview Tab
                tabButton(
                    tab: .overview,
                    label: "Overview",
                    iconName: "square.grid.2x2.fill",
                    isCustomMeditation: false
                )
                
                // Quests Tab
                tabButton(
                    tab: .quests,
                    label: "Quests",
                    iconName: "clipboard.fill",
                    isCustomMeditation: false
                )
                
                // Relax Tab
                tabButton(
                    tab: .relax,
                    label: "Relax",
                    iconName: "figure.mind.and.body",
                    isCustomMeditation: true
                )
            }
            .frame(width: 278, height: 64.5)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 2)
            )
            
            // Search Circle Button
            Button(action: {
                onSearchTap?()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 2)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(MokoTabPressStyle())
        }
    }
    
    @ViewBuilder
    private func tabButton(tab: MokoTab, label: String, iconName: String, isCustomMeditation: Bool) -> some View {
        let isSelected = selectedTab == tab
        let tint = isSelected ? activeGreen : inactiveColor
        
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                selectedTab = tab
            }
        }) {
            ZStack {
                // Active Capsule Highlight
                if isSelected {
                    Capsule()
                        .fill(activePillBg)
                        .frame(width: 90, height: 55)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                
                VStack(spacing: 4) {
                    if isCustomMeditation {
                        MeditationYogaIcon(color: tint)
                            .frame(width: 24, height: 21)
                    } else if tab == .quests {
                        QuestsClipboardIcon(color: tint)
                            .frame(width: 17, height: 22)
                    } else {
                        // Overview Icon
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(tint)
                    }
                    
                    Text(label)
                        .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                        .foregroundColor(tint)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(MokoTabPressStyle())
    }
}

// MARK: - Native Tactile Button Style
struct MokoTabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Custom Vector Icons Matching Design Specs
struct QuestsClipboardIcon: View {
    var color: Color = .black
    
    var body: some View {
        ZStack {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct MeditationYogaIcon: View {
    var color: Color = .black
    
    var body: some View {
        // Precise meditation/lotus pose vector
        ZStack {
            // Head
            Circle()
                .fill(color)
                .frame(width: 5.5, height: 5.5)
                .offset(y: -7)
            
            // Body + Crossed Legs
            MeditationPoseShape()
                .fill(color)
                .frame(width: 24, height: 16)
                .offset(y: 2)
        }
    }
}

struct MeditationPoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Torso and outward hands resting on knees
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.35))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.98, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.88))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.35))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        Color(red: 242/255, green: 242/255, blue: 247/255)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            MokoFloatingTabBar(selectedTab: .constant(.overview))
                .padding(.bottom, 20)
        }
    }
}
