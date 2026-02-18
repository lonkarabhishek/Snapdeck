import AppKit
import SwiftUI

class DropHostingView<Content: View>: NSHostingView<Content> {
    var onPasteboardDrop: ((NSPasteboard) -> Bool)?

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return onPasteboardDrop?(sender.draggingPasteboard) ?? false
    }
}
