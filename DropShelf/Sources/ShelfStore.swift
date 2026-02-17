import AppKit
import UniformTypeIdentifiers

class ShelfStore: ObservableObject {
    @Published var items: [ShelfItem] = []

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

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false

        for provider in providers {
            // Files / URLs
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] data, _ in
                    if let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        self?.addFile(url: url)
                    }
                }
                handled = true
            }
            // Images
            else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, _ in
                    if let data = data as? Data {
                        self?.addImage(data: data)
                    } else if let url = data as? URL, let imageData = try? Data(contentsOf: url) {
                        self?.addImage(data: imageData)
                    }
                }
                handled = true
            }
            // Plain text
            else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                    if let data = data as? Data, let text = String(data: data, encoding: .utf8) {
                        self?.addText(text)
                    } else if let text = data as? String {
                        self?.addText(text)
                    }
                }
                handled = true
            }
        }

        return handled
    }
}
