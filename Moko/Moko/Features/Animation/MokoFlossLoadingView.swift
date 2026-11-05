import SwiftUI
import UIKit
import WebKit

/// Transparent, reusable Moko loader. A bundled mascot image appears immediately,
/// then cross-fades to the vector floss loop when its WebKit page is ready.
struct MokoFlossLoadingView: View {
    var size: CGFloat = 112

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationIsReady = false

    /// Loads the local animation page before a loader needs to appear.
    @MainActor
    static func prewarm() {
        MokoFlossWebViewPool.prewarm()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 226 / 255, green: 245 / 255, blue: 177 / 255).opacity(0.46))
                .frame(width: size * 0.72, height: size * 0.72)

            Circle()
                .stroke(Color(red: 31 / 255, green: 116 / 255, blue: 136 / 255).opacity(0.12), lineWidth: 1)
                .frame(width: size * 0.64, height: size * 0.64)

            Image("moko_waving_raw")
                .resizable()
                .scaledToFit()
                .padding(size * 0.08)
                .opacity(animationIsReady ? 0 : 1)

            MokoFlossWebView(reduceMotion: reduceMotion) {
                animationIsReady = true
            }
            .opacity(animationIsReady ? 1 : 0)
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.18), value: animationIsReady)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Moko dancing while content loads")
    }
}

private struct MokoFlossWebView: UIViewRepresentable {
    let reduceMotion: Bool
    let onReady: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(reduceMotion: reduceMotion, onReady: onReady)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = MokoFlossWebViewPool.take() ?? MokoFlossWebViewPool.makeWebView(reduceMotion: reduceMotion)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        if let url = MokoFlossWebViewPool.loaderURL {
            if webView.url?.standardizedFileURL == url.standardizedFileURL {
                context.coordinator.checkIfPageIsReady()
            } else {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        } else {
            assertionFailure("MokoFlossLoader.html is missing from the app bundle.")
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.reduceMotion = reduceMotion
        context.coordinator.onReady = onReady
        context.coordinator.applyMotionPreferenceIfReady()
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.evaluateJavaScript("window.setMokoRunning(false)")
        webView.navigationDelegate = nil
        coordinator.webView = nil
        MokoFlossWebViewPool.recycle(webView)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var reduceMotion: Bool
        var onReady: () -> Void
        private var isReady = false

        init(reduceMotion: Bool, onReady: @escaping () -> Void) {
            self.reduceMotion = reduceMotion
            self.onReady = onReady
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            markReady()
        }

        func checkIfPageIsReady() {
            webView?.evaluateJavaScript("typeof window.setMokoReduceMotion === 'function'") { [weak self] result, _ in
                guard (result as? Bool) == true else { return }
                Task { @MainActor in self?.markReady() }
            }
        }

        private func markReady() {
            isReady = true
            applyMotionPreferenceIfReady()
            webView?.evaluateJavaScript("window.setMokoRunning(true)")
            onReady()
        }

        func applyMotionPreferenceIfReady() {
            guard isReady, let webView else { return }
            webView.evaluateJavaScript("window.setMokoReduceMotion(\(reduceMotion ? "true" : "false"));")
        }
    }
}

@MainActor
private enum MokoFlossWebViewPool {
    private(set) static var prewarmedWebView: WKWebView?

    static var loaderURL: URL? {
        Bundle.main.url(forResource: "MokoFlossLoader", withExtension: "html")
    }

    static func prewarm() {
        guard prewarmedWebView == nil,
              let loaderURL else { return }

        let webView = makeWebView(reduceMotion: UIAccessibility.isReduceMotionEnabled)
        webView.loadFileURL(loaderURL, allowingReadAccessTo: loaderURL.deletingLastPathComponent())
        prewarmedWebView = webView
    }

    static func take() -> WKWebView? {
        defer { prewarmedWebView = nil }
        return prewarmedWebView
    }

    static func recycle(_ webView: WKWebView) {
        guard prewarmedWebView == nil else { return }
        prewarmedWebView = webView
    }

    static func makeWebView(reduceMotion: Bool) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "window.__MOKO_REDUCE_MOTION__ = \(reduceMotion ? "true" : "false");",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.underPageBackgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isUserInteractionEnabled = false
        webView.accessibilityElementsHidden = true
        return webView
    }
}
