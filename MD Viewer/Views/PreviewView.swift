import SwiftUI
import MarkdownUI

struct PreviewView: View {
    let text: String
    let baseURL: URL?
    @Binding var scrollTarget: String?
    var onInternalLink: ((URL) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let processed = MathPreprocessor.process(text)
        let sections = MarkdownSectionParser.parse(processed)
        let anchorMap = buildAnchorMap(sections: sections)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Markdown(section.content, baseURL: baseURL, imageBaseURL: baseURL)
                            .markdownTheme(.obsidian)
                            .markdownCodeSyntaxHighlighter(SplashSyntaxHighlighter(colorScheme: colorScheme))
                            .padding(.top, index == 0 ? 0 : topSpacing(for: section.level))
                            .id(section.id)
                    }
                }
                .textSelection(.enabled)
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
                .frame(maxWidth: 960, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .environment(\.openURL, OpenURLAction { url in
                if let sectionID = resolveSameDocumentAnchor(url, anchorMap: anchorMap) {
                    scrollTarget = sectionID
                    return .handled
                }
                if let target = resolveInternalMarkdownLink(url) {
                    onInternalLink?(target)
                    return .handled
                }
                return .systemAction
            })
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(target, anchor: .top)
                }
                DispatchQueue.main.async {
                    scrollTarget = nil
                }
            }
        }
    }

    private func resolveInternalMarkdownLink(_ url: URL) -> URL? {
        guard let baseURL else { return nil }
        let folder = baseURL.deletingLastPathComponent().standardizedFileURL

        let resolved: URL
        if url.scheme == "file" {
            resolved = url.standardizedFileURL
        } else if url.scheme == nil {
            resolved = URL(fileURLWithPath: url.relativePath, relativeTo: folder).standardizedFileURL
        } else {
            return nil
        }

        guard MarkdownFileTypes.isMarkdown(resolved) else { return nil }
        guard resolved.deletingLastPathComponent() == folder else { return nil }
        guard FileManager.default.fileExists(atPath: resolved.path) else { return nil }
        return resolved
    }

    private func resolveSameDocumentAnchor(_ url: URL, anchorMap: [String: String]) -> String? {
        guard let fragment = url.fragment, !fragment.isEmpty else { return nil }
        // Same-document anchor: either fragment-only (no scheme/host/path)
        // or a file URL whose path equals the current document's path.
        let isSameDoc: Bool
        if url.scheme == nil && url.host == nil && url.path.isEmpty {
            isSameDoc = true
        } else if url.scheme == "file", let baseURL,
                  url.standardizedFileURL.path == baseURL.standardizedFileURL.path {
            isSameDoc = true
        } else {
            isSameDoc = false
        }
        guard isSameDoc else { return nil }
        let slug = Self.slugify(fragment)
        return anchorMap[slug]
    }

    private func buildAnchorMap(sections: [MarkdownSection]) -> [String: String] {
        var map: [String: String] = [:]
        for section in sections {
            guard let title = section.title else { continue }
            let slug = Self.slugify(title)
            if !slug.isEmpty && map[slug] == nil {
                map[slug] = section.id
            }
        }
        return map
    }

    private static func slugify(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        var result = ""
        for ch in folded {
            if ch.isLetter || ch.isNumber {
                result.append(ch.lowercased())
            } else if ch == "-" || ch == "_" || ch.isWhitespace {
                result.append("-")
            }
        }
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        return result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func topSpacing(for level: Int) -> CGFloat {
        switch level {
        case 1: return 40
        case 2: return 32
        case 3: return 26
        case 4, 5, 6: return 22
        default: return 0
        }
    }
}
