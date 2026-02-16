import AppKit

struct DownloadItem: Identifiable, Equatable {
    let id: URL
    let url: URL
    let filename: String
    let date: Date
    let fileSize: Int64
    let icon: NSImage

    var sizeString: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var ageInDays: Int {
        Int(Date().timeIntervalSince(date) / 86400)
    }

    var isOld: Bool {
        ageInDays >= 30
    }

    static func == (lhs: DownloadItem, rhs: DownloadItem) -> Bool {
        lhs.id == rhs.id
    }
}
