import Foundation

struct MarkdownSection: Identifiable, Equatable {
    let id: String
    let level: Int       // 0 = preamble before any heading; 1...6 = heading level
    let title: String?   // nil for the preamble section
    let content: String  // the section's markdown, including the heading line
}

/// Splits a Markdown document into sections delimited by ATX headings (`#`...`######`),
/// while ignoring `#` lines that fall inside fenced code blocks.
enum MarkdownSectionParser {
    static func parse(_ markdown: String) -> [MarkdownSection] {
        let lines = markdown.components(separatedBy: "\n")
        var sections: [MarkdownSection] = []

        var currentLines: [String] = []
        var currentLevel = 0
        var currentTitle: String? = nil
        var inFence = false
        var fenceMarker = ""

        func flush() {
            if currentLines.isEmpty && currentLevel == 0 && currentTitle == nil {
                return
            }
            sections.append(MarkdownSection(
                id: "section-\(sections.count)",
                level: currentLevel,
                title: currentTitle,
                content: currentLines.joined(separator: "\n")
            ))
            currentLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if !inFence {
                if trimmed.hasPrefix("```") {
                    inFence = true
                    fenceMarker = "```"
                    currentLines.append(line)
                    continue
                }
                if trimmed.hasPrefix("~~~") {
                    inFence = true
                    fenceMarker = "~~~"
                    currentLines.append(line)
                    continue
                }

                if let (level, title) = parseHeading(trimmed) {
                    flush()
                    currentLevel = level
                    currentTitle = title
                    currentLines = [line]
                    continue
                }

                currentLines.append(line)
            } else {
                currentLines.append(line)
                if trimmed.hasPrefix(fenceMarker) {
                    inFence = false
                    fenceMarker = ""
                }
            }
        }
        flush()
        return sections
    }

    private static func parseHeading(_ trimmedLine: String) -> (level: Int, title: String)? {
        guard trimmedLine.hasPrefix("#") else { return nil }
        var level = 0
        for c in trimmedLine {
            if c == "#" { level += 1 } else { break }
        }
        guard (1...6).contains(level) else { return nil }
        let after = trimmedLine.dropFirst(level)
        guard after.first == " " || after.isEmpty else { return nil }
        let title = after
            .trimmingCharacters(in: .whitespaces)
            // Strip a trailing run of `#` characters (closing ATX style).
            .replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        return (level, title)
    }
}
