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
    // Universal completion illustration (animated HTML file, preferred for tick).
    static let tickCompleteHTML = "11-Tick-Complete-animated"

    /// Cached Lottie animation for the inline loader to avoid repeated decoding.
    static let inlineLoaderAnimation: LottieAnimation? = LottieAnimation.named(inlineLoaderName)

    /// Cached SVG/HTML sources to avoid repeated disk reads.
    private static var svgCache: [String: String] = [:]
    private static var htmlCache: [String: String] = [:]
    private static let cacheLock = NSLock()

    /// Finds a bundled resource URL by trying common animation folders.
    static func url(named name: String, extension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        let fm = FileManager.default
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        let candidates = [
            (bundlePath as NSString).appendingPathComponent("\(name).\(ext)"),
            (bundlePath as NSString).appendingPathComponent("Features/Animation/\(name).\(ext)"),
            (bundlePath as NSString).appendingPathComponent("Animation/\(name).\(ext)")
        ]
        for path in candidates where fm.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    /// Loads an SVG file from the bundle as a String (cached).
    static func svgString(named name: String) -> String? {
        cacheLock.lock()
        if let cached = svgCache[name] { cacheLock.unlock(); return cached }
        cacheLock.unlock()

        var result: String?
        if let url = url(named: name, extension: "svg"),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            result = string
        }
        if let result {
            cacheLock.lock(); svgCache[name] = result; cacheLock.unlock()
        }
        return result
    }

    /// Loads an HTML animation file from the bundle as a String (cached).
    static func htmlString(named name: String) -> String? {
        cacheLock.lock()
        if let cached = htmlCache[name] { cacheLock.unlock(); return cached }
        cacheLock.unlock()

        var result: String?
        if let url = url(named: name, extension: "html"),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            result = string
        }
        if let result {
            cacheLock.lock(); htmlCache[name] = result; cacheLock.unlock()
        }
        return result
    }

    /// Preloads commonly used animation assets to reduce first-render delay.
    static func preloadCommonSVGs() {
        _ = svgString(named: tickCompleteSVG)
        _ = svgString(named: fullScreenLoadingSVG)
        _ = htmlString(named: tickCompleteHTML)
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
