import Foundation

final class FileWatcher {
    typealias Handler = () -> Void

    private let url: URL
    private let queue: DispatchQueue
    private let handler: Handler
    private var source: DispatchSourceFileSystemObject?

    init(url: URL, queue: DispatchQueue = .main, handler: @escaping Handler) {
        self.url = url
        self.queue = queue
        self.handler = handler
    }

    deinit { stop() }

    func start() {
        stop()
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: queue
        )
        src.setEventHandler { [weak self, weak src] in
            guard let self, let src else { return }
            let mask = src.data
            if mask.contains(.delete) || mask.contains(.rename) {
                // Atomic save: original fd is gone; reopen on same path after the
                // editor's rename settles, then notify.
                self.queue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.start()
                    self?.handler()
                }
            } else {
                self.handler()
            }
        }
        src.setCancelHandler {
            close(fd)
        }
        source = src
        src.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}
