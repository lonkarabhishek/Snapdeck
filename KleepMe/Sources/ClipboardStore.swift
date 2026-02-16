import AppKit
import Combine

enum ClipboardItemType: String, Codable {
    case text
    case image
    case url
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let textContent: String?
    let imageData: Data?
    var isPinned: Bool
    let date: Date

    var preview: String {
        switch type {
        case .text:
            return String((textContent ?? "").prefix(80))
        case .url:
            return textContent ?? "URL"
        case .image:
            return "Image"
        }
    }

    var iconName: String {
        switch type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        }
    }
}

class ClipboardStore: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""

    var willWriteToClipboard: (() -> Void)?

    private let maxItems = 20
    private let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("KleepMe")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()

    var displayItems: [ClipboardItem] {
        let filtered: [ClipboardItem]
        if searchText.isEmpty {
            filtered = items
        } else {
            let query = searchText.lowercased()
            filtered = items.filter { item in
                switch item.type {
                case .text, .url:
                    return item.textContent?.lowercased().contains(query) ?? false
                case .image:
                    return "image".contains(query)
                }
            }
        }
        let pinned = filtered.filter { $0.isPinned }
        let unpinned = filtered.filter { !$0.isPinned }
        return pinned + unpinned
    }

    func addItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // Deduplicate: remove existing item with same content
            self.items.removeAll { existing in
                existing.type == item.type &&
                existing.textContent == item.textContent &&
                existing.imageData == item.imageData
            }

            self.items.insert(item, at: 0)

            // Enforce max: only evict unpinned items
            while self.items.count > self.maxItems {
                if let lastUnpinnedIndex = self.items.lastIndex(where: { !$0.isPinned }) {
                    self.items.remove(at: lastUnpinnedIndex)
                } else {
                    break
                }
            }

            self.saveToDisk()
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        willWriteToClipboard?()
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case .text:
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .url:
            if let urlString = item.textContent {
                pb.setString(urlString, forType: .string)
                if let url = URL(string: urlString) {
                    pb.writeObjects([url as NSURL])
                }
            }
        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pb.writeObjects([image])
            }
        }
    }

    func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            saveToDisk()
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func clearAll() {
        items.removeAll { !$0.isPinned }
        saveToDisk()
    }

    // MARK: - Persistence

    func saveToDisk() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        self.items = loaded
    }
}
