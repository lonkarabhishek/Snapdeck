import AppKit
import Combine

struct TextItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date

    var preview: String {
        String(text.prefix(100))
    }
}

class TextStore: ObservableObject {
    @Published var items: [TextItem] = []

    private let maxItems = 20
    private let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("TextGrab")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()

    func addText(_ text: String) {
        let item = TextItem(id: UUID(), text: text, date: Date())
        DispatchQueue.main.async {
            // Deduplicate
            self.items.removeAll { $0.text == text }
            self.items.insert(item, at: 0)
            if self.items.count > self.maxItems {
                self.items = Array(self.items.prefix(self.maxItems))
            }
            self.saveToDisk()
        }

        // Copy to clipboard
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    func copyToClipboard(_ item: TextItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
    }

    func deleteItem(_ item: TextItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func clearAll() {
        items.removeAll()
        saveToDisk()
    }

    func saveToDisk() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? JSONDecoder().decode([TextItem].self, from: data) else { return }
        self.items = loaded
    }
}
