import AppKit

class SelectionOverlay: NSWindow {
    private var selectionView: SelectionView!
    var onSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    init() {
        guard let screen = NSScreen.main else {
            super.init(
                contentRect: .zero,
                styleMask: [.borderless],
                backing: .buffered,
                defer: true
            )
            return
        }

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )

        self.level = .statusBar + 1
        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.2)
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.hasShadow = false

        selectionView = SelectionView(frame: screen.frame)
        selectionView.onSelection = { [weak self] rect in
            self?.handleSelection(rect)
        }
        selectionView.onCancel = { [weak self] in
            self?.dismiss()
            self?.onCancel?()
        }

        self.contentView = selectionView
    }

    func show() {
        guard let screen = NSScreen.main else { return }
        self.setFrame(screen.frame, display: true)
        self.makeKeyAndOrderFront(nil)
        NSCursor.crosshair.push()
    }

    private func dismiss() {
        NSCursor.pop()
        self.orderOut(nil)
    }

    private func handleSelection(_ rect: NSRect) {
        dismiss()

        guard let screen = NSScreen.main else { return }
        // Convert from window coordinates (origin bottom-left) to screen coordinates for CGWindowListCreateImage (origin top-left)
        let screenHeight = screen.frame.height
        let cgRect = CGRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        onSelection?(cgRect)
    }
}

class SelectionView: NSView {
    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    var onSelection: ((NSRect) -> Void)?
    var onCancel: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = nil
        setNeedsDisplay(bounds)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)

        currentRect = NSRect(x: x, y: y, width: w, height: h)
        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width > 10, rect.height > 10 else {
            startPoint = nil
            currentRect = nil
            setNeedsDisplay(bounds)
            return
        }
        onSelection?(rect)
        startPoint = nil
        currentRect = nil
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        // Dim overlay
        NSColor.black.withAlphaComponent(0.2).setFill()
        dirtyRect.fill()

        // Draw selection rectangle
        guard let rect = currentRect else { return }

        // Clear the selected area
        NSColor.clear.setFill()
        rect.fill(using: .copy)

        // Draw border around selection
        let border = NSBezierPath(rect: rect)
        NSColor.white.setStroke()
        border.lineWidth = 1.5
        border.stroke()

        // Dashed inner border
        let innerBorder = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        NSColor.systemBlue.withAlphaComponent(0.6).setStroke()
        innerBorder.lineWidth = 1
        innerBorder.setLineDash([4, 4], count: 2, phase: 0)
        innerBorder.stroke()
    }
}
