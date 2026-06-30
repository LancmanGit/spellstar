import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebView()
            .ignoresSafeArea()
    }
}

/// Hosts the bundled SpellStar.html in a full-screen WKWebView.
/// The HTML is loaded from the app bundle so it lives inside the app —
/// there is no address bar, no navigation chrome, and (once vendored)
/// no browser engine for a child to escape into. This is what lets
/// SpellStar appear as its own native tile in iOS Assistive Access.
struct WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Let the spelling audio (Web Speech API) and any media play
        // without requiring a tap each time.
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = false
        webView.isOpaque = true
        // Enables Safari Web Inspector against the device while developing.
        // Harmless to leave on; remove for a hardened release if desired.
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        if let url = Bundle.main.url(forResource: "SpellStar", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
