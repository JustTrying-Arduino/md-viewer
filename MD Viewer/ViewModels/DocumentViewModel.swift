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
    private(set) var navigationHistory: [URL] = []

    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var suppressWatcherUntil: Date = .distantPast
    @ObservationIgnored private var conflictAlertOnScreen = false
    @ObservationIgnored private var savedScrollSections: [URL: String] = [:]

    var isDirty: Bool { rawText != lastSavedText }
    var canGoBack: Bool { !navigationHistory.isEmpty }

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

    /// Loads a file as a fresh document, resetting the back-navigation history.
    /// Use this for external entry points (Finder open, drop, File menu).
    func load(url: URL) {
        navigationHistory.removeAll()
        performLoad(url: url)
    }

    private func performLoad(url: URL) {
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

    // MARK: - Scroll position (in-memory, session-scoped)

    func recordScrollSection(_ id: String, for url: URL) {
        savedScrollSections[url.standardizedFileURL] = id
    }

    func savedScrollSection(for url: URL) -> String? {
        savedScrollSections[url.standardizedFileURL]
    }

    /// Replace the current document in place. If there are unsaved changes,
    /// ask the user whether to save, discard, or cancel.
    func switchDocument(to newURL: URL) {
        performSwitch(to: newURL, recordHistory: true)
    }

    /// Pop the most recent entry off the navigation history and load it.
    func goBack() {
        guard let previous = navigationHistory.last else { return }
        performSwitch(to: previous, recordHistory: false, popHistory: true)
    }

    private func performSwitch(to newURL: URL, recordHistory: Bool, popHistory: Bool = false) {
        guard newURL != url else { return }

        let proceed: () -> Void = { [weak self] in
            guard let self else { return }
            if recordHistory, let current = self.url {
                self.navigationHistory.append(current)
            }
            if popHistory {
                self.navigationHistory.removeLast()
            }
            self.performLoad(url: newURL)
        }

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
                proceed()
            case .alertSecondButtonReturn:
                proceed()
            default:
                return
            }
        } else {
            proceed()
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
