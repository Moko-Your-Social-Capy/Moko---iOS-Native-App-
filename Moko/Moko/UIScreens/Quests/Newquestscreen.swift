//
//  NewQuestScreen.swift
//  Moko
//
//  Create a custom quest, or edit an existing one (pass `quest`). Saves straight into
//  SwiftData, so the Quests screen (which uses @Query) updates as soon as this closes.
//

import SwiftUI
import SwiftData

struct NewQuestScreen: View {
    /// nil = create a new quest; otherwise edit this one
    var quest: Quest?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var intensity: QuestIntensity
    @State private var category: QuestCategory
    @State private var scheduled: Date

    init(quest: Quest? = nil) {
        self.quest = quest
        _title = State(initialValue: quest?.title ?? "")
        _notes = State(initialValue: quest?.notes ?? "")
        _intensity = State(initialValue: quest?.intensity ?? .medium)
        _category = State(initialValue: quest?.category ?? .others)
        _scheduled = State(initialValue: quest?.date ?? QuestFormat.defaultSchedule())
    }

    private var isEditing: Bool { quest != nil }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// New quests can't be scheduled in the past; an existing one keeps whatever date it has
    private var earliestDate: Date {
        isEditing ? Date.distantPast : Calendar.current.startOfDay(for: Date())
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
                               in: earliestDate...,
                               displayedComponents: .date)

                    DatePicker("Time",
                               selection: $scheduled,
                               displayedComponents: .hourAndMinute)
                }
            }
            .scrollContentBackground(.hidden)
            .background(QuestStyle.screenBg)
            .navigationTitle(isEditing ? "Edit Quest" : "New Quest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(isEditing ? "Save Changes" : "Create Quest", action: save)
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

    private func save() {
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let quest {
            // Editing: update the saved quest in place
            quest.title = trimmedTitle
            quest.notes = cleanNotes
            quest.intensity = intensity
            quest.category = category
            quest.date = scheduled
        } else {
            let newQuest = Quest(
                ownerID: CurrentUser.localID,
                title: trimmedTitle,
                notes: cleanNotes,
                intensity: intensity,
                category: category,
                date: scheduled
            )
            modelContext.insert(newQuest)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview("New") {
    NewQuestScreen()
        .modelContainer(MokoDatabase.preview)
}
