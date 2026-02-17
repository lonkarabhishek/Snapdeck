import AppKit
import Combine

struct ScreenshotItem: Identifiable, Equatable {
    let id: URL
    let url: URL
    let thumbnail: NSImage
    let filename: String
    let date: Date

    static func == (lhs: ScreenshotItem, rhs: ScreenshotItem) -> Bool {
        lhs.id == rhs.id
    }
}

class ScreenshotStore: ObservableObject {
    @Published var screenshots: [ScreenshotItem] = []
    private let maxItems = 20
    private var directory: URL?

    func refresh() {
        guard let dir = directory else { return }
        loadExisting(from: dir)
    }

    func loadExisting(from directory: URL) {
        self.directory = directory
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey, .contentTypeKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let pngFiles = contents.filter { url in
            url.pathExtension.lowercased() == "png" && isScreenshotFile(url)
        }

        let sorted = pngFiles.compactMap { url -> (URL, Date)? in
            guard let attrs = try? fm.attributesOfItem(atPath: url.path),
                  let date = attrs[.creationDate] as? Date else { return nil }
            return (url, date)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(maxItems)

        var items: [ScreenshotItem] = []
        for (url, date) in sorted {
            if let item = makeItem(url: url, date: date) {
                items.append(item)
            }
        }

        DispatchQueue.main.async {
            self.screenshots = items
        }
    }

    func addScreenshot(url: URL) {
        let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.creationDate] as? Date ?? Date()
        guard let item = makeItem(url: url, date: date) else { return }

        DispatchQueue.main.async {
            self.screenshots.insert(item, at: 0)
            if self.screenshots.count > self.maxItems {
                self.screenshots = Array(self.screenshots.prefix(self.maxItems))
            }
        }
    }

    func copyToClipboard(screenshot: ScreenshotItem) {
        guard let image = NSImage(contentsOf: screenshot.url) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    func showInFinder(screenshot: ScreenshotItem) {
        NSWorkspace.shared.activateFileViewerSelecting([screenshot.url])
    }

    private func makeItem(url: URL, date: Date) -> ScreenshotItem? {
        guard let image = NSImage(contentsOf: url) else { return nil }
        let thumbSize = NSSize(width: 120, height: 120)
        let thumbnail = NSImage(size: thumbSize)
        thumbnail.lockFocus()
        let aspect = image.size.width / image.size.height
        var drawRect: NSRect
        if aspect > 1 {
            let h = thumbSize.width / aspect
            drawRect = NSRect(x: 0, y: (thumbSize.height - h) / 2, width: thumbSize.width, height: h)
        } else {
            let w = thumbSize.height * aspect
            drawRect = NSRect(x: (thumbSize.width - w) / 2, y: 0, width: w, height: thumbSize.height)
        }
        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        thumbnail.unlockFocus()

        return ScreenshotItem(
            id: url,
            url: url,
            thumbnail: thumbnail,
            filename: url.lastPathComponent,
            date: date
        )
    }

    private func isScreenshotFile(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        if name.hasPrefix("Screenshot ") || name.hasPrefix("Clean Shot ") {
            return true
        }
        // Also include recent .png files (created in the last 24 hours) as potential screenshots
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let date = attrs[.creationDate] as? Date,
           Date().timeIntervalSince(date) < 86400 {
            return name.hasSuffix(".png")
        }
        return false
    }
}
