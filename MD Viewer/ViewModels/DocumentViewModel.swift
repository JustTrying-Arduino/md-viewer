import Foundation
import Observation
import AppKit

@Observable
final class DocumentViewModel {
    enum Mode { case preview, edit }

    var url: URL?
    var rawText: String = ""
    var mode: Mode = .preview
    var showOutline: Bool = false
    var showFiles: Bool = false
    private(set) var lastSavedText: String = ""

    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var suppressWatcherUntil: Date = .distantPast
    @ObservationIgnored private var conflictAlertOnScreen = false

    var isDirty: Bool { rawText != lastSavedText }

    var windowTitle: String {
        let base = url?.lastPathComponent ?? "MD Viewer"
        return isDirty ? "• \(base)" : base
    }

    var siblingFiles: [URL] {
        guard let url else { return [] }
        let dir = url.deletingLastPathComponent()
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        return contents
            .filter(MarkdownFileTypes.isMarkdown)
            .sorted {
                $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    func load(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            self.url = url
            self.rawText = text
            self.lastSavedText = text
            self.mode = .preview
            startWatching()
        } catch {
            presentError(error, message: "Could not open \(url.lastPathComponent)")
        }
    }

    func save() {
        guard let url else { return }
        guard isDirty else { return }
        do {
            // Suppress our own watcher event for the next ~half second.
            suppressWatcherUntil = Date().addingTimeInterval(0.5)
            try rawText.write(to: url, atomically: true, encoding: .utf8)
            lastSavedText = rawText
        } catch {
            presentError(error, message: "Could not save \(url.lastPathComponent)")
        }
    }

    func toggleMode() {
        guard url != nil else { return }
        mode = (mode == .preview) ? .edit : .preview
    }

    /// Replace the current document in place. If there are unsaved changes,
    /// ask the user whether to save, discard, or cancel.
    func switchDocument(to newURL: URL) {
        guard newURL != url else { return }
        if isDirty, let current = url {
            let alert = NSAlert()
            alert.messageText = "“\(current.lastPathComponent)” has unsaved changes"
            alert.informativeText = "Do you want to save them before opening “\(newURL.lastPathComponent)”?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            switch alert.runModal() {
            case .alertFirstButtonReturn:
                save()
                load(url: newURL)
            case .alertSecondButtonReturn:
                load(url: newURL)
            default:
                return
            }
        } else {
            load(url: newURL)
        }
    }

    // MARK: - File watching

    private func startWatching() {
        watcher?.stop()
        guard let url else { return }
        watcher = FileWatcher(url: url, queue: .main) { [weak self] in
            self?.handleExternalChange()
        }
        watcher?.start()
    }

    private func handleExternalChange() {
        guard let url else { return }
        if Date() < suppressWatcherUntil { return }
        if conflictAlertOnScreen { return }

        switch (mode, isDirty) {
        case (.preview, _), (.edit, false):
            reloadFromDisk(url: url)
        case (.edit, true):
            promptConflict(url: url)
        }
    }

    private func reloadFromDisk(url: URL) {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        self.rawText = text
        self.lastSavedText = text
    }

    private func promptConflict(url: URL) {
        conflictAlertOnScreen = true
        defer { conflictAlertOnScreen = false }

        let alert = NSAlert()
        alert.messageText = "“\(url.lastPathComponent)” was modified outside MD Viewer"
        alert.informativeText = "You have unsaved changes. Reload from disk to discard them, or keep your edits to overwrite the file on the next save."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Keep My Edits")
        alert.addButton(withTitle: "Reload from Disk")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            reloadFromDisk(url: url)
        }
    }

    private func presentError(_ error: Error, message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

extension DocumentViewModel: Equatable {
    static func == (lhs: DocumentViewModel, rhs: DocumentViewModel) -> Bool {
        lhs === rhs
    }
}
