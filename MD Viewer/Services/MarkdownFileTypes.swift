import Foundation

enum MarkdownFileTypes {
    static let extensions: Set<String> = ["md", "markdown", "mdown", "mkd", "txt"]

    static func isMarkdown(_ url: URL) -> Bool {
        extensions.contains(url.pathExtension.lowercased())
    }
}
