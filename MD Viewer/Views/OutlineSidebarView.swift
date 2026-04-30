import SwiftUI

struct OutlineSidebarView: View {
    let sections: [MarkdownSection]
    let onSelect: (String) -> Void

    private var headings: [MarkdownSection] {
        sections.filter { $0.title != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Outline")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)

            if headings.isEmpty {
                Text("No headings in this document")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(headings) { section in
                            OutlineRow(section: section, onSelect: onSelect)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

private struct OutlineRow: View {
    let section: MarkdownSection
    let onSelect: (String) -> Void
    @State private var isHovering = false

    var body: some View {
        Button {
            onSelect(section.id)
        } label: {
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: CGFloat(max(0, section.level - 1)) * 12, height: 1)
                Text(section.title ?? "")
                    .font(.system(size: 12.5, weight: section.level <= 1 ? .medium : .regular))
                    .foregroundStyle(section.level <= 1 ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(isHovering ? Color.primary.opacity(0.06) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
