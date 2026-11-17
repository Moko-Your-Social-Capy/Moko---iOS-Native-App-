import Foundation
import SwiftUI
import Lottie

/// Central place to locate and load the supplied animation assets.
enum MokoAnimationAssets {
    // Inline/small loading (Lottie JSON).
    static let inlineLoaderName = "loading"

    // Full-screen loading illustration (SVG with SMIL animation). "CI2" asset in project.
    static let fullScreenLoadingSVG = "moko-moonwalk-loading"

    // Universal completion illustration (SVG with SMIL animation).
    static let tickCompleteSVG = "moko-tick-complete"

    /// Cached Lottie animation for the inline loader to avoid repeated decoding.
    static let inlineLoaderAnimation: LottieAnimation? = LottieAnimation.named(inlineLoaderName)

    /// Cached SVG sources to avoid repeated disk reads.
    private static var svgCache: [String: String] = [:]
    private static let svgLock = NSLock()

    /// Loads an SVG file from the bundle as a String (cached).
    static func svgString(named name: String) -> String? {
        svgLock.lock()
        if let cached = svgCache[name] { svgLock.unlock(); return cached }
        svgLock.unlock()

        var result: String?
        if let url = Bundle.main.url(forResource: name, withExtension: "svg"),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            result = string
        } else {
            let fm = FileManager.default
            if let bundlePath = Bundle.main.resourcePath {
                let candidates = [
                    (bundlePath as NSString).appendingPathComponent("\(name).svg"),
                    (bundlePath as NSString).appendingPathComponent("Features/Animation/\(name).svg"),
                    (bundlePath as NSString).appendingPathComponent("Animation/\(name).svg")
                ]
                for path in candidates where fm.fileExists(atPath: path) {
                    if let string = try? String(contentsOfFile: path, encoding: .utf8) { result = string; break }
                }
            }
        }
        if let result {
            svgLock.lock(); svgCache[name] = result; svgLock.unlock()
        }
        return result
    }

    /// Preloads commonly used animation SVGs to reduce first-render delay.
    static func preloadCommonSVGs() {
        _ = svgString(named: tickCompleteSVG)
        _ = svgString(named: fullScreenLoadingSVG)
    }
}

/// Coordinates animation-related shared state and lifecycle helpers.
@MainActor
final class MokoAnimationManager {
    static let shared = MokoAnimationManager()

    // Preload the inline loader animation once.
    let inlineLoader: LottieAnimation?

    private init() {
        inlineLoader = MokoAnimationAssets.inlineLoaderAnimation
    }
}
