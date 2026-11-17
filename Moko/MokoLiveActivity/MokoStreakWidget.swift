import WidgetKit
import SwiftUI

// Home Screen streak widget. Uses the same streak snapshot source written by the app.
// Flame in widget is a static symbol/image representation (WidgetKit cannot run Lottie continuously).

private struct MokoStreakEntry: TimelineEntry {
    let date: Date
    let snapshot: MokoStreakWidgetSnapshot
}

private struct MokoStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> MokoStreakEntry {
        MokoStreakEntry(date: .now, snapshot: .empty)
    }
    func getSnapshot(in context: Context, completion: @escaping (MokoStreakEntry) -> Void) {
        completion(MokoStreakEntry(date: .now, snapshot: MokoStreakWidgetSnapshot.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MokoStreakEntry>) -> Void) {
        let snapshot = MokoStreakWidgetSnapshot.load()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [MokoStreakEntry(date: .now, snapshot: snapshot)], policy: .after(next)))
    }
}

private struct MokoStreakTheme {
    let leftTop: Color
    let leftBottom: Color
    let leftText: Color
    let rightBg: Color
    let rightText: Color
    let muted: Color
    let flame: Color

    static func resolve(_ scheme: ColorScheme) -> MokoStreakTheme {
        // Widgets have no SwiftUI environment theme; read the app’s saved MOKO theme name.
        let raw = UserDefaults.standard.string(forKey: "moko.theme.selected") ?? "default"
        switch raw {
        case "lavender":
            return MokoStreakTheme(
                leftTop: Color(red: 0.75, green: 0.60, blue: 0.95),
                leftBottom: Color(red: 0.48, green: 0.23, blue: 0.93),
                leftText: .white,
                rightBg: Color(red: 0.15, green: 0.13, blue: 0.20),
                rightText: .white,
                muted: Color.white.opacity(0.58),
                flame: Color(red: 1.0, green: 0.55, blue: 0.30)
            )
        case "ocean":
            return MokoStreakTheme(
                leftTop: Color(red: 0.55, green: 0.75, blue: 0.67),
                leftBottom: Color(red: 0.30, green: 0.49, blue: 0.67),
                leftText: Color(red: 0.10, green: 0.18, blue: 0.24),
                rightBg: Color(red: 0.12, green: 0.15, blue: 0.19),
                rightText: .white,
                muted: Color.white.opacity(0.55),
                flame: Color(red: 1.0, green: 0.55, blue: 0.25)
            )
        case "blossom":
            return MokoStreakTheme(
                leftTop: Color(red: 0.99, green: 0.65, blue: 0.78),
                leftBottom: Color(red: 0.76, green: 0.28, blue: 0.67),
                leftText: .white,
                rightBg: Color(red: 0.17, green: 0.12, blue: 0.15),
                rightText: .white,
                muted: Color.white.opacity(0.55),
                flame: Color(red: 1.0, green: 0.60, blue: 0.20)
            )
        case "midnight":
            return MokoStreakTheme(
                leftTop: Color(red: 0.55, green: 0.68, blue: 1.0),
                leftBottom: Color(red: 0.22, green: 0.29, blue: 0.68),
                leftText: .white,
                rightBg: Color(red: 0.09, green: 0.11, blue: 0.16),
                rightText: .white,
                muted: Color.white.opacity(0.55),
                flame: Color(red: 1.0, green: 0.55, blue: 0.20)
            )
        case "batman":
            return MokoStreakTheme(
                leftTop: Color(red: 0.00, green: 0.75, blue: 0.70),
                leftBottom: Color(red: 0.00, green: 0.42, blue: 0.38),
                leftText: .white,
                rightBg: Color(red: 0.07, green: 0.07, blue: 0.07),
                rightText: .white,
                muted: Color.white.opacity(0.55),
                flame: Color(red: 1.0, green: 0.45, blue: 0.15)
            )
        default:
            if scheme == .dark {
                return MokoStreakTheme(
                    leftTop: Color(red: 0.18, green: 0.43, blue: 0.29),
                    leftBottom: Color(red: 0.10, green: 0.30, blue: 0.22),
                    leftText: .white,
                    rightBg: Color(red: 0.11, green: 0.11, blue: 0.12),
                    rightText: .white,
                    muted: Color.white.opacity(0.55),
                    flame: Color(red: 1.0, green: 0.55, blue: 0.2)
                )
            } else {
                return MokoStreakTheme(
                    leftTop: Color(red: 0.86, green: 0.95, blue: 0.73),
                    leftBottom: Color(red: 0.62, green: 0.82, blue: 0.52),
                    leftText: Color(red: 0.11, green: 0.26, blue: 0.18),
                    rightBg: Color(red: 0.10, green: 0.10, blue: 0.11),
                    rightText: .white,
                    muted: Color.white.opacity(0.55),
                    flame: Color(red: 1.0, green: 0.45, blue: 0.1)
                )
            }
        }
    }
}

