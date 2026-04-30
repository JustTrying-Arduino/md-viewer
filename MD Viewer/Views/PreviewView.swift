import SwiftUI
import MarkdownUI

struct PreviewView: View {
    let text: String
    let baseURL: URL?
    @Binding var scrollTarget: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let processed = MathPreprocessor.process(text)
        let sections = MarkdownSectionParser.parse(processed)

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
