import SwiftUI
import WebKit

/// A WKWebView wrapper that renders an HTML template with substitutions and
/// reports its content height back via a JS message handler so the SwiftUI
/// parent can size it correctly. Uses a custom URL scheme to serve bundled
/// JS/CSS/font assets without needing file:// access flags.
struct WebRendererView: NSViewRepresentable {
    let html: String
    @Binding var measuredHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator($measuredHeight) }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(context.coordinator, name: "height")
        config.userContentController = userContent
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        if let assetsRoot = WebAssets.rootURL {
            let handler = WebAssetSchemeHandler(assetsRoot: assetsRoot)
            config.setURLSchemeHandler(handler, forURLScheme: WebAssets.scheme)
            context.coordinator.handlerStrongRef = handler
        }

        let webView = PassthroughWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        loadHTML(in: webView)
        context.coordinator.lastHTML = html
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            loadHTML(in: webView)
        }
    }

    private func loadHTML(in webView: WKWebView) {
        let baseURL = URL(string: "\(WebAssets.scheme)://app/")
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    private final class PassthroughWebView: WKWebView {
        override func scrollWheel(with event: NSEvent) {
            nextResponder?.scrollWheel(with: event)
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let height: Binding<CGFloat>
        var lastHTML: String = ""
        var handlerStrongRef: WebAssetSchemeHandler?

        init(_ height: Binding<CGFloat>) {
            self.height = height
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "height" else { return }
            let value: CGFloat
            if let n = message.body as? NSNumber {
                value = CGFloat(truncating: n)
            } else if let d = message.body as? Double {
                value = CGFloat(d)
            } else {
                return
            }
            DispatchQueue.main.async {
                if abs(self.height.wrappedValue - value) > 0.5 {
                    self.height.wrappedValue = value
                }
            }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
