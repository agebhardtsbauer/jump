import Cocoa

/// Main coordinator that manages the application flow
class AppCoordinator {
    private let hotkeyManager = HotkeyManager()
    private let overlayWindow = OverlayWindow()
    private let scanner = AccessibilityScanner()
    private let matcher = ElementMatcher()
    private let highlightRenderer = HighlightRenderer()
    private let mouseController = MouseController()

    private var currentMatches: [MatchedElement] = []
    private var allElements: [AccessibleElement] = []
    private var targetApp: NSRunningApplication?

    init() {
        setupHotkey()
        setupOverlay()
    }

    /// Setup hotkey registration
    private func setupHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.handleHotkeyPressed()
        }

        if hotkeyManager.registerHotkey() {
            print("✓ Hotkey registered: cmd + ctrl + shift + opt + space")
        } else {
            print("✗ Failed to register hotkey")
        }
    }

    /// Setup overlay window delegate
    private func setupOverlay() {
        overlayWindow.overlayDelegate = self
    }

    /// Handle hotkey activation
    private func handleHotkeyPressed() {
        // Check accessibility permissions
        guard AccessibilityScanner.checkAccessibilityPermissions() else {
            print("⚠ Accessibility permissions not granted")
            showAccessibilityAlert()
            return
        }

        // IMPORTANT: Capture frontmost app BEFORE activating Jump
        targetApp = NSWorkspace.shared.frontmostApplication

        // Show overlay and scan elements
        overlayWindow.show()
        scanElements()
    }

    /// Scan elements from target application
    private func scanElements() {
        guard let app = targetApp else {
            print("⚠ No target application")
            return
        }

        let appName = app.localizedName ?? "Unknown"
        print("Scanning app: \(appName)")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let elements = self.scanner.scanApplication(app)

            DispatchQueue.main.async {
                self.allElements = elements
                print("Found \(elements.count) accessible elements in \(appName)")
            }
        }
    }

    /// Update matches based on current search text
    private func updateMatches(for text: String) {
        if text.isEmpty {
            currentMatches = []
            highlightRenderer.clearHighlights()
            return
        }

        // Perform matching on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let matches = self.matcher.match(query: text, in: self.allElements)

            DispatchQueue.main.async {
                self.currentMatches = matches
                self.highlightRenderer.showHighlights(for: matches)
                print("Matched \(matches.count) elements")
            }
        }
    }

    /// Handle element selection
    private func selectElement(at index: Int) {
        guard index >= 0 && index < currentMatches.count else {
            print("⚠ Invalid selection index: \(index) (have \(currentMatches.count) matches)")
            return
        }

        let match = currentMatches[index]
        print("✓ Selecting element #\(index + 1): \(match.matchedText)")
        mouseController.moveMouse(toCenter: match.element.frame)
        hideOverlay()
    }

    /// Hide overlay and clear highlights
    private func hideOverlay() {
        overlayWindow.hide()
        highlightRenderer.clearHighlights()
        currentMatches = []
        allElements = []

        // Return focus to the original application
        if let app = targetApp {
            app.activate(options: [])
            print("↩️  Returning focus to \(app.localizedName ?? "app")")
        }
        targetApp = nil
    }

    /// Show accessibility permissions alert
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        Jump needs Accessibility permissions to scan UI elements.

        Please enable it in:
        System Preferences > Privacy & Security > Accessibility

        Then restart Jump.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            AccessibilityScanner.requestAccessibilityPermissions()
        }
    }
}

// MARK: - OverlayWindowDelegate
extension AppCoordinator: OverlayWindowDelegate {
    func overlayWindow(_ window: OverlayWindow, didUpdateText text: String) {
        updateMatches(for: text)
    }

    func overlayWindowDidPressEnter(_ window: OverlayWindow, withText text: String) {
        print("📥 Enter pressed with text: '\(text)', matches: \(currentMatches.count)")
        // If exactly one match, select it
        if currentMatches.count == 1 {
            print("→ Selecting single match")
            selectElement(at: 0)
        } else if currentMatches.isEmpty {
            print("→ No matches, closing")
            // No matches, just close
            hideOverlay()
        } else {
            print("→ Multiple matches (\(currentMatches.count)), need number key")
            // Multiple matches, do nothing (user should press number)
            NSSound.beep()
        }
    }

    func overlayWindowDidPressEscape(_ window: OverlayWindow) {
        print("📥 Escape pressed, closing overlay")
        hideOverlay()
    }

    func overlayWindowDidPressNumber(_ window: OverlayWindow, number: Int) {
        print("📥 Number \(number) pressed")
        // Numbers are 1-indexed, array is 0-indexed
        selectElement(at: number - 1)
    }
}
