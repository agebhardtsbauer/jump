import Cocoa

/// Delegate protocol for overlay window events
protocol OverlayWindowDelegate: AnyObject {
    func overlayWindow(_ window: OverlayWindow, didUpdateText text: String)
    func overlayWindowDidPressEnter(_ window: OverlayWindow, withText text: String)
    func overlayWindowDidPressEscape(_ window: OverlayWindow)
    func overlayWindowDidPressNumber(_ window: OverlayWindow, number: Int)
}

/// Transparent overlay window with text field for search input
class OverlayWindow: NSWindow {
    weak var overlayDelegate: OverlayWindowDelegate?
    private var textField: NSTextField!
    private let windowWidth: CGFloat = 500
    private let windowHeight: CGFloat = 50

    init() {
        // Create window in center of screen
        let screenRect = NSScreen.main?.frame ?? NSRect.zero
        let windowRect = NSRect(
            x: (screenRect.width - windowWidth) / 2,
            y: screenRect.height - 100,
            width: windowWidth,
            height: windowHeight
        )

        super.init(
            contentRect: windowRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupTextField()
    }

    private func setupWindow() {
        backgroundColor = NSColor.black.withAlphaComponent(0.8)
        isOpaque = false
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
        delegate = self
    }

    /// Allow window to become key even though app is accessory
    override var canBecomeKey: Bool {
        return true
    }

    /// Intercept key events before they reach the text field
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        print("🔑 Window KeyEquivalent: keyCode=\(event.keyCode), chars=\(event.characters ?? "nil")")

        // Handle Enter key
        if event.keyCode == 36 {
            print("✅ Enter key intercepted")
            overlayDelegate?.overlayWindowDidPressEnter(self, withText: textField.stringValue)
            return true
        }

        // Handle number keys 1-9
        switch event.keyCode {
        case 18: print("✅ Number 1 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 1); return true
        case 19: print("✅ Number 2 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 2); return true
        case 20: print("✅ Number 3 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 3); return true
        case 21: print("✅ Number 4 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 4); return true
        case 23: print("✅ Number 5 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 5); return true
        case 22: print("✅ Number 6 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 6); return true
        case 26: print("✅ Number 7 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 7); return true
        case 28: print("✅ Number 8 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 8); return true
        case 25: print("✅ Number 9 intercepted"); overlayDelegate?.overlayWindowDidPressNumber(self, number: 9); return true
        default:
            break
        }

        return super.performKeyEquivalent(with: event)
    }

    private func setupTextField() {
        textField = CustomTextField(frame: NSRect(
            x: 10,
            y: 10,
            width: windowWidth - 20,
            height: 30
        ))

        textField.font = NSFont.systemFont(ofSize: 18)
        textField.alignment = .center
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.isBordered = false
        textField.focusRingType = .none
        textField.delegate = self

        contentView?.addSubview(textField)
    }

    /// Show the overlay and focus the text field
    func show() {
        textField.stringValue = ""

        // Activate the app to accept keyboard input
        NSApp.activate(ignoringOtherApps: true)

        makeKeyAndOrderFront(nil)

        // Ensure window becomes key and text field gets focus
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.makeKey()
            self.makeFirstResponder(self.textField)
        }
    }

    /// Hide the overlay
    func hide() {
        orderOut(nil)
        textField.stringValue = ""
    }

    /// Get current text in the text field
    var currentText: String {
        return textField.stringValue
    }
}

// MARK: - NSWindowDelegate
extension OverlayWindow: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        // Auto-close when window loses focus (user clicked elsewhere)
        print("🔄 Window lost focus, auto-closing")
        overlayDelegate?.overlayWindowDidPressEscape(self)
    }
}

// MARK: - NSTextFieldDelegate
extension OverlayWindow: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let text = textField.stringValue
        overlayDelegate?.overlayWindow(self, didUpdateText: text)
    }
}

/// Custom text field that handles special key events
private class CustomTextField: NSTextField {
    override func keyDown(with event: NSEvent) {
        print("🔑 KeyDown: keyCode=\(event.keyCode), chars=\(event.characters ?? "nil")")

        guard let window = self.window as? OverlayWindow else {
            print("⚠️  Window is not OverlayWindow")
            super.keyDown(with: event)
            return
        }

        // Check for special keys by keyCode
        switch event.keyCode {
        case 36: // Return/Enter
            print("✅ Enter key detected")
            window.overlayDelegate?.overlayWindowDidPressEnter(window, withText: stringValue)
            return

        case 53: // Escape
            print("✅ Escape key detected")
            window.overlayDelegate?.overlayWindowDidPressEscape(window)
            return

        // Number keys 1-9 (top row)
        case 18: print("✅ Number 1 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 1); return
        case 19: print("✅ Number 2 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 2); return
        case 20: print("✅ Number 3 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 3); return
        case 21: print("✅ Number 4 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 4); return
        case 23: print("✅ Number 5 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 5); return
        case 22: print("✅ Number 6 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 6); return
        case 26: print("✅ Number 7 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 7); return
        case 28: print("✅ Number 8 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 8); return
        case 25: print("✅ Number 9 detected"); window.overlayDelegate?.overlayWindowDidPressNumber(window, number: 9); return

        default:
            print("⏭️  Passing to super.keyDown")
            break
        }

        super.keyDown(with: event)
    }

    /// Handle escape key (called by Cocoa framework on Esc)
    override func cancelOperation(_ sender: Any?) {
        if let window = self.window as? OverlayWindow {
            window.overlayDelegate?.overlayWindowDidPressEscape(window)
        }
    }
}
