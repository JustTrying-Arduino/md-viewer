import SwiftUI

struct MermaidBlockView: View {
    let source: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var height: CGFloat = 120

    var body: some View {
        WebRendererView(html: html, measuredHeight: $height)
            .frame(height: max(60, height))
            .padding(.vertical, 4)
    }

    private var html: String {
        let template = WebAssets.loadTemplate("mermaid.html") ?? ""
        let theme = colorScheme == .dark ? "dark" : "default"
        let escaped = source
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return template
            .replacingOccurrences(of: "__CONTENT__", with: escaped)
            .replacingOccurrences(of: "__THEME__", with: theme)
    }
}
