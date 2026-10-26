import SwiftUI

/// The four tabs of the app.
enum AppTab: Hashable {
    case overview, quests, relax, search

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .quests:   return "Quests"
        case .relax:    return "Relax"
        case .search:   return "Search"
        }
    }

    var icon: String {          // SF Symbols
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .quests:   return "list.clipboard.fill"
        case .relax:    return "figure.mind.and.body"
        case .search:   return "magnifyingglass"
        }
    }
}

/// Floating tab bar from the Figma: a capsule with three tabs, plus a separate round Search button.
struct AppTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var pillSpace

    private let mainTabs: [AppTab] = [.overview, .quests, .relax]

    var body: some View {
        HStack(spacing: 16) {
            // Capsule with Overview / Quests / Relax
            HStack(spacing: 0) {
                ForEach(mainTabs, id: \.self) { tab in
                    tabItem(tab)
                }
            }
            .padding(4)
            .frame(width: 278, height: 65)
            .tabBarGlass(in: Capsule())

            // Separate round Search button (icon only)
            Button {
                withAnimation(.snappy(duration: 0.25)) { selection = .search }
            } label: {
                Image(systemName: AppTab.search.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(selection == .search ? BBColor.button : .black)
                    .frame(width: 60, height: 60)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .tabBarGlass(in: Circle())
            .accessibilityLabel("Search")
            .accessibilityAddTraits(selection == .search ? .isSelected : [])
        }
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            withAnimation(.snappy(duration: 0.25)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .frame(height: 26)
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? BBColor.button : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 57)
            .background {
                if isSelected {
                    // The grey pill slides between tabs
                    Capsule()
                        .fill(Color(hex: 0xEDEDED))
                        .matchedGeometryEffect(id: "pill", in: pillSpace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Glass look

private extension View {
    /// iOS 26+ liquid glass; a frosted material on older versions.
    @ViewBuilder
    func tabBarGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.5), lineWidth: 0.5))
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(hex: 0xF2F2F7).ignoresSafeArea()
        AppTabBar(selection: .constant(.relax))
            .padding(.bottom, 20)
    }
}
