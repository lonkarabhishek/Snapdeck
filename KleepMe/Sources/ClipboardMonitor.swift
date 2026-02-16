import AppKit

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private var skipNextChange = false
    var onNewClipboardContent: ((ClipboardItem) -> Void)?

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func ignoreNextChange() {
        skipNextChange = true
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        let currentCount = pb.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if skipNextChange {
            skipNextChange = false
            return
        }

        // Priority: URL > Image > Text
        if let urlString = pb.string(forType: .string),
           urlString.hasPrefix("http://") || urlString.hasPrefix("https://"),
           URL(string: urlString) != nil {
            let item = ClipboardItem(
                id: UUID(), type: .url,
                textContent: urlString, imageData: nil,
                isPinned: false, date: Date()
            )
            onNewClipboardContent?(item)
        } else if let imageData = pb.data(forType: .tiff) ?? pb.data(forType: .png) {
            let pngData = resizeIfNeeded(imageData)
            let item = ClipboardItem(
                id: UUID(), type: .image,
                textContent: nil, imageData: pngData,
                isPinned: false, date: Date()
            )
            onNewClipboardContent?(item)
        } else if let text = pb.string(forType: .string),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = ClipboardItem(
                id: UUID(), type: .text,
                textContent: text, imageData: nil,
                isPinned: false, date: Date()
            )
            onNewClipboardContent?(item)
        }
    }

    private func resizeIfNeeded(_ data: Data, maxDimension: CGFloat = 512) -> Data? {
        guard let image = NSImage(data: data) else { return data }
        let size = image.size
        if size.width <= maxDimension && size.height <= maxDimension {
            // Still convert to PNG for consistent storage
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData) else { return data }
            return bitmap.representation(using: .png, properties: [:])
        }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .sourceOver, fraction: 1.0)
        resized.unlockFocus()
        guard let tiffData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return data }
        return bitmap.representation(using: .png, properties: [:])
    }
}
