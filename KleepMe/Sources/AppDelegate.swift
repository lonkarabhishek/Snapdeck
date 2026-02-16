import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var store: ClipboardStore!
    private var monitor: ClipboardMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = ClipboardStore()
        monitor = ClipboardMonitor()

        // Wire self-copy prevention
        store.willWriteToClipboard = { [weak self] in
            self?.monitor.ignoreNextChange()
        }

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "KleepMe")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuBarView(store: store))

        // Wire monitor to store
        monitor.onNewClipboardContent = { [weak self] item in
            self?.store.addItem(item)
        }

        // Load persisted history then start polling
        store.loadFromDisk()
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        store.saveToDisk()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
