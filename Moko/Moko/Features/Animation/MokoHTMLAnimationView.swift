import SwiftUI
import WebKit

/// Renders a bundled animated HTML file in a transparent web view.
/// Used when a supplied HTML animation should play as-is (e.g. tick complete).
struct MokoHTMLAnimationView: View {
    let fileName: String
    let fileExtension: String

    init(fileName: String, fileExtension: String = "html") {
        self.fileName = fileName
        self.fileExtension = fileExtension
    }

    var body: some View {
        HTMLWebView(fileName: fileName, fileExtension: fileExtension)
            .background(Color.clear)
            .accessibilityHidden(true)
    }
}

private struct HTMLWebView: UIViewRepresentable {
    let fileName: String
    let fileExtension: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isUserInteractionEnabled = false

        if let url = MokoAnimationAssets.url(named: fileName, extension: fileExtension) {
            // Load the bundled HTML file so its inline SVG/SMIL animations run natively.
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else if let html = MokoAnimationAssets.htmlString(named: fileName) {
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
