//
//  MokoTabBar.swift
//  Moko
//
//  Floating Liquid Glass tab bar styled like the system tab bar:
//  glass capsule with a sliding glass selection pill, plus a separate
//  round glass search tab. Search is a regular tab: tapping it only
//  changes the selection, like the other three.
//  Requires iOS 26+. API: MokoTabBar(selectedTab: $selectedTab)
//

import SwiftUI

enum MokoTab: Hashable {
    case overview
    case quests
    case relax
    case search
}

struct MokoTabBar: View {
    @Binding var selectedTab: MokoTab
    /// Provided by MokoRootView so tapping a tab can switch screens. Nil in standalone previews.
    @Environment(\.mokoTabSelect) private var tabSelect

    // Layout
    private let barWidth: CGFloat = 278
    private let barHeight: CGFloat = 64.5
    private let pillSize = CGSize(width: 90, height: 55)
    /// Pushes the whole bar lower. Raise this to move it further down.
    private let verticalNudge: CGFloat = 10

    private let activeGreen = Color(red: 54/255, green: 89/255, blue: 72/255) // #365948
    private let selectionTint = Color(red: 54/255, green: 89/255, blue: 72/255).opacity(0.14)

    private var tabWidth: CGFloat { barWidth / 3 }

    private var selectedIndex: Int? {
        switch selectedTab {
        case .overview: return 0
        case .quests:   return 1
        case .relax:    return 2
        case .search:   return nil
        }
    }

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                tabCapsule
                searchTab
            }
        }
        .offset(y: verticalNudge)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
    }

    // MARK: - Glass capsule with sliding selection pill
    private var tabCapsule: some View {
        ZStack(alignment: .leading) {
            // Selection pill: one view that slides, hidden while search is selected
            Capsule()
                .fill(Color.clear)
                .frame(width: pillSize.width, height: pillSize.height)
                .glassEffect(.regular.tint(selectionTint), in: Capsule())
                .offset(x: pillOffset)
                .opacity(selectedIndex == nil ? 0 : 1)

            HStack(spacing: 0) {
                tabButton(.overview, label: "Overview", icon: "square.grid.2x2.fill")
                tabButton(.quests, label: "Quests", icon: "list.clipboard.fill")
                tabButton(.relax, label: "Relax", icon: "figure.mind.and.body")
            }
        }
        .frame(width: barWidth, height: barHeight)
        .glassEffect(.regular, in: Capsule())
    }

    private var pillOffset: CGFloat {
        let index = CGFloat(selectedIndex ?? 0)
        return index * tabWidth + (tabWidth - pillSize.width) / 2
    }

    private func tabButton(_ tab: MokoTab, label: String, icon: String) -> some View {
        let tint = selectedTab == tab ? activeGreen : Color.black

        return Button {
            selectedTab = tab
            tabSelect?(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 28, height: 24)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(tint)
            .frame(width: tabWidth, height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MokoNoFeedbackButtonStyle())
    }

    // MARK: - Separate glass search tab (same behavior as the other tabs)
    private var searchTab: some View {
        let isSelected = selectedTab == .search

        return Button {
            selectedTab = .search
            tabSelect?(.search)
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? activeGreen : Color.black)
                .frame(width: 60, height: 60)
                .contentShape(Circle())
        }
        .buttonStyle(MokoNoFeedbackButtonStyle())
        .glassEffect(isSelected ? .regular.tint(selectionTint) : .regular, in: Circle())
    }
}

// MARK: - Environment hook used by MokoRootView to switch screens
private struct MokoTabSelectKey: EnvironmentKey {
    static let defaultValue: ((MokoTab) -> Void)? = nil
}

extension EnvironmentValues {
    var mokoTabSelect: ((MokoTab) -> Void)? {
        get { self[MokoTabSelectKey.self] }
        set { self[MokoTabSelectKey.self] = newValue }
    }
}

// No scale or dimming on press
struct MokoNoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Preview (tab bar on its own)
private struct MokoTabBarPreviewHost: View {
    @State private var tab: MokoTab = .overview

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content behind the bar so the glass has something to refract
            LinearGradient(
                colors: [Color(red: 242/255, green: 242/255, blue: 247/255),
                         Color(red: 200/255, green: 220/255, blue: 208/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            MokoTabBar(selectedTab: $tab)
                .padding(.bottom, 4)
        }
    }
}

#Preview("Tab bar only") {
    MokoTabBarPreviewHost()
}