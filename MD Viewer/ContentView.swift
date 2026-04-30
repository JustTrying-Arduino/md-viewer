import SwiftUI

struct ContentView: View {
    let url: URL?
    @State private var vm = DocumentViewModel()
    @State private var scrollTarget: String?
    @Environment(\.openWindow) private var openWindow

    private var sidebarVisible: Bool {
        vm.url != nil && (vm.showOutline || vm.showFiles) && vm.mode == .preview
    }

    private var sections: [MarkdownSection] {
        guard vm.url != nil else { return [] }
        let processed = MathPreprocessor.process(vm.rawText)
        return MarkdownSectionParser.parse(processed)
    }

    var body: some View {
        @Bindable var vm = vm

        HStack(spacing: 0) {
            if sidebarVisible {
                sidebar
                    .frame(width: 240)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Divider()
            }

            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottomLeading) {
                    if vm.url != nil {
                        FloatingFolderButton(isActive: vm.showFiles) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                vm.showFiles.toggle()
                            }
                        }
                        .padding(12)
                    }
                }
        }
        .frame(minWidth: 480, minHeight: 320)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        vm.showOutline.toggle()
                    }
                } label: {
                    Image(systemName: "list.bullet.indent")
                        .foregroundStyle(vm.showOutline ? Color.accentColor : Color.primary)
                }
                .help("Outline")
                .disabled(vm.url == nil || vm.mode != .preview)
            }
            ToolbarItem(placement: .primaryAction) {
                if vm.url != nil {
                    Button {
                        vm.toggleMode()
                    } label: {
                        Image(systemName: vm.mode == .preview ? "square.and.pencil" : "eye")
                    }
                    .help(vm.mode == .preview ? "Edit (⌘E)" : "Preview (⌘E)")
                }
            }
        }
        .navigationTitle(vm.windowTitle)
        .focusedSceneValue(\.document, vm)
        .dropDestination(for: URL.self) { urls, _ in
            guard let dropped = urls.first(where: MarkdownFileTypes.isMarkdown) else { return false }
            if vm.url == nil {
                vm.load(url: dropped)
            } else {
                openWindow(value: dropped)
            }
            return true
        }
        .onAppear {
            if let url, vm.url == nil {
                vm.load(url: url)
            }
        }
        .onChange(of: url) { _, new in
            if let new, new != vm.url {
                vm.load(url: new)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if vm.url != nil {
            if vm.mode == .preview {
                PreviewView(text: vm.rawText, baseURL: vm.url, scrollTarget: $scrollTarget)
            } else {
                EditorView(text: $vm.rawText)
            }
        } else {
            EmptyStateView()
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            if vm.showOutline {
                OutlineSidebarView(sections: sections) { id in
                    scrollTarget = id
                }
            }
            if vm.showOutline && vm.showFiles {
                Divider()
            }
            if vm.showFiles {
                FilesSidebarView(currentURL: vm.url, files: vm.siblingFiles) { selected in
                    vm.switchDocument(to: selected)
                }
            }
        }
    }
}

private struct FloatingFolderButton: View {
    let isActive: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "folder")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(isHovering ? 0.18 : 0.10), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 3, y: 1)
                .scaleEffect(isHovering ? 1.06 : 1.0)
                .animation(.easeOut(duration: 0.12), value: isHovering)
        }
        .buttonStyle(.plain)
        .help("Show files in this folder")
        .onHover { isHovering = $0 }
    }
}
