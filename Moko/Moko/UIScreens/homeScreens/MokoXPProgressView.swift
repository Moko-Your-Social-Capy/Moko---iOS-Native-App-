import SwiftUI
import SwiftData

enum MokoXPProgressSize: Equatable {
    case compact
    case profile
}

struct MokoXPProgressView: View {
    let xp: Int
    var size: MokoXPProgressSize = .compact
    var onLevelUp: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: CGFloat = 0
    @State private var displayedXP = 0
    @State private var rewardLabel: String?
    @State private var shine = false
    @State private var unlockedCostume: MokoCostume?

    private var level: Int { max(0, xp) / 400 + 1 }
    private var levelXP: Int { max(0, xp) % 400 }
    private var progress: CGFloat { CGFloat(levelXP) / 400 }
    private var isProfileSize: Bool { size == .profile }
    private var textColor: Color { colorScheme == .dark ? Color(hex: 0xF7F0E6) : ProfilePalette.text }
    private var secondaryColor: Color { colorScheme == .dark ? Color(hex: 0xDDD5C9).opacity(0.82) : ProfilePalette.secondary }
    private var trackColor: Color { colorScheme == .dark ? Color(hex: 0x365246) : ProfilePalette.midGreen.opacity(0.26) }

    var body: some View {
        VStack(alignment: .leading, spacing: isProfileSize ? 11 : 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Level \(level)")
                    .font(isProfileSize ? .system(.headline, design: .rounded, weight: .bold) : .system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(textColor)

                Spacer(minLength: 8)

                Text("\(levelXP) / 400 XP")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(secondaryColor)
                    .contentTransition(.numericText())
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(trackColor)
                    Capsule()
                        .fill(ProfilePalette.accent)
                        .frame(width: proxy.size.width * animatedProgress)
                        .overlay(alignment: .leading) {
                            if !reduceMotion {
                                Capsule()
                                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.52), .clear], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: 44)
                                    .offset(x: shine ? proxy.size.width : -44)
                                    .blendMode(.screen)
                                    .clipShape(Capsule())
                            }
                        }
                        .clipShape(Capsule())
                }
                .clipShape(Capsule())
            }
            .frame(height: 14)
            .accessibilityElement()
            .accessibilityLabel("Level \(level) progress")
            .accessibilityValue("\(levelXP) of 400 XP")

            if isProfileSize {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.caption2.weight(.bold))
                    Text("\(max(0, 400 - levelXP)) XP to Level \(level + 1)")
                        .font(.caption)
                }
                .foregroundStyle(secondaryColor)
            }
        }
        .padding(isProfileSize ? 14 : 12)
        .background((colorScheme == .dark ? Color(hex: 0x294335) : ProfilePalette.lightGreen.opacity(0.42)), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if let rewardLabel {
                Text(rewardLabel)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(ProfilePalette.accent, in: Capsule())
                    .offset(y: -18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityLabel("Earned \(rewardLabel)")
            }
        }
        .onAppear {
            displayedXP = xp
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.7, dampingFraction: 0.78)) {
                animatedProgress = progress
            }
            guard !reduceMotion else { return }
            shine = false
            withAnimation(.linear(duration: 1.1).delay(0.2)) { shine = true }
        }
        .onChange(of: xp) { oldValue, newValue in
            let gained = max(0, newValue - oldValue)
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.68, dampingFraction: 0.76)) {
                animatedProgress = CGFloat(max(0, newValue) % 400) / 400
                displayedXP = newValue
                rewardLabel = gained > 0 ? "+\(gained) XP" : nil
            }

            if gained > 0 {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(reduceMotion ? 0.8 : 1.35))
                    withAnimation(.easeOut(duration: 0.2)) { rewardLabel = nil }
                }
            }

            let previousLevel = max(0, oldValue) / 400 + 1
            let updatedLevel = max(0, newValue) / 400 + 1
            if updatedLevel > previousLevel,
               let costume = MokoCostume.all.first(where: { $0.level == updatedLevel }) {
                onLevelUp?()
                if reduceMotion {
                    unlockedCostume = costume
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        unlockedCostume = costume
                    }
                }
            }
        }
        .sheet(item: $unlockedCostume) { costume in
            MokoCostumeUnlockSheet(costume: costume, level: level)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct MokoWeeklyXPStrip: View {
    let quests: [Quest]
    let streak: Int
    let lastActivityDate: Date?

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var practiceDays: Set<Date> {
        let calendar = Calendar.current
        let questDays = quests.filter(\.isCompleted).map { calendar.startOfDay(for: $0.completedAt ?? $0.date) }
        return Set(questDays + (lastActivityDate.map { [calendar.startOfDay(for: $0)] } ?? []))
    }

    private func isRestDay(_ day: Date) -> Bool {
        guard streak >= 7, streak.isMultiple(of: 7), let lastActivityDate else { return false }
        let calendar = Calendar.current
        let lastDay = calendar.startOfDay(for: lastActivityDate)
        let today = calendar.startOfDay(for: .now)
        guard let restDay = calendar.date(byAdding: .day, value: 1, to: lastDay),
              calendar.isDate(restDay, inSameDayAs: day),
              let daysSinceActivity = calendar.dateComponents([.day], from: lastDay, to: today).day else { return false }
        return daysSinceActivity == 1 || daysSinceActivity == 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("THIS WEEK")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(ProfilePalette.secondary)
                Spacer()
                Label("Rest is okay", systemImage: "circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2)
                    .foregroundStyle(ProfilePalette.secondary)
            }

            HStack(spacing: 7) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    let active = practiceDays.contains(Calendar.current.startOfDay(for: day))
                    let rest = isRestDay(day)
                    VStack(spacing: 5) {
                        Capsule()
                            .fill(active ? ProfilePalette.success : (rest ? ProfilePalette.midGreen : ProfilePalette.midGreen.opacity(0.22)))
                            .frame(height: 7)
                            .overlay {
                                if rest {
                                    Circle().fill(ProfilePalette.accent).frame(width: 5, height: 5)
                                }
                            }
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(.caption2, design: .rounded, weight: Calendar.current.isDateInToday(day) ? .bold : .regular))
                            .foregroundStyle(ProfilePalette.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(active ? "practice complete" : (rest ? "rest day" : "no practice recorded"))")
                }
            }
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .contain)
    }
}

private struct MokoCostumeUnlockSheet: View {
    let costume: MokoCostume
    let level: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("moko.selectedCostumeLevel") private var selectedCostumeLevel = 1
    @State private var hopped = false

    var body: some View {
        VStack(spacing: 10) {
            Image(costume.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 122, height: 122)
                .offset(y: hopped ? -8 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.46).repeatCount(2, autoreverses: true), value: hopped)
                .accessibilityLabel("Moko wearing the newly unlocked \(costume.name) costume")

            Text("Level Up!")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(ProfilePalette.text)
            Text("You reached Level \(level). \(costume.name) is now in Moko’s wardrobe.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ProfilePalette.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button {
                selectedCostumeLevel = costume.level
                dismiss()
            } label: {
                Text("Equip costume")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(ProfilePalette.accent, in: Capsule())
            }
            .buttonStyle(MokoPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .background(AppBackground())
        .onAppear { hopped = true }
    }
}
