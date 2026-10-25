import SwiftUI

struct SearchView: View {
    @Binding var selectedTab: MokoTab
    @State private var query = ""
    @State private var selectedFilter = "All"

    private let filterOptions = ["All", "Quests", "Relax", "Insights", "Reflections"]

    private let mockResults = [
        SearchResult(title: "Coffee Chat Introduction", category: "Quest", description: "Initiate a casual 5-minute conversation with a colleague."),
        SearchResult(title: "Mindful Box Breathing", category: "Relax", description: "Breathe in, hold, breathe out, and repeat slowly for calm."),
        SearchResult(title: "Warmth & Presence Insights", category: "Analytics", description: "Review your social balance across 4 key interaction metrics."),
        SearchResult(title: "Elevator Small Talk", category: "Quest", description: "Greet someone warmly in a shared public space.")
    ]

    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let category: String
        let description: String
    }

    var filteredResults: [SearchResult] {
        if query.isEmpty {
            return mockResults
        } else {
            return mockResults.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.description.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.Light.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // Header & Search Bar
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search Moko")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.Light.primaryText)

                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.Light.secondaryText)
                            TextField("Search quests, relax, insights...", text: $query)
                                .font(.system(size: 16))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.Light.surface))
                        .shadow(color: AppColors.Light.cardShadow, radius: 4, x: 0, y: 2)

                        if !query.isEmpty {
                            Button("Clear") {
                                query = ""
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.Light.primaryText)
                        }
                    }

                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterOptions, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedFilter == filter ? .white : AppColors.Light.primaryText)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(selectedFilter == filter ? Color.black : AppColors.Light.surface))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Results List
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredResults) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(result.category.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: 0x1B422F))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color(hex: 0x1B422F).opacity(0.12)))

                                    Spacer()
                                }

                                Text(result.title)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AppColors.Light.primaryText)

                                Text(result.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.Light.secondaryText)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.Light.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: AppColors.Light.cardShadow, radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
            }

            MokoTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
    }
}
