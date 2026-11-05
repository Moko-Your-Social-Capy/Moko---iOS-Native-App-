import SwiftUI
import UIKit

enum ProfilePage: String, CaseIterable, Identifiable, Hashable {
    case profile
    case moko
    var id: Self { self }
    var title: String { self == .profile ? "Profile" : "Moko" }
}

/// Shared, low contrast foliage layer for the app's primary tabs.
/// The decorative motion moves only the vector layers and is disabled for Reduce Motion.
struct AppBackground: View {
    var baseColor: Color?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    private var isDark: Bool { colorScheme == .dark }
    private var canvas: Color {
        isDark
            ? Color(red: 0.105, green: 0.15, blue: 0.13)
            : (baseColor ?? Color(red: 0.965, green: 0.973, blue: 0.925))
    }
    private var leafTint: Color { isDark ? Color(red: 0.56, green: 0.68, blue: 0.52) : Color(red: 0.46, green: 0.61, blue: 0.43) }
    private var bushTint: Color { isDark ? Color(red: 0.45, green: 0.59, blue: 0.44) : Color(red: 0.57, green: 0.70, blue: 0.53) }
    private var grassTint: Color { isDark ? Color(red: 0.52, green: 0.66, blue: 0.49) : Color(red: 0.64, green: 0.75, blue: 0.57) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                canvas

                // A softly shaded canopy sits behind the sharper, very faint leaf silhouettes.
                Image("FoliageBush")
                    .renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(bushTint)
                    .frame(width: size.width * 0.66, height: size.height * 0.24)
                    .blur(radius: 11)
                    .opacity(isDark ? 0.10 : 0.11)
                    .offset(x: drift ? 5 : -5, y: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                Image("FoliageBush")
                    .renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(bushTint)
                    .frame(width: size.width * 0.48, height: size.height * 0.16)
                    .blur(radius: 5)
                    .opacity(isDark ? 0.12 : 0.14)
                    .offset(x: drift ? -4 : 4, y: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                Image("FoliageBranch")
                    .renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(leafTint)
                    .frame(width: size.width * 0.20, height: size.height * 0.13)
                    .rotationEffect(.degrees(-24))
                    .opacity(isDark ? 0.10 : 0.12)
                    .offset(x: drift ? -6 : -2, y: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                Image("FoliageBranch")
                    .renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(leafTint)
                    .frame(width: size.width * 0.17, height: size.height * 0.11)
                    .rotationEffect(.degrees(154))
                    .opacity(isDark ? 0.09 : 0.11)
                    .offset(x: drift ? 4 : 8, y: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                Image("FoliageGrass")
                    .renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(grassTint)
                    .frame(width: size.width * 0.31, height: size.height * 0.17)
                    .opacity(isDark ? 0.13 : 0.16)
                    .offset(x: drift ? 2 : -2, y: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
        .onAppear(perform: startDriftIfAllowed)
        .onChange(of: reduceMotion) { _, _ in startDriftIfAllowed() }
    }

    private func startDriftIfAllowed() {
        if reduceMotion {
            drift = false
            return
        }
        guard !drift else { return }
        withAnimation(.linear(duration: 90).repeatForever(autoreverses: true)) { drift = true }
    }
}

/// A category scene with a left-to-right fade so the card's copy remains on a quiet field.
struct QuestCategoryScene: View {
    let category: String
    var cardTint: Color?
    @State private var shownAsset: String?
    @State private var previousAsset: String?
    @State private var fadeProgress = 1.0

    private var assetName: String {
        switch category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "work", "career": "QuestSceneWork"
        case "friends", "friendship", "social": "QuestSceneFriends"
        case "family": "QuestSceneFamily"
        case "date", "dating", "romance": "QuestSceneDate"
        case "interview": "QuestSceneInterview"
        case "event", "events": "QuestSceneEvents"
        case "calm", "relax", "relaxation": "QuestSceneCalm"
        case "explore", "exploration": "QuestSceneExplore"
        default: "QuestSceneWork"
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                if let previousAsset {
                    sceneLayer(named: previousAsset, size: proxy.size)
                        .opacity(1 - fadeProgress)
                }
                sceneLayer(named: shownAsset ?? assetName, size: proxy.size)
                    .opacity(fadeProgress)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .trailing)
            .overlay {
                if let cardTint {
                    LinearGradient(stops: [
                        .init(color: cardTint, location: 0),
                        .init(color: cardTint, location: 0.65),
                        .init(color: cardTint.opacity(0.94), location: 0.90),
                        .init(color: cardTint.opacity(0), location: 1)
                    ], startPoint: .leading, endPoint: .trailing)
                }
            }
        }
        .onChange(of: assetName) { _, nextAsset in
            let current = shownAsset ?? assetName
            guard current != nextAsset else { return }
            previousAsset = current
            shownAsset = nextAsset
            fadeProgress = 0
            withAnimation(.easeInOut(duration: 0.3)) { fadeProgress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                guard shownAsset == nextAsset else { return }
                previousAsset = nil
            }
        }
        .accessibilityHidden(true)
    }

    private func sceneLayer(named name: String, size: CGSize) -> some View {
        SceneAssetImage(name: name)
            .frame(width: size.width * 0.57, height: size.height)
            .clipped()
            .mask {
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.28), location: 0.27),
                    .init(color: .black, location: 0.72)
                ], startPoint: .leading, endPoint: .trailing)
            }
            .opacity(0.22)
    }
}

/// Asset catalog images are materialized into a bitmap on a worker task before display.
private struct SceneAssetImage: View {
    let name: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var decodedImage: CGImage?

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Group {
            if let decodedImage {
                Image(decorative: decodedImage, scale: 1)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .task(id: "\(name)-\(isDark)") {
            let key = name + (isDark ? "Dark" : "Light")
            guard let data = NSDataAsset(name: key)?.data else {
                decodedImage = nil
                return
            }
            let image = await Task.detached(priority: .userInitiated) {
                SceneImageDecoder.decode(data: data)
            }.value
            guard !Task.isCancelled else { return }
            decodedImage = image
        }
    }

}

private enum SceneImageDecoder {
    nonisolated static func decode(data: Data) -> CGImage? {
        let options = [kCGImageSourceShouldCache: true, kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options),
              let image = CGImageSourceCreateImageAtIndex(source, 0, options) else { return nil }
        let width = image.width
        let height = image.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
