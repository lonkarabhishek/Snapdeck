import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var store: TextStore!
    private var overlay: SelectionOverlay!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = TextStore()
        store.loadFromDisk()

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "TextGrab")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(store: store, onGrabText: { [weak self] in
                self?.startGrab()
            })
        )

        // Selection overlay
        overlay = SelectionOverlay()
        overlay.onSelection = { [weak self] rect in
            self?.handleSelection(rect)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
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

    private func startGrab() {
        popover.performClose(nil)
        // Small delay so the popover closes before the overlay appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.overlay.show()
        }
    }

    private func handleSelection(_ rect: CGRect) {
        guard rect.width > 5, rect.height > 5 else { return }

        guard let image = OCREngine.captureScreen(rect: rect) else { return }

        OCREngine.recognizeText(in: image) { [weak self] text in
            DispatchQueue.main.async {
                guard let text = text, !text.isEmpty else { return }
                self?.store.addText(text)
            }
        }
    }
}
