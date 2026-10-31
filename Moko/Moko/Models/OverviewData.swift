//
//  OverviewData.swift
//  Moko
//
//  Real values behind the Overview growth cards. Insights show today's
//  average warmth; Calm Down shows today's total time and the last six days.
//

import Foundation

struct OverviewData {
    let insights: InsightsScores
    /// Minutes spent on calm down exercises today
    let calmDownMinutes: Int
    /// Calm down minutes for the last six days, oldest first
    let calmDownBars: [Double]

    init(insights records: [InsightsModel],
         calmDowns: [CalmDownModel],
         now: Date = .now,
         calendar: Calendar = .current) {
        let todaysInsights = records.filter { calendar.isDate($0.date, inSameDayAs: now) }
        insights = InsightsScores(records: todaysInsights)

        let todaysCalmDowns = calmDowns.filter { calendar.isDate($0.date, inSameDayAs: now) }
        let todaysSeconds = todaysCalmDowns.reduce(0) { $0 + $1.exerciseTime }
        calmDownMinutes = Int((todaysSeconds / 60).rounded())

        calmDownBars = (0..<6).map { index in
            let daysAgo = 5 - index
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
                return 0
            }

            let seconds = calmDowns
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.exerciseTime }

            return seconds / 60
        }
    }
}
