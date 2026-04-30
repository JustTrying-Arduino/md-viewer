import SwiftUI

struct MathBlockView: View {
    let source: String

    @State private var height: CGFloat = 80

    var body: some View {
        WebRendererView(html: html, measuredHeight: $height)
            .frame(height: max(40, height))
            .padding(.vertical, 4)
    }

    private var html: String {
        let template = WebAssets.loadTemplate("math.html") ?? ""
        let wrapped = "$$\n" + source.trimmingCharacters(in: .whitespacesAndNewlines) + "\n$$"
        return template.replacingOccurrences(of: "__CONTENT__", with: wrapped)
    }
}
