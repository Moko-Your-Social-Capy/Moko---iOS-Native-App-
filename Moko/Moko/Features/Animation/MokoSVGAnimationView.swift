import SwiftUI
import WebKit

/// Renders an animated SVG (SMIL) from the bundle with a transparent background.
/// Used for the full-screen loader and completion illustrations so animations stay smooth.
struct MokoSVGAnimationView: View {
    let name: String
    var contentMode: ContentMode = .fit

    var body: some View {
        SVGWebView(svgName: name)
            .aspectRatio(contentMode: contentMode)
            .background(Color.clear)
            .accessibilityHidden(true)
    }
}

private struct SVGWebView: UIViewRepresentable {
    let svgName: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false
        config.dataDetectorTypes = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isUserInteractionEnabled = false

        // Load immediately (SVG is preloaded/cached) so the animation appears fast.
        if let svg = MokoAnimationAssets.svgString(named: svgName) {
            let html = Self.wrap(svg: svg)
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private static func wrap(svg: String) -> String {
        // Wrap SVG in a transparent, full-bleed HTML container for smooth SMIL playback.
        return """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
          html,body{margin:0;padding:0;width:100%;height:100%;background:transparent;overflow:hidden}
          body{display:flex;align-items:center;justify-content:center}
          svg{width:100%;height:100%;display:block}
        </style></head><body>\(svg)</body></html>
        """
    }
}
