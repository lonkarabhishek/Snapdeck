import AppKit

class DraggableContentView: NSView {
    var onClicked: (() -> Void)?
    private var dragThreshold: CGFloat = 3
    private var mouseDownLocation: NSPoint = .zero
    private var didDrag = false

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        didDrag = false
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        let current = event.locationInWindow
        let dx = current.x - mouseDownLocation.x
        let dy = current.y - mouseDownLocation.y
        if sqrt(dx * dx + dy * dy) > dragThreshold {
            didDrag = true
        }
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if !didDrag {
            onClicked?()
        }
        super.mouseUp(with: event)
    }
}

class FloatingThumbnailWindow: NSPanel {
    private var autoDismissTimer: Timer?
    private var copiedLabel: NSTextField?
    private var imageView: NSImageView?
    private var screenshotURL: URL?
    var onCopy: ((URL) -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 170),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.animationBehavior = .utilityWindow

        setupUI()
        positionAtBottomRight()
    }

    private func setupUI() {
        let container = DraggableContentView(frame: NSRect(x: 0, y: 0, width: 220, height: 170))
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.masksToBounds = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        container.layer?.borderColor = NSColor.separatorColor.cgColor
        container.layer?.borderWidth = 0.5
        container.onClicked = { [weak self] in self?.handleClick() }

        let imgView = NSImageView(frame: NSRect(x: 10, y: 30, width: 200, height: 130))
        imgView.imageScaling = .scaleProportionallyUpOrDown
        imgView.wantsLayer = true
        imgView.layer?.cornerRadius = 6
        imgView.layer?.masksToBounds = true
        container.addSubview(imgView)
        self.imageView = imgView

        let label = NSTextField(labelWithString: "Click to copy  \u{b7}  Drag to move")
        label.frame = NSRect(x: 10, y: 6, width: 200, height: 20)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor
        container.addSubview(label)
        self.copiedLabel = label

        // Tracking area for hover
        let trackingArea = NSTrackingArea(
            rect: container.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        container.addTrackingArea(trackingArea)

        self.contentView = container
    }

    func show(for url: URL) {
        screenshotURL = url

        // Load image with a tiny delay to make sure the file is fully written
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if let image = NSImage(contentsOf: url) {
                self.imageView?.image = image
            }
            self.copiedLabel?.stringValue = "Click to copy  \u{b7}  Drag to move"
            self.copiedLabel?.textColor = .secondaryLabelColor
            self.positionAtBottomRight()

            self.alphaValue = 0
            self.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                self.animator().alphaValue = 1
            }

            self.resetDismissTimer()
        }
    }

    private func positionAtBottomRight() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - self.frame.width - 20
        let y = screenFrame.minY + 20
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func handleClick() {
        guard let url = screenshotURL else { return }
        onCopy?(url)

        copiedLabel?.stringValue = "Copied!"
        copiedLabel?.textColor = .systemGreen

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.dismissAnimated()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }

    override func mouseExited(with event: NSEvent) {
        resetDismissTimer()
    }

    private func resetDismissTimer() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.dismissAnimated()
        }
    }

    private func dismissAnimated() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
        })
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }
}
