import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var store: DownloadStore!
    private var watcher: DownloadWatcher!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = DownloadStore()
        watcher = DownloadWatcher()

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "CleanDock")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 450)
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuBarView(store: store))

        // Watch for new downloads
        watcher.onNewDownload = { [weak self] url in
            // Small delay for file to finish writing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.store.addDownload(url: url)
            }
        }

        // Load existing downloads then start watching
        store.loadExisting()
        watcher.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stop()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Refresh on open
            store.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
