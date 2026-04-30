import Foundation

/// Rewrites bare `$$...$$` blocks in the Markdown source into ```math fenced
/// blocks so MarkdownUI's code-block dispatcher can route them to the KaTeX
/// renderer. Skips content inside existing fenced code blocks (``` or ~~~)
/// to avoid rewriting literal `$$` examples in code listings.
///
/// Inline `$...$` is left untouched (rendered as plain text in MVP).
enum MathPreprocessor {
    static func process(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var output: [String] = []
        var buffer: [String] = []
        var inFence = false
        var fenceMarker = ""

        func flushBuffer() {
            if buffer.isEmpty { return }
            let chunk = buffer.joined(separator: "\n")
            output.append(transform(chunk))
            buffer.removeAll(keepingCapacity: true)
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !inFence {
                if trimmed.hasPrefix("```") {
                    flushBuffer()
                    output.append(line)
                    inFence = true
                    fenceMarker = "```"
                    continue
                }
                if trimmed.hasPrefix("~~~") {
                    flushBuffer()
                    output.append(line)
                    inFence = true
                    fenceMarker = "~~~"
                    continue
                }
                buffer.append(line)
            } else {
                output.append(line)
                if trimmed.hasPrefix(fenceMarker) {
                    inFence = false
                    fenceMarker = ""
                }
            }
        }
        flushBuffer()
        return output.joined(separator: "\n")
    }

    private static let blockMathRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"\$\$([\s\S]+?)\$\$"#,
            options: [.dotMatchesLineSeparators]
        )
    }()

    private static func transform(_ text: String) -> String {
        guard let regex = blockMathRegex else { return text }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: text, options: [], range: range)
        guard !matches.isEmpty else { return text }

        var result = text as NSString
        for match in matches.reversed() {
            let inner = result.substring(with: match.range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let replacement = "\n```math\n\(inner)\n```\n"
            result = result.replacingCharacters(in: match.range, with: replacement) as NSString
        }
        return result as String
    }
}
