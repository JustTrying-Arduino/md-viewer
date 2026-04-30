import SwiftUI
import UniformTypeIdentifiers
import AppKit

private struct DocumentFocusedValueKey: FocusedValueKey {
    typealias Value = DocumentViewModel
}

extension FocusedValues {
    var document: DocumentViewModel? {
        get { self[DocumentFocusedValueKey.self] }
        set { self[DocumentFocusedValueKey.self] = newValue }
    }
}

private extension UTType {
    static let markdownExtensions: [UTType] = {
        var types: [UTType] = []
        if let t = UTType(filenameExtension: "md") { types.append(t) }
        if let t = UTType(filenameExtension: "markdown") { types.append(t) }
        if let t = UTType("net.daringfireball.markdown") { types.append(t) }
        return types
    }()
}

struct OpenFileCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open…") {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = UTType.markdownExtensions
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            if panel.runModal() == .OK, let url = panel.url {
                openWindow(value: url)
            }
        }
        .keyboardShortcut("o", modifiers: .command)
    }
}

struct SaveFileCommand: View {
    @FocusedValue(\.document) private var document

    var body: some View {
        Button("Save") {
            document?.save()
        }
        .keyboardShortcut("s", modifiers: .command)
        .disabled(document == nil)
    }
}

struct ToggleModeCommand: View {
    @FocusedValue(\.document) private var document

    var body: some View {
        Button(toggleTitle) {
            document?.toggleMode()
        }
        .keyboardShortcut("e", modifiers: .command)
        .disabled(document?.url == nil)
    }

    private var toggleTitle: String {
        switch document?.mode {
        case .edit: return "Show Preview"
        default:    return "Show Editor"
        }
    }
}
