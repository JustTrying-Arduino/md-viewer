import SwiftUI

struct FilesSidebarView: View {
    let currentURL: URL?
    let files: [URL]
    let onSelect: (URL) -> Void

    private var folderName: String {
        currentURL?.deletingLastPathComponent().lastPathComponent ?? "Folder"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(folderName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            if files.isEmpty {
                Text("No Markdown files in this folder")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(files, id: \.self) { url in
                            FileRow(url: url, isCurrent: url == currentURL, onSelect: onSelect)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

private struct FileRow: View {
    let url: URL
    let isCurrent: Bool
    let onSelect: (URL) -> Void
    @State private var isHovering = false

    var body: some View {
        Button {
            onSelect(url)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCurrent ? "doc.text.fill" : "doc.text")
                    .font(.system(size: 11))
                    .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                    .frame(width: 14)
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.system(size: 12.5, weight: isCurrent ? .medium : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(
                isCurrent ? Color.accentColor.opacity(0.10) :
                isHovering ? Color.primary.opacity(0.06) : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .disabled(isCurrent)
    }
}