private struct MokoStreakWidgetView: View {
    var entry: MokoStreakEntry
    @Environment(\.colorScheme) private var scheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let theme = MokoStreakTheme.resolve(scheme)
        Group {
            switch family {
            case .systemSmall:
                small(theme)
            case .systemLarge:
                large(theme)
            default:
                medium(theme)
            }
        }
        .widgetURL(URL(string: "moko://streak"))
    }

    private func small(_ t: MokoStreakTheme) -> some View {
        ZStack {
            LinearGradient(colors: [t.leftTop, t.leftBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 6) {
                Image(systemName: "flame.fill").font(.system(size: 28)).foregroundStyle(t.flame)
                Text("\(entry.snapshot.currentStreak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(t.leftText)
                Text("DAY STREAK")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(t.leftText.opacity(0.85))
            }
        }
    }

    private func medium(_ t: MokoStreakTheme) -> some View {
        HStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [t.leftTop, t.leftBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "flame.fill").font(.system(size: 26)).foregroundStyle(t.flame)
                    Text("\(entry.snapshot.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(t.leftText)
                    Text("DAY STREAK")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(t.leftText.opacity(0.9))
                    Text("Keep your rhythm")
                        .font(.caption2)
                        .foregroundStyle(t.leftText.opacity(0.8))
                    if entry.snapshot.longestStreak > 0 {
                        Text("Best \(entry.snapshot.longestStreak)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(t.leftText.opacity(0.75))
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.snapshot.week.prefix(7)) { day in
                    HStack(spacing: 8) {
                        Text(day.shortLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(t.muted)
                            .frame(width: 34, alignment: .leading)
                        Image(systemName: icon(for: day.status))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(color(for: day.status, t: t))
                            .frame(width: 14)
                        Text(label(for: day.status))
                            .font(.caption2)
                            .foregroundStyle(day.status == .completed ? t.rightText : t.muted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(t.rightBg)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func large(_ t: MokoStreakTheme) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Current streak").font(.caption).foregroundStyle(.secondary)
                    Text("\(entry.snapshot.currentStreak) days").font(.system(size: 34, weight: .bold, design: .rounded))
                }
                Spacer()
                Image(systemName: "flame.fill").font(.system(size: 34)).foregroundStyle(t.flame)
            }
            .padding()
            .background(LinearGradient(colors: [t.leftTop, t.leftBottom], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("This week").font(.headline)
                ForEach(entry.snapshot.week) { day in
                    HStack {
                        Text(day.shortLabel).font(.subheadline.weight(.medium)).frame(width: 44, alignment: .leading)
                        Image(systemName: icon(for: day.status)).foregroundStyle(color(for: day.status, t: t))
                        Text(label(for: day.status)).font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                    }
                    Divider()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(8)
    }

    private func icon(for status: MokoStreakWidgetSnapshot.Day.Status) -> String {
        switch status {
        case .completed: return "flame.fill"
        case .missed: return "circle"
        case .upcoming: return "circle.dotted"
        case .todayPending: return "flame"
        }
    }
    private func label(for status: MokoStreakWidgetSnapshot.Day.Status) -> String {
        switch status {
        case .completed: return "Completed"
        case .missed: return "Missed"
        case .upcoming: return "Upcoming"
        case .todayPending: return "Today"
        }
    }
    private func color(for status: MokoStreakWidgetSnapshot.Day.Status, t: MokoStreakTheme) -> Color {
        switch status {
        case .completed, .todayPending: return t.flame
        default: return t.muted
        }
    }
}

struct MokoStreakWidget: Widget {
    let kind = "MokoStreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MokoStreakProvider()) { entry in
            if #available(iOS 17.0, *) {
                MokoStreakWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MokoStreakWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Moko Streak")
        .description("Current streak and this week’s activity.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
