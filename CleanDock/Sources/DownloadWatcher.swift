import AppKit

class DownloadWatcher {
    let directory: URL
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var knownFiles: Set<String> = []
    var onNewDownload: ((URL) -> Void)?

    init() {
        directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    func start() {
        // Track existing files
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: directory.path) {
            knownFiles = Set(contents)
        }

        fileDescriptor = open(directory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .userInitiated)
        )

        source.setEventHandler { [weak self] in
            self?.handleDirectoryChange()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }

        self.dispatchSource = source
        source.resume()
    }

    func stop() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    private func handleDirectoryChange() {
        guard let currentContents = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }
        let currentFiles = Set(currentContents)
        let newFiles = currentFiles.subtracting(knownFiles)
        knownFiles = currentFiles

        for filename in newFiles {
            if filename.hasPrefix(".") { continue }
            // Skip partial downloads
            if filename.hasSuffix(".crdownload") || filename.hasSuffix(".download") || filename.hasSuffix(".part") { continue }

            let url = directory.appendingPathComponent(filename)
            DispatchQueue.main.async {
                self.onNewDownload?(url)
            }
        }
    }
}
