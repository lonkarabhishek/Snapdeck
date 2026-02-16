import AppKit
import Combine

class ScratchStore: ObservableObject {
    @Published var text: String = "" {
        didSet { saveToDisk() }
    }

    private let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("QuickScrap")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("scratch.txt")
    }()

    func loadFromDisk() {
        guard let content = try? String(contentsOf: storageURL, encoding: .utf8) else { return }
        self.text = content
    }

    func saveToDisk() {
        try? text.write(to: storageURL, atomically: true, encoding: .utf8)
    }

    var characterCount: Int {
        text.count
    }

    var lineCount: Int {
        text.isEmpty ? 0 : text.components(separatedBy: .newlines).count
    }

    func clear() {
        text = ""
    }
}
