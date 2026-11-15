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
    /// nil = create a new quest; otherwise edit this one.
    var quest: Quest?

    // SwiftData's "save box". Inserting or editing a quest goes through it.
    @Environment(\.modelContext) private var modelContext
    // Closes this full-screen cover.
    @Environment(\.dismiss) private var dismiss

    // The form fields. They start with the quest's values (or defaults) and are
    // only copied back onto the quest when the user taps Save.
    @State private var title: String
    @State private var notes: String
    @State private var intensity: QuestIntensity
    @State private var category: QuestCategory
    @State private var scheduled: Date

    init(quest: Quest? = nil) {
        self.quest = quest
        // `_title = State(initialValue:)` sets the starting value of an @State from init.
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

    /// New quests can't be scheduled in the past; an existing one keeps whatever date it has.
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
                .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)

                Section("Schedule") {
                    // Both pickers edit the same `scheduled` date: one the day, one the time.
                    DatePicker("Date",
                               selection: $scheduled,
                               in: earliestDate...,
                               displayedComponents: .date)

                    DatePicker("Time",
                               selection: $scheduled,
                               displayedComponents: .hourAndMinute)
                }
                .listRowBackground(MokoScreenTheme.Colors.surfaceWhite)
            }
            .mokoText(MokoScreenTheme.Typeface.body)
            .foregroundStyle(MokoScreenTheme.Colors.textTitle)
            .textCase(nil)
            .scrollContentBackground(.hidden)
            .background { MokoBackdrop() }
            .navigationTitle(isEditing ? "Edit Quest" : "New Quest")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // The screen is a full-screen cover, so the leading control is the system
                    // cross that closes it rather than a "Cancel" title.
                    Button(role: .close) { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
            // Pins the button to the bottom, above the keyboard and home indicator.
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text(isEditing ? "Save Changes" : "Create Quest")
                        .mokoText(MokoScreenTheme.Typeface.slider)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(QuestStyle.accent)
                .controlSize(.large)
                .disabled(trimmedTitle.isEmpty)
                .padding(.horizontal, MokoScreenTheme.Space.page)
                .padding(.bottom, 12)
            }
        }
        .tint(QuestStyle.accent)
    }

    /// Copies the form onto the quest (or creates a new one) and closes the screen.
    private func save() {
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let quest {
            // Editing: update the saved quest in place.
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

        modelContext.saveOrLog(isEditing ? "edited quest" : "new quest")
        dismiss()
    }
}

#Preview("New") {
    NewQuestScreen()
        .modelContainer(MokoDatabase.preview)
}
