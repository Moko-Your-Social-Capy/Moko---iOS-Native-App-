import SwiftUI

enum InsightsPeriod: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

struct PeriodPicker: View {
    @Binding var selection: InsightsPeriod

    var body: some View {
        Picker("Time period", selection: $selection) {
            ForEach(InsightsPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}
