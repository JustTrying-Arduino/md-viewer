import Foundation
import Observation

@Observable
final class FindController {
    struct Match: Equatable {
        let sectionID: String
        let range: Range<String.Index>
    }

    var isVisible: Bool = false
    var query: String = ""
    private(set) var matches: [Match] = []
    var currentIndex: Int = 0

    /// Bumped to ask the bar's text field to re-focus and select all,
    /// e.g. when the user hits Cmd+F again while the bar is already visible.
    private(set) var focusToken: Int = 0

    var currentMatch: Match? {
        guard !matches.isEmpty, matches.indices.contains(currentIndex) else { return nil }
        return matches[currentIndex]
    }

    var matchedSectionIDs: Set<String> {
        var set = Set<String>()
        set.reserveCapacity(matches.count)
        for m in matches { set.insert(m.sectionID) }
        return set
    }

    func activate() {
        isVisible = true
        focusToken &+= 1
    }

    func dismiss() {
        isVisible = false
        query = ""
        matches = []
        currentIndex = 0
    }

    func next() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex + 1) % matches.count
    }

    func previous() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex - 1 + matches.count) % matches.count
    }

    /// Recompute matches against the current `query` over the given sections.
    /// Case- and diacritic-insensitive plain substring search.
    func recompute(sections: [MarkdownSection]) {
        let q = query
        guard !q.isEmpty else {
            matches = []
            currentIndex = 0
            return
        }
        var found: [Match] = []
        let opts: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        for section in sections {
            let content = section.content
            var cursor = content.startIndex
            while cursor < content.endIndex,
                  let r = content.range(of: q, options: opts, range: cursor..<content.endIndex),
                  !r.isEmpty {
                found.append(Match(sectionID: section.id, range: r))
                cursor = r.upperBound
            }
        }
        matches = found
        if currentIndex >= matches.count { currentIndex = 0 }
    }
}
