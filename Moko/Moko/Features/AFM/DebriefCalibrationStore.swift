//
//  DebriefCalibrationStore.swift
//  Moko
//
//  Privacy-friendly local samples for checking whether AFM scores are calibrated.
//

import Foundation
import OSLog

@MainActor
enum DebriefCalibrationStore {
    struct Sample: Codable, Equatable {
        var id = UUID()
        var date = Date()
        var rubricVersion = 1
        var questCategory: String
        var focus: String?
        var inputCategory: String
        var confidence: Int
        var scores: [String: Int]
        var evidence: [String: String]
    }

    struct Summary: Equatable {
        var count: Int
        var mean: Double
        var standardDeviation: Double
        var minimum: Int
        var maximum: Int
    }

    private static let key = "moko.debriefCalibration.v1"
    private static let maximumSampleCount = 200

    /// Stores score metadata only: no answer text, names, transcripts or coach notes.
    static func record(_ grade: DebriefGrade, questCategory: QuestCategory,
                       defaults: UserDefaults = .standard) {
        let sample = Sample(
            questCategory: questCategory.rawValue,
            focus: grade.focus?.rawValue,
            inputCategory: grade.category.rawValue,
            confidence: grade.confidence,
            scores: Dictionary(uniqueKeysWithValues: grade.parameterScores.map { ($0.key.rawValue, $0.value) }),
            evidence: Dictionary(uniqueKeysWithValues: grade.parameterEvidence.map { ($0.key.rawValue, $0.value.rawValue) })
        )
        var stored = samples(from: defaults)
        stored.append(sample)
        stored = Array(stored.suffix(maximumSampleCount))
        guard let data = try? JSONEncoder().encode(stored) else { return }
        defaults.set(data, forKey: key)
    }

    static func samples(from defaults: UserDefaults = .standard) -> [Sample] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Sample].self, from: data)) ?? []
    }

    /// Count, spread and range make a 78 versus a 72 auditable against the same rubric.
    static func summary(for parameter: DebriefParameter,
                        defaults: UserDefaults = .standard) -> Summary? {
        let values = samples(from: defaults).compactMap { sample -> Int? in
            guard sample.evidence[parameter.rawValue] != DebriefEvidenceLevel.missing.rawValue else { return nil }
            return sample.scores[parameter.rawValue]
        }
        guard let minimum = values.min(), let maximum = values.max(), !values.isEmpty else { return nil }

        let mean = values.reduce(0.0) { $0 + Double($1) } / Double(values.count)
        let variance = values.reduce(0.0) { partial, value in
            let difference = Double(value) - mean
            return partial + difference * difference
        } / Double(values.count)
        return Summary(
            count: values.count,
            mean: mean,
            standardDeviation: variance.squareRoot(),
            minimum: minimum,
            maximum: maximum
        )
    }

    static func logSummary() {
        for parameter in DebriefParameter.allCases {
            guard let summary = summary(for: parameter) else { continue }
            Logger.afm.info("Calibration \(parameter.rawValue, privacy: .public): n=\(summary.count), mean=\(summary.mean, privacy: .public), sd=\(summary.standardDeviation, privacy: .public), range=\(summary.minimum)...\(summary.maximum)")
        }
    }
}
