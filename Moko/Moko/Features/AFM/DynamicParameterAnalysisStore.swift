//
//  DynamicParameterAnalysisStore.swift
//  Moko
//
//  Manages dynamic AFM-generated parameter analyses for Courage, Clarity, Presence,
//  and Warmth. Caches results in UserDefaults and updates reactively whenever
//  new scores or debriefs are recorded.
//

import Foundation
import SwiftUI
import OSLog

@MainActor
@Observable
final class DynamicParameterAnalysisStore {
    static let shared = DynamicParameterAnalysisStore()

    // Cached analysis text keyed by Stat.
    var cachedAnalysis: [Stat: String] = [:]
    
    // Tracks the hash of scores last analyzed by AFM to prevent redundant calls.
    private var lastAnalyzedScoreHash: String = ""

    private let defaults = UserDefaults.standard
    private let keyPrefix = "moko.dynamic.analysis."
    private let lastHashKey = "moko.dynamic.analysis.lastHash"

    init() {
        loadFromCache()
    }

    /// Loads persisted analysis text from UserDefaults.
    private func loadFromCache() {
        for stat in Stat.allCases {
            if let saved = defaults.string(forKey: keyPrefix + stat.rawValue), !saved.isEmpty {
                cachedAnalysis[stat] = saved
            }
        }
        lastAnalyzedScoreHash = defaults.string(forKey: lastHashKey) ?? ""
    }

    /// Returns the AFM-generated analysis for a stat, or a dynamic score-tailored fallback.
    func analysis(for stat: Stat, score: Double, band: Band) -> String {
        if let current = cachedAnalysis[stat], !current.isEmpty {
            return current
        }
        return dynamicFallback(for: stat, score: score, band: band)
    }

    /// Refreshes the AFM parameter analyses if scores have changed or no analysis exists yet.
    func refreshAnalysisIfNeeded(scores: InsightsScores, recentObservations: [String] = []) async {
        let roundedCourage = Int(scores.courage.rounded())
        let roundedClarity = Int(scores.clarity.rounded())
        let roundedPresence = Int(scores.presence.rounded())
        let roundedWarmth = Int(scores.warmth.rounded())

        let currentHash = "\(roundedCourage)-\(roundedClarity)-\(roundedPresence)-\(roundedWarmth)"
        guard currentHash != lastAnalyzedScoreHash || cachedAnalysis.count < 4 else { return }

        guard AFM.isAvailable else {
            // AFM unavailable on this device; populate dynamic fallbacks.
            populateDynamicFallbacks(scores: scores)
            return
        }

        do {
            let report = try await AFM.generate(
                ParametersAnalysisReport.self,
                instructions: DebriefPrompts.insightsReportInstructions,
                prompt: DebriefPrompts.insightsReportPrompt(
                    courage: scores.courage,
                    clarity: scores.clarity,
                    presence: scores.presence,
                    warmth: scores.warmth,
                    recentHighlights: recentObservations
                ),
                temperature: 0.4
            )

            let cText = report.courageAnalysis.trimmingCharacters(in: .whitespacesAndNewlines)
            let clText = report.clarityAnalysis.trimmingCharacters(in: .whitespacesAndNewlines)
            let pText = report.presenceAnalysis.trimmingCharacters(in: .whitespacesAndNewlines)
            let wText = report.warmthAnalysis.trimmingCharacters(in: .whitespacesAndNewlines)

            if !cText.isEmpty { updateStat(.courage, text: cText) }
            if !clText.isEmpty { updateStat(.clarity, text: clText) }
            if !pText.isEmpty { updateStat(.presence, text: pText) }
            if !wText.isEmpty { updateStat(.warmth, text: wText) }

            lastAnalyzedScoreHash = currentHash
            defaults.set(currentHash, forKey: lastHashKey)
        } catch {
            Logger.afm.warning("Dynamic parameter analysis generation skipped: \(error.localizedDescription)")
            if cachedAnalysis.isEmpty {
                populateDynamicFallbacks(scores: scores)
            }
        }
    }

    /// Updates one stat in memory and persists to UserDefaults.
    private func updateStat(_ stat: Stat, text: String) {
        cachedAnalysis[stat] = text
        defaults.set(text, forKey: keyPrefix + stat.rawValue)
    }

    /// Generates dynamic score-tailored fallback text when AFM is unavailable.
    private func populateDynamicFallbacks(scores: InsightsScores) {
        let statsWithScores: [(Stat, Double)] = [
            (.courage, scores.courage),
            (.clarity, scores.clarity),
            (.presence, scores.presence),
            (.warmth, scores.warmth)
        ]
        for (stat, score) in statsWithScores {
            let band = Band(score: Int(score.rounded()))
            updateStat(stat, text: dynamicFallback(for: stat, score: score, band: band))
        }
    }

    /// Dynamic score-tailored copy that references the actual score level.
    private func dynamicFallback(for stat: Stat, score: Double, band: Band) -> String {
        let rounded = Int(score.rounded())
        switch stat {
        case .courage:
            switch band {
            case .strength:
                return "At \(rounded)%, you consistently step forward into unfamiliar moments. Keep building momentum by speaking first."
            case .steady:
                return "Holding steady at \(rounded)%. Taking initiative just a few seconds earlier will help carry your confidence into high-stakes moments."
            case .growth:
                return "Currently at \(rounded)%. Starting an interaction can feel daunting—try taking one small initial step like a brief greeting."
            }
        case .clarity:
            switch band {
            case .strength:
                return "With a solid \(rounded)%, you communicate directly and concisely. Continue trusting your core message without over-qualifying."
            case .steady:
                return "Scoring \(rounded)%. Leading with your main point before offering context will make your delivery even sharper."
            case .growth:
                return "At \(rounded)%. Practicing a single, clear sentence without over-explaining is an effective way to strengthen your voice."
            }
        case .presence:
            switch band {
            case .strength:
                return "Remarkable focus at \(rounded)%. Tuning into concrete details of the other person keeps your interactions effortless."
            case .steady:
                return "Grounded at \(rounded)%. When you notice yourself rehearsing what to say next, anchoring on the other person's voice brings you right back."
            case .growth:
                return "Currently \(rounded)%. Replaying moments in your head is natural; focusing on one physical detail around you helps stay present."
            }
        case .warmth:
            switch band {
            case .strength:
                return "Vibrant warmth at \(rounded)%. Your curiosity and openness make others feel immediately valued and comfortable."
            case .steady:
                return "At \(rounded)%, you bring welcoming energy. Adding an authentic follow-up question deepens casual chats into genuine connection."
            case .growth:
                return "At \(rounded)%. Sharing one small genuine detail with someone you trust is a gentle way to cultivate openness."
            }
        }
    }
}
