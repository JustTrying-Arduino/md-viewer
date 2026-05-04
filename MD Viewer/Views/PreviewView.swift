import SwiftUI
import MarkdownUI

struct PreviewView: View {
    let text: String
    let baseURL: URL?
    @Bindable var find: FindController
    @Binding var scrollTarget: String?
    var onInternalLink: ((URL) -> Void)?
    var initialSectionID: String?
    var onScrollSectionChanged: ((String) -> Void)?

    @State private var topVisibleID: String?
    @State private var didRestore = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let processed = MathPreprocessor.process(text)
        let sections = MarkdownSectionParser.parse(processed)
        let anchorMap = buildAnchorMap(sections: sections)
        let matchedIDs = find.matchedSectionIDs
        let currentMatchSectionID = find.currentMatch?.sectionID

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Markdown(section.content, baseURL: baseURL, imageBaseURL: baseURL)
                            .markdownTheme(.obsidian)
                            .markdownCodeSyntaxHighlighter(SplashSyntaxHighlighter(colorScheme: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(highlightBackground(
                                sectionID: section.id,
                                matchedIDs: matchedIDs,
                                currentID: currentMatchSectionID
                            ))
                            .padding(.top, index == 0 ? 0 : topSpacing(for: section.level))
                            .id(section.id)
                    }
                }
                .scrollTargetLayout()
                .textSelection(.enabled)
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
                .frame(maxWidth: 960, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .scrollPosition(id: $topVisibleID, anchor: .top)
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
            .overlay(alignment: .topTrailing) {
                if find.isVisible {
                    FindBarView(controller: find)
                        .padding(.top, 12)
                        .padding(.trailing, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: find.isVisible)
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(target, anchor: .top)
                }
                DispatchQueue.main.async {
                    scrollTarget = nil
                }
            }
            .onChange(of: topVisibleID) { _, newID in
                guard didRestore, let newID else { return }
                onScrollSectionChanged?(newID)
            }
            .onChange(of: find.query) { _, _ in
                find.recompute(sections: sections)
            }
            .onChange(of: text) { _, _ in
                find.recompute(sections: sections)
            }
            .onChange(of: find.currentMatch?.sectionID) { _, newID in
                guard find.isVisible, let newID else { return }
                scrollTarget = newID
            }
            .onAppear {
                guard !didRestore else { return }
                if let id = initialSectionID {
                    // Defer until after first layout so proxy.scrollTo lands;
                    // gate recording until the scroll has settled, otherwise
                    // the initial "section-0" reading from .scrollPosition
                    // would overwrite the saved position.
                    DispatchQueue.main.async {
                        proxy.scrollTo(id, anchor: .top)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            didRestore = true
                        }
                    }
                } else {
                    didRestore = true
                }
            }
        }
    }

    @ViewBuilder
    private func highlightBackground(
        sectionID: String,
        matchedIDs: Set<String>,
        currentID: String?
    ) -> some View {
        if matchedIDs.contains(sectionID) {
            let isCurrent = (sectionID == currentID)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.yellow.opacity(isCurrent ? 0.32 : 0.14))
                .padding(.horizontal, -6)
                .padding(.vertical, -2)
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
