import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var store: ScreenshotStore!
    private var watcher: ScreenshotWatcher!
    private var floatingWindow: FloatingThumbnailWindow!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = ScreenshotStore()
        watcher = ScreenshotWatcher()

        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Snapdeck")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuBarView(store: store))

        // Setup floating thumbnail window
        floatingWindow = FloatingThumbnailWindow()
        floatingWindow.onCopy = { [weak self] url in
            guard let self = self else { return }
            if let item = self.store.screenshots.first(where: { $0.url == url }) {
                self.store.copyToClipboard(screenshot: item)
            }
        }

        // Watch for new screenshots
        watcher.onNewScreenshot = { [weak self] url in
            guard let self = self else { return }
            self.store.addScreenshot(url: url)
            // Show floating thumbnail
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.floatingWindow.show(for: url)
            }
        }

        // Load existing screenshots then start watching
        store.loadExisting(from: watcher.directory)
        watcher.start()

        // Monitor for clicks outside the popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Refresh the view with latest store state
            popover.contentViewController = NSHostingController(rootView: MenuBarView(store: store))
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Make popover key window so it can receive events
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
