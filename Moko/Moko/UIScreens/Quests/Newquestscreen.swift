//
//  NewQuestScreen.swift
//  Moko
//
//  Create a custom quest: title and notes are text fields, intensity and category
//  are dropdowns, date and time open inline pickers.
//

import SwiftUI

// MARK: - Dropdown plumbing
enum QuestDropdownField: Hashable {
    case intensity
    case category
}

/// Lets each dropdown row report where it is, so the menu can float over the card.
struct QuestDropdownAnchorKey: PreferenceKey {
    static var defaultValue: [QuestDropdownField: Anchor<CGRect>] = [:]

    static func reduce(value: inout [QuestDropdownField: Anchor<CGRect>],
                       nextValue: () -> [QuestDropdownField: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// The floating options card with a check next to the selected one.
struct QuestDropdown<Option: Hashable>: View {
    let options: [Option]
    let selected: Option
    let label: (Option) -> String
    let onSelect: (Option) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(label(option))
                            .font(.system(size: 16))
                            .foregroundColor(QuestStyle.title)

                        Spacer()

                        if option == selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 46)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
    }
}

// MARK: - Screen
struct NewQuestScreen: View {
    /// Called with the finished quest when "Create Quest" is tapped.
    var onCreate: (Quest) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var intensity: QuestIntensity = .medium
    @State private var category: QuestCategory = .others
    @State private var scheduled: Date = QuestFormat.defaultSchedule()

    @State private var openDropdown: QuestDropdownField?
    @State private var expandedPicker: ExpandedPicker?

    private enum ExpandedPicker {
        case date, time
    }

    private enum Field: Hashable {
        case title, notes
    }

    @FocusState private var focus: Field?

    private let dropdownWidth: CGFloat = 200
    private let labelWidth: CGFloat = 78

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreate: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        ZStack {
            QuestStyle.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(Color(red: 237/255, green: 237/255, blue: 237/255)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Text("New Quest")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(QuestStyle.title)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    detailsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            createButton
        }
        .overlayPreferenceValue(QuestDropdownAnchorKey.self) { anchors in
            dropdownLayer(anchors)
        }
        .animation(.easeInOut(duration: 0.25), value: expandedPicker)
        .onChange(of: focus) { _, newValue in
            if newValue != nil {
                openDropdown = nil
                expandedPicker = nil
            }
        }
    }

    // MARK: Details card
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Details")

            // Title
            HStack(alignment: .center, spacing: 8) {
                rowLabel("Title")
                TextField("Quest title", text: $title)
                    .font(.system(size: 15))
                    .foregroundColor(QuestStyle.title)
                    .focused($focus, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focus = .notes }
            }
            .padding(.vertical, 12)

            divider

            // Notes
            HStack(alignment: .top, spacing: 8) {
                rowLabel("Notes")
                    .padding(.top, 1)
                TextField("Add notes", text: $notes, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(QuestStyle.title)
                    .lineLimit(1...4)
                    .focused($focus, equals: .notes)
            }
            .padding(.vertical, 12)

            divider

            // Intensity and Category dropdowns
            dropdownRow("Intensity", value: intensity.rawValue, field: .intensity)
            divider
            dropdownRow("Category", value: category.rawValue, field: .category)

            sectionTitle("Schedule")
                .padding(.top, 22)

            // Date
            pickerRow("Date", text: QuestFormat.dateText(scheduled), isExpanded: expandedPicker == .date) {
                togglePicker(.date)
            }

            if expandedPicker == .date {
                DatePicker(
                    "",
                    selection: $scheduled,
                    in: Calendar.current.startOfDay(for: Date())...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(QuestStyle.green)
                .transition(.opacity)
            }

            divider

            // Time
            pickerRow("Time", text: QuestFormat.timeText(scheduled), isExpanded: expandedPicker == .time) {
                togglePicker(.time)
            }

            if expandedPicker == .time {
                DatePicker("", selection: $scheduled, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .clipped()
                    .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(QuestStyle.title)
            .padding(.bottom, 4)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(QuestStyle.title)
            .frame(width: labelWidth, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(QuestStyle.divider)
            .frame(height: 1)
    }

    // A row whose value opens a floating dropdown
    private func dropdownRow(_ label: String, value: String, field: QuestDropdownField) -> some View {
        Button {
            focus = nil
            expandedPicker = nil
            openDropdown = (openDropdown == field) ? nil : field
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(QuestStyle.title)

                Spacer()

                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color.black.opacity(0.35))
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .anchorPreference(key: QuestDropdownAnchorKey.self, value: .bounds) { anchor in
            [field: anchor]
        }
    }

    // A row whose value expands an inline date or time picker
    private func pickerRow(_ label: String, text: String, isExpanded: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(QuestStyle.title)

                Spacer()

                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(isExpanded ? QuestStyle.green : QuestStyle.title)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func togglePicker(_ picker: ExpandedPicker) {
        focus = nil
        openDropdown = nil
        expandedPicker = (expandedPicker == picker) ? nil : picker
    }

    // MARK: Floating dropdown
    private func dropdownLayer(_ anchors: [QuestDropdownField: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let field = openDropdown, let anchor = anchors[field] {
                    let rect = proxy[anchor]

                    // Tap anywhere else to close
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture { openDropdown = nil }

                    dropdown(for: field)
                        .frame(width: dropdownWidth)
                        .offset(x: rect.maxX - dropdownWidth, y: rect.maxY + 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .topTrailing)))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: openDropdown)
        }
    }

    @ViewBuilder
    private func dropdown(for field: QuestDropdownField) -> some View {
        switch field {
        case .intensity:
            QuestDropdown(
                options: QuestIntensity.allCases,
                selected: intensity,
                label: { $0.rawValue },
                onSelect: { choice in
                    intensity = choice
                    openDropdown = nil
                }
            )
        case .category:
            QuestDropdown(
                options: QuestCategory.allCases,
                selected: category,
                label: { $0.rawValue },
                onSelect: { choice in
                    category = choice
                    openDropdown = nil
                }
            )
        }
    }

    // MARK: Create
    private var createButton: some View {
        Button {
            createQuest()
        } label: {
            Text("Create Quest")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Capsule().fill(QuestStyle.deepGreen))
        }
        .buttonStyle(.plain)
        .disabled(!canCreate)
        .opacity(canCreate ? 1 : 0.45)
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.2), value: canCreate)
    }

    private func createQuest() {
        guard canCreate else { return }

        let quest = Quest(
            ownerID: CurrentUser.localID,
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            intensity: intensity,
            category: category,
            date: scheduled
        )
        onCreate(quest)
        dismiss()
    }
}

#Preview {
    NewQuestScreen { _ in }
}