import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var monitor: NetworkMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = NetworkMonitor()

        // Status bar item — variable length so we can show ping
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wifi", accessibilityDescription: "WiFiMon")
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusTitle()
        }

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 420)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: MenuBarView(monitor: monitor))

        // Start monitoring
        monitor.start()

        // Update menu bar title when ping changes
        monitor.onStatusChange = { [weak self] in
            self?.updateStatusTitle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func updateStatusTitle() {
        if let button = statusItem.button {
            let text = monitor.statusText
            if text.contains("ms") {
                button.title = " \(text)"
            } else {
                button.title = ""
            }
        }
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
