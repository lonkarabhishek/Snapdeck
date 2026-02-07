import Foundation

class ScreenshotWatcher {
    let directory: URL
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var knownFiles: Set<String> = []
    var onNewScreenshot: ((URL) -> Void)?

    init() {
        self.directory = ScreenshotWatcher.resolveScreenshotDirectory()
    }

    static func resolveScreenshotDirectory() -> URL {
        // Try reading the user's screenshot save location
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.screencapture", "location"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        return url
                    }
                }
            }
        } catch {}

        // Fall back to ~/Desktop
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }

    func start() {
        // Snapshot current files so we only detect truly new ones
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: directory.path) {
            knownFiles = Set(contents)
        }

        fileDescriptor = open(directory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("ScreenshotWatcher: Failed to open directory \(directory.path)")
            return
        }

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
        // Small delay to let the file finish writing
        Thread.sleep(forTimeInterval: 0.5)

        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }

        let currentFiles = Set(contents)
        let newFiles = currentFiles.subtracting(knownFiles)
        knownFiles = currentFiles

        for filename in newFiles {
            guard filename.hasSuffix(".png") else { continue }
            let url = directory.appendingPathComponent(filename)

            // Check if it looks like a screenshot
            if filename.hasPrefix("Screenshot ") || filename.hasPrefix("Clean Shot ") || isRecentScreenshot(url) {
                DispatchQueue.main.async {
                    self.onNewScreenshot?(url)
                }
            }
        }
    }

    private func isRecentScreenshot(_ url: URL) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let date = attrs[.creationDate] as? Date else { return false }
        return Date().timeIntervalSince(date) < 5
    }
}
