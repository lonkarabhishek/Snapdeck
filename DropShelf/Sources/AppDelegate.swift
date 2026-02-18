import AppKit
import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var store: ShelfStore!
    private var panel: NSPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = ShelfStore()

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "DropShelf")
            button.action = #selector(togglePanel)
            button.target = self
        }

        // Use NSPanel with custom drop-enabled hosting view
        let hostingView = DropHostingView(rootView: MenuBarView(store: store))
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 400)
        hostingView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) } + [
            .fileURL, .tiff, .png, .string
        ])
        hostingView.onPasteboardDrop = { [weak self] pasteboard in
            self?.store.handlePasteboardDrop(pasteboard) ?? false
        }

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .windowBackgroundColor
        panel.contentView = hostingView
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

    }

    func applicationWillTerminate(_ notification: Notification) {}

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            guard let button = statusItem.button, let window = button.window else { return }
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = window.convertToScreen(buttonFrame)

            let x = screenFrame.midX - panel.frame.width / 2
            let y = screenFrame.minY - panel.frame.height - 4

            panel.setFrameOrigin(NSPoint(x: x, y: y))
            panel.makeKeyAndOrderFront(nil)
        }
    }
}
