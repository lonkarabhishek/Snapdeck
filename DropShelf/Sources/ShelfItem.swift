import AppKit
import UniformTypeIdentifiers

enum ShelfItemType: String {
    case file
    case image
    case text
}

struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let type: ShelfItemType
    let fileURL: URL?
    let text: String?
    let imageData: Data?
    let icon: NSImage
    let title: String
    let date: Date

    static func fromFile(url: URL) -> ShelfItem {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        return ShelfItem(
            id: UUID(),
            type: .file,
            fileURL: url,
            text: nil,
            imageData: nil,
            icon: icon,
            title: url.lastPathComponent,
            date: Date()
        )
    }

    static func fromText(_ text: String) -> ShelfItem {
        let icon = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Text") ?? NSImage()
        icon.size = NSSize(width: 32, height: 32)
        return ShelfItem(
            id: UUID(),
            type: .text,
            fileURL: nil,
            text: text,
            imageData: nil,
            icon: icon,
            title: String(text.prefix(60)),
            date: Date()
        )
    }

    static func fromImage(data: Data) -> ShelfItem {
        let icon: NSImage
        if let img = NSImage(data: data) {
            img.size = NSSize(width: 32, height: 32)
            icon = img
        } else {
            icon = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image") ?? NSImage()
        }
        return ShelfItem(
            id: UUID(),
            type: .image,
            fileURL: nil,
            text: nil,
            imageData: data,
            icon: icon,
            title: "Image",
            date: Date()
        )
    }

    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}
