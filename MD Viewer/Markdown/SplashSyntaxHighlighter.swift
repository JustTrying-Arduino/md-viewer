import SwiftUI
import MarkdownUI
import Splash

struct SplashSyntaxHighlighter: CodeSyntaxHighlighter {
    private let theme: Splash.Theme

    init(colorScheme: ColorScheme) {
        let font = Splash.Font(size: 13.6)
        switch colorScheme {
        case .dark:
            self.theme = .midnight(withFont: font)
        default:
            self.theme = .sunset(withFont: font)
        }
    }

    func highlightCode(_ code: String, language: String?) -> Text {
        guard let language, language.lowercased() == "swift" else {
            return Text(code)
        }
        let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme))
        let attributed = highlighter.highlight(code)
        return Text(AttributedString(attributed))
    }
}
