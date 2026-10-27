import SwiftUI

struct MainHomeContainerView: View {
    @State private var selectedTab: MokoTab = .overview
    var userEmail: String

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "square.grid.2x2.fill", value: MokoTab.overview) {
                Overview(selectedTab: $selectedTab)
            }

            Tab("Quests", systemImage: "clipboard.fill", value: MokoTab.quests) {
                QuestsScreen()
            }

            Tab("Relax", systemImage: "figure.mind.and.body", value: MokoTab.relax) {
                RelaxScreen(selectedTab: $selectedTab)
            }

            Tab("Search", systemImage: "magnifyingglass", value: MokoTab.search, role: .search) {
                SearchView(selectedTab: $selectedTab)
            }
        }
        .tint(Color(red: 27/255, green: 66/255, blue: 47/255))
    }
}
