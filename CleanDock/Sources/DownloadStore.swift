import AppKit
import Combine

class DownloadStore: ObservableObject {
    @Published var items: [DownloadItem] = []
    @Published var autoCleanEnabled: Bool = false {
        didSet { savePreferences() }
    }

    let downloadsDir: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

    private let prefsURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("CleanDock")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("prefs.json")
    }()

    var oldItemsCount: Int {
        items.filter { $0.isOld }.count
    }

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.fileSize }
    }

    var oldItemsSize: Int64 {
        items.filter { $0.isOld }.reduce(0) { $0 + $1.fileSize }
    }

    func loadExisting() {
        loadPreferences()

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: downloadsDir,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var allItems: [DownloadItem] = []
        for url in contents {
            if let item = makeItem(url: url) {
                allItems.append(item)
            }
        }

        // Sort by date, newest first
        allItems.sort { $0.date > $1.date }
        self.items = allItems

        // Auto-clean on launch if enabled
        if autoCleanEnabled {
            cleanOldFiles()
        }
    }

    func addDownload(url: URL) {
        guard let item = makeItem(url: url) else { return }
        DispatchQueue.main.async {
            self.items.removeAll { $0.url == url }
            self.items.insert(item, at: 0)
        }
    }

    func refresh() {
        loadExisting()
    }

    func moveToTrash(_ item: DownloadItem) {
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            DispatchQueue.main.async {
                self.items.removeAll { $0.id == item.id }
            }
        } catch {}
    }

    func showInFinder(_ item: DownloadItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    func openFile(_ item: DownloadItem) {
        NSWorkspace.shared.open(item.url)
    }

    func cleanOldFiles() {
        let oldItems = items.filter { $0.isOld }
        for item in oldItems {
            moveToTrash(item)
        }
    }

    private func makeItem(url: URL) -> DownloadItem? {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: url.path) else { return nil }

        // Skip .DS_Store and other system files
        let filename = url.lastPathComponent
        if filename.hasPrefix(".") { return nil }

        let date = (attrs[.creationDate] as? Date) ?? Date()
        let size = (attrs[.size] as? Int64) ?? 0
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)

        return DownloadItem(
            id: url,
            url: url,
            filename: filename,
            date: date,
            fileSize: size,
            icon: icon
        )
    }

    private func savePreferences() {
        let data = try? JSONEncoder().encode(["autoClean": autoCleanEnabled])
        try? data?.write(to: prefsURL, options: .atomic)
    }

    private func loadPreferences() {
        guard let data = try? Data(contentsOf: prefsURL),
              let prefs = try? JSONDecoder().decode([String: Bool].self, from: data) else { return }
        self.autoCleanEnabled = prefs["autoClean"] ?? false
    }
}
