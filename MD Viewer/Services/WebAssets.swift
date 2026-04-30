import Foundation
import WebKit

enum WebAssets {
    static let scheme = "mdv-asset"

    static var rootURL: URL? {
        Bundle.main.url(forResource: "WebAssets", withExtension: nil)
    }

    static func loadTemplate(_ name: String) -> String? {
        guard let url = rootURL?.appendingPathComponent("templates/\(name)") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

final class WebAssetSchemeHandler: NSObject, WKURLSchemeHandler {
    private let assetsRoot: URL

    init(assetsRoot: URL) {
        self.assetsRoot = assetsRoot
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        // mdv-asset://app/<path...> -> assetsRoot/<path...>
        let pathOnly = url.path
        let trimmed = pathOnly.hasPrefix("/") ? String(pathOnly.dropFirst()) : pathOnly
        let fileURL = assetsRoot.appendingPathComponent(trimmed)

        // Reject path-traversal escapes outside the assets root.
        let canonicalRoot = assetsRoot.standardizedFileURL.path
        let canonicalFile = fileURL.standardizedFileURL.path
        guard canonicalFile.hasPrefix(canonicalRoot) else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": Self.mimeType(for: fileURL.pathExtension),
                    "Content-Length": String(data.count),
                    "Access-Control-Allow-Origin": "*"
                ]
            )!
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "css":   return "text/css; charset=utf-8"
        case "js":    return "application/javascript; charset=utf-8"
        case "html":  return "text/html; charset=utf-8"
        case "json":  return "application/json; charset=utf-8"
        case "woff2": return "font/woff2"
        case "woff":  return "font/woff"
        case "ttf":   return "font/ttf"
        case "svg":   return "image/svg+xml"
        case "png":   return "image/png"
        default:      return "application/octet-stream"
        }
    }
}
