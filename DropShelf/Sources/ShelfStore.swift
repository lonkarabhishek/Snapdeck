import AppKit
import UniformTypeIdentifiers

class ShelfStore: ObservableObject {
    @Published var items: [ShelfItem] = []
    @Published var selectedIds: Set<UUID> = []

    var selectedItems: [ShelfItem] {
        items.filter { selectedIds.contains($0.id) }
    }

    var hasSelection: Bool {
        !selectedIds.isEmpty
    }

    func toggleSelection(_ item: ShelfItem) {
        if selectedIds.contains(item.id) {
            selectedIds.remove(item.id)
        } else {
            selectedIds.insert(item.id)
        }
    }

    func selectAll() {
        selectedIds = Set(items.map { $0.id })
    }

    func clearSelection() {
        selectedIds.removeAll()
    }

    func removeSelected() {
        items.removeAll { selectedIds.contains($0.id) }
        selectedIds.removeAll()
    }

    func copySelectedToClipboard() {
        let selected = selectedItems
        guard !selected.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        var objects: [NSPasteboardWriting] = []
        for item in selected {
            switch item.type {
            case .file:
                if let url = item.fileURL { objects.append(url as NSURL) }
            case .text:
                if let text = item.text { objects.append(text as NSString) }
            case .image:
                if let data = item.imageData, let image = NSImage(data: data) { objects.append(image) }
            }
        }
        pb.writeObjects(objects)
    }

    func addFile(url: URL) {
        DispatchQueue.main.async {
            // Don't add duplicates
            if self.items.contains(where: { $0.fileURL == url }) { return }
            self.items.insert(ShelfItem.fromFile(url: url), at: 0)
        }
    }

    func addText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        DispatchQueue.main.async {
            self.items.insert(ShelfItem.fromText(trimmed), at: 0)
        }
    }

    func addImage(data: Data) {
        DispatchQueue.main.async {
            self.items.insert(ShelfItem.fromImage(data: data), at: 0)
        }
    }

    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll()
    }

    func copyToClipboard(_ item: ShelfItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case .file:
            if let url = item.fileURL {
                pb.writeObjects([url as NSURL])
            }
        case .text:
            if let text = item.text {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pb.writeObjects([image])
            }
        }
    }

    func handlePasteboardDrop(_ pasteboard: NSPasteboard) -> Bool {
        // Try file URLs first — works for ALL file types (png, pdf, zip, anything)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty {
            for url in urls {
                addFile(url: url)
            }
            return true
        }

        // Try images (from browser drag, copy-paste, etc.)
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], !images.isEmpty {
            for image in images {
                if let tiff = image.tiffRepresentation {
                    addImage(data: tiff)
                }
            }
            return true
        }

        // Try strings
        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], !strings.isEmpty {
            for text in strings {
                addText(text)
            }
            return true
        }

        return false
    }
}
