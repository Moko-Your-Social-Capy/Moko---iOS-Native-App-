//
//  DebriefScoring.swift
//  Moko
//
//  Pure score maths for accepted debrief answers. Missing evidence stays missing.
//

import Foundation

enum DebriefScoring {
    /// The opening needs any usable evidence; a follow-up needs its selected stat.
    static func hasRequiredEvidence(_ evidence: [DebriefParameter: DebriefEvidenceLevel],
                                    focus: DebriefParameter?) -> Bool {
        if let focus {
            guard let level = evidence[focus] else { return false }
            return level != .missing
        }
        return DebriefParameter.allCases.contains { parameter in
            guard let level = evidence[parameter] else { return false }
            return level != .missing
        }
    }

    /// Averages each stat using evidence strength and question-relevance confidence as weights.
    /// Confidence weights independent scores; it never adds to or subtracts from their values.
    /// The only rounding happens once, after the full-precision average is calculated.
    static func finalScores(from grades: [DebriefGrade]) -> [DebriefParameter: Int] {
        var result: [DebriefParameter: Int] = [:]

        for parameter in DebriefParameter.allCases {
            var weightedTotal = 0.0
            var totalWeight = 0.0

            for grade in grades {
                guard let score = grade.parameterScores[parameter],
                      let evidence = grade.parameterEvidence[parameter],
                      evidence != .missing else { continue }

                // Relevance changes an accepted answer's weight, never its independent stat score.
                let relevanceWeight = 0.5 + Double(grade.confidence) / 200
                let weight = evidence.weight * relevanceWeight
                weightedTotal += Double(score) * weight
                totalWeight += weight
            }

            if totalWeight > 0 {
                result[parameter] = Int((weightedTotal / totalWeight).rounded())
            }
        }

        return result
    }

    /// Targets a missing stat first, then the stat with the least evidence and lowest score.
    /// This lets the opening and three accepted follow-ups cover all four stats.
    static func nextFocus(from grades: [DebriefGrade]) -> DebriefParameter {
        let missing = DebriefParameter.allCases.filter { parameter in
            evidenceWeight(for: parameter, grades: grades) == 0
        }
        if let firstMissing = missing.first { return firstMissing }

        let scores = finalScores(from: grades)
        var best: DebriefParameter?
        for parameter in DebriefParameter.allCases {
            guard let currentBest = best else {
                best = parameter
                continue
            }
            let weight = evidenceWeight(for: parameter, grades: grades)
            let bestWeight = evidenceWeight(for: currentBest, grades: grades)
            if weight != bestWeight {
                if weight < bestWeight { best = parameter }
                continue
            }
            if (scores[parameter] ?? -1) < (scores[currentBest] ?? -1) {
                best = parameter
            }
        }
        return best ?? .courage
    }

    /// Counts only real score-and-evidence pairs when deciding what still needs a question.
    private static func evidenceWeight(for parameter: DebriefParameter,
                                       grades: [DebriefGrade]) -> Double {
        grades.reduce(0.0) { total, grade in
            guard grade.parameterScores[parameter] != nil,
                  let evidence = grade.parameterEvidence[parameter],
                  evidence != .missing else { return total }
            return total + evidence.weight
        }
    }

    /// Compact facts for AFM's next-question decision; rejected answers never reach this list.
    static func evidenceSummary(from grades: [DebriefGrade]) -> [String] {
        DebriefParameter.allCases.map { parameter in
            let observations = grades.flatMap { grade -> [String] in
                guard let score = grade.parameterScores[parameter],
                      let evidence = grade.parameterEvidence[parameter],
                      evidence != .missing else { return [] }
                return ["\(score)/100 \(evidence.rawValue) evidence"]
            }
            return "\(parameter.rawValue): \(observations.isEmpty ? "no evidence" : observations.joined(separator: ", "))"
        }
    }
}
