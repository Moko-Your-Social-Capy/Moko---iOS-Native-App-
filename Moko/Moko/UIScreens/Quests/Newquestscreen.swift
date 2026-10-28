//
//  NewQuestScreen.swift
//  Moko
//
//  Create a custom quest. Saves straight into SwiftData, so the Quests screen
//  (which uses @Query) shows the new quest as soon as this screen closes.
//

import SwiftUI
import SwiftData

struct NewQuestScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var intensity: QuestIntensity = .medium
    @State private var category: QuestCategory = .others
    @State private var scheduled: Date = QuestFormat.defaultSchedule()

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Quest title", text: $title)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)

                    Picker("Intensity", selection: $intensity) {
                        ForEach(QuestIntensity.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(QuestCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.symbol).tag(item)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Date",
                               selection: $scheduled,
                               in: Calendar.current.startOfDay(for: Date())...,
                               displayedComponents: .date)

                    DatePicker("Time",
                               selection: $scheduled,
                               displayedComponents: .hourAndMinute)
                }
            }
            .scrollContentBackground(.hidden)
            .background(QuestStyle.screenBg)
            .navigationTitle("New Quest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Create Quest", action: createQuest)
                    .buttonStyle(.borderedProminent)
                    .tint(QuestStyle.deepGreen)
                    .controlSize(.large)
                    .disabled(trimmedTitle.isEmpty)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
            }
        }
        .tint(QuestStyle.green)
    }

    private func createQuest() {
        let quest = Quest(
            ownerID: CurrentUser.localID,
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            intensity: intensity,
            category: category,
            date: scheduled
        )
        modelContext.insert(quest)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NewQuestScreen()
        .modelContainer(MokoDatabase.preview)
}
