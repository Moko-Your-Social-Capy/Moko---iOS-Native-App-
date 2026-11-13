//
//  MirrorAffirmations.swift
//  Moko
//
//  The lines shown during Mirror Reflection, and the sheet that lets the user
//  rewrite them.
//
//  The practice is a fixed 2:00, split evenly across the lines, so the number of
//  slots is what fixes each line's on-screen time: 8 slots x 15 s = 2:00.
//  Both timer screens (mirror and camera) read this one store, so an edit shows
//  up in both and survives relaunches (UserDefaults).
//

import SwiftUI
import Combine

// MARK: - Store

/// Eight affirmation slots, persisted as a plain string array.
///
/// Every slot always holds a non-empty line: blanks fall back to the matching
/// default, which keeps a timer that divides 2:00 by the slot count well defined.
final class MirrorAffirmationStore: ObservableObject {

    static let shared = MirrorAffirmationStore()

    /// Seconds each line stays highlighted. `slotCount * slotDuration` is the
    /// practice length (8 x 15 = 120 s).
    static let slotDuration: TimeInterval = 15
    static let slotCount = 8

    static let defaultQuotes: [String] = [
        "I am good and getting better.",
        "I am growing and I am going at my own pace.",
        "I am held and supported by those who love me.",
        "I am in charge of how I feel and I choose to feel happy.",
        "I am allowed to take up space exactly as I am.",
        "I can be gentle with myself and still want more.",
        "I don't have to earn my own kindness.",
        "I can meet this moment softly, and let it be enough."
    ]

    private static let storageKey = "mirror.affirmations.v1"

    @Published var quotes: [String] {
        didSet { persist() }
    }

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? []
        quotes = Self.normalized(stored)
    }

    /// Forces exactly `slotCount` trimmed, non-empty lines.
    func normalize() {
        let fixed = Self.normalized(quotes)
        if fixed != quotes { quotes = fixed }
    }

    func resetToDefaults() {
        quotes = Self.defaultQuotes
    }

    private static func normalized(_ values: [String]) -> [String] {
        (0..<slotCount).map { index in
            let line = index < values.count
                ? values[index].trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            return line.isEmpty ? defaultQuotes[index] : line
        }
    }

    private func persist() {
        UserDefaults.standard.set(quotes, forKey: Self.storageKey)
    }
}

// MARK: - Edit affordance

/// The session screens don't list all eight lines at once: they show a scrolling
/// window about four rows tall and keep the highlighted line in view. Four is the
/// cap, not a page size -- the rest are one swipe (or 15 s) away.
enum MirrorAffirmationsWindow {
    /// ~4 rows of `moco.type.body` (22 pt line + 10 pt gap) plus padding. Rows that
    /// wrap to two lines trade a row for a line, never more than four blocks.
    static let height: CGFloat = 136
}

/// The small "Edit" pill that opens the editor. Screens hide it while a session
/// is actually running, so the timer can't advance behind the sheet.
struct MirrorEditAffirmationsButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12, weight: .semibold))

                Text("Edit")
                    .mocoText(MocoScreenTheme.Typeface.caption)
            }
            .foregroundColor(MirrorPalette.green)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Capsule().fill(MirrorPalette.chip))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit affirmations")
    }
}

// MARK: - Editor

struct MirrorAffirmationsSheet: View {
    @ObservedObject var store: MirrorAffirmationStore
    @Environment(\.dismiss) private var dismiss

    private var slotSeconds: Int { Int(MirrorAffirmationStore.slotDuration) }

    private var practiceMinutes: String {
        let seconds = Double(MirrorAffirmationStore.slotCount) * MirrorAffirmationStore.slotDuration
        return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("These lines play one at a time during the \(practiceMinutes) practice, \(slotSeconds) seconds each. Rewrite any of them so they sound like you.")
                        .mocoText(MocoScreenTheme.Typeface.body)
                        .foregroundColor(MirrorPalette.subtext)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(store.quotes.indices, id: \.self) { index in
                        editorRow(index)
                    }

                    Button {
                        store.resetToDefaults()
                    } label: {
                        Text("Reset to the default lines")
                            .mocoText(MocoScreenTheme.Typeface.caption)
                            .foregroundColor(MirrorPalette.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, MocoScreenTheme.Space.page)
                .padding(.vertical, 18)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(MocoBackdrop())
            .navigationTitle("Your affirmations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Cross, not a "Cancel" title -- matches the app-wide dismiss convention.
                    Button(role: .close) { close() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { close() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MirrorPalette.green)
                }
            }
        }
    }

    private func editorRow(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Line \(index + 1)")
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .foregroundColor(MirrorPalette.subtext)

                Spacer()

                Text("\(slotSeconds)s")
                    .mocoText(MocoScreenTheme.Typeface.caption)
                    .foregroundColor(MirrorPalette.green.opacity(0.6))
            }

            TextField("Write your affirmation", text: $store.quotes[index], axis: .vertical)
                .mocoText(MocoScreenTheme.Typeface.body)
                .foregroundColor(MirrorPalette.title)
                .tint(MirrorPalette.green)
                .lineLimit(1...3)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MocoScreenTheme.Space.cardHorizontal)
        .mocoCard()
    }

    /// Edits persist as they're typed; this only tidies blanks left behind.
    private func close() {
        store.normalize()
        dismiss()
    }
}

#Preview("Affirmations editor") {
    MirrorAffirmationsSheet(store: .shared)
}
