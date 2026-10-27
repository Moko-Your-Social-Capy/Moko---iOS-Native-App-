import SwiftUI

struct ExploreView: View {
    @Binding var selectedTab: MokoTab
    @State private var searchText = ""
    @State private var showingCustomQuestSetup = false
    @State private var activeCustomQuest: CustomQuest? = nil
    @State private var selectedFilter: QuestCategory = .all

    enum QuestCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case daily = "Daily"
        case social = "Social"
        case calm = "Calm"
        var id: String { rawValue }
    }

    struct CustomQuest: Identifiable {
        let id = UUID()
        var title: String
        var description: String
        var targetMinutes: Int
        var isCompleted: Bool = false
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            let isDark = false // supports theme via AppColors or environment
            AppColors.Light.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explore & Quests")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.Light.primaryText)
                            Text("Level up your social confidence with daily guided missions.")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.Light.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Categories Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(QuestCategory.allCases) { category in
                                Button(action: { selectedFilter = category }) {
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(selectedFilter == category ? .white : AppColors.Light.primaryText)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedFilter == category ? Color.black : AppColors.Light.surface)
                                        )
                                        .shadow(color: AppColors.Light.cardShadow, radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Custom Quest Banner / CTA Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom Quest")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Create your own social interaction milestone.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        Button(action: { showingCustomQuestSetup = true }) {
                            Text(activeCustomQuest == nil ? "Set Up Custom Quest" : "View Active Quest")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0x1B422F)))
                    .padding(.horizontal, 16)

                    // Quests List Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Available Quests")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.Light.primaryText)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            questCard(
                                title: "Coffee Chat Introduction",
                                description: "Initiate a casual 5-minute conversation with a colleague or acquaintance.",
                                duration: "10 min",
                                category: "Social"
                            )

                            questCard(
                                title: "Elevator Small Talk",
                                description: "Greet someone warmly in a shared public space without rushing away.",
                                duration: "5 min",
                                category: "Daily"
                            )

                            questCard(
                                title: "Mindful Box Breathing",
                                description: "Center your nervous system before entering a team meeting.",
                                duration: "3 min",
                                category: "Calm"
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 24)
                }
            }
        }
        .sheet(isPresented: $showingCustomQuestSetup) {
            CustomQuestSetupView(onSave: { quest in
                activeCustomQuest = quest
                showingCustomQuestSetup = false
            })
        }
    }

    private func questCard(title: String, description: String, duration: String, category: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(category)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x1B422F))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: 0x1B422F).opacity(0.12)))

                Spacer()

                Text(duration)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.Light.secondaryText)
            }

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.Light.primaryText)

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(AppColors.Light.secondaryText)
                .lineSpacing(2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.Light.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppColors.Light.cardShadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Custom Quest Setup View
struct CustomQuestSetupView: View {
    var onSave: (ExploreView.CustomQuest) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var targetMinutes = 5

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Quest Details")) {
                    TextField("Quest Title (e.g. Lunch with team)", text: $title)
                    TextField("Goal / Description", text: $description)
                    Stepper("Estimated Duration: \(targetMinutes) min", value: $targetMinutes, in: 1...30)
                }

                Section {
                    Button("Save & Start Quest") {
                        if !title.isEmpty {
                            onSave(ExploreView.CustomQuest(title: title, description: description, targetMinutes: targetMinutes))
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("New Custom Quest")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}
