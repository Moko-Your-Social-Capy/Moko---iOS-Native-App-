import Foundation

enum MokoPeriod: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

struct CalmActivity: Identifiable {
    let id = UUID()
    let title: String
    let minutes: Int
    let symbol: String
}

struct RadarMetric: Identifiable {
    let id: String
    let title: String
    let value: Int
    let note: String
}

struct BarDatum: Identifiable {
    let id: String
    let label: String
    let minutes: Double
}

enum DemoMokoData {
    static func metrics(for period: MokoPeriod) -> [RadarMetric] {
        let values: [(String, Int, String)]
        switch period {
        case .day:
            values = [
                ("Clarity", 75, "A clear view of what matters today."),
                ("Courage", 66, "Small steps taken outside your comfort zone."),
                ("Presence", 70, "Time spent paying attention to the present."),
                ("Warmth", 78, "Care and connection in your interactions.")
            ]
        case .week:
            values = [
                ("Clarity", 75, "You made space to identify what matters."),
                ("Courage", 70, "You kept showing up for meaningful steps."),
                ("Presence", 66, "A little more room for the present moment."),
                ("Warmth", 78, "You made space for others and yourself.")
            ]
        case .month:
            values = [
                ("Clarity", 78, "Your priorities are becoming more intentional."),
                ("Courage", 72, "You are building momentum through small actions."),
                ("Presence", 74, "You are making more room for the present."),
                ("Warmth", 81, "You are strengthening care and connection.")
            ]
        }
        return values.map { RadarMetric(id: $0.0, title: $0.0, value: $0.1, note: $0.2) }
    }

    static func calmBars(for period: MokoPeriod) -> [BarDatum] {
        let pairs: [(String, Double)]
        switch period {
        case .day:
            pairs = [("Mon", 3), ("Tue", 5), ("Wed", 18), ("Thu", 8), ("Fri", 4), ("Sat", 10), ("Sun", 6)]
        case .week:
            pairs = [("Week 1", 18), ("Week 2", 28), ("Week 3", 42), ("Week 4", 24), ("Week 5", 16)]
        case .month:
            pairs = [("Jan", 18), ("Feb", 26), ("Mar", 42), ("Apr", 22), ("May", 30), ("Jun", 18), ("Jul", 24)]
        }
        return pairs.map { BarDatum(id: $0.0, label: $0.0, minutes: $0.1) }
    }

    static func activities(for period: MokoPeriod) -> [CalmActivity] {
        switch period {
        case .day:
            return [
                CalmActivity(title: "Box Breathing", minutes: 4, symbol: "circle.grid.2x2.fill"),
                CalmActivity(title: "Mirror Reflection", minutes: 6, symbol: "person.crop.rectangle"),
                CalmActivity(title: "Box Breathing", minutes: 4, symbol: "circle.grid.2x2.fill"),
                CalmActivity(title: "Gentle Breathing", minutes: 4, symbol: "wind")
            ]
        case .week:
            return [
                CalmActivity(title: "Box Breathing", minutes: 25, symbol: "circle.grid.2x2.fill"),
                CalmActivity(title: "Mirror Reflection", minutes: 10, symbol: "person.crop.rectangle"),
                CalmActivity(title: "5-4-3-2-1 Grounding", minutes: 15, symbol: "hand.raised.fingers.spread.fill"),
                CalmActivity(title: "Gentle Breathing", minutes: 20, symbol: "wind"),
                CalmActivity(title: "Imagery Guide", minutes: 15, symbol: "photo")
            ]
        case .month:
            return [
                CalmActivity(title: "Box Breathing", minutes: 240, symbol: "circle.grid.2x2.fill"),
                CalmActivity(title: "Mirror Reflection", minutes: 300, symbol: "person.crop.rectangle"),
                CalmActivity(title: "5-4-3-2-1 Grounding", minutes: 420, symbol: "hand.raised.fingers.spread.fill"),
                CalmActivity(title: "Gentle Breathing", minutes: 300, symbol: "wind"),
                CalmActivity(title: "Imagery Guide", minutes: 360, symbol: "photo")
            ]
        }
    }

    static func totalMinutes(for period: MokoPeriod) -> Int {
        switch period {
        case .day: 18
        case .week: 85
        case .month: 1_605
        }
    }

    static func activityCount(for period: MokoPeriod) -> Int {
        switch period {
        case .day: 4
        case .week: 6
        case .month: 5
        }
    }
}
