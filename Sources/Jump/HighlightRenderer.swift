import Cocoa

/// Renders transparent green highlights over matching UI elements
class HighlightRenderer {
    private var highlightWindows: [NSWindow] = []
    private let maxHighlights = 9  // Limit to 9 since we only support keys 1-9

    /// Show highlights for matched elements with numeric labels
    /// - Parameter matches: Array of matched elements to highlight
    func showHighlights(for matches: [MatchedElement]) {
        // Clear existing highlights
        clearHighlights()

        // Limit to maxHighlights to prevent creating too many windows
        let limitedMatches = Array(matches.prefix(maxHighlights))
        print("Showing \(limitedMatches.count) highlights")

        // Create highlight window for each match
        for (index, match) in limitedMatches.enumerated() {
            let window = createHighlightWindow(
                frame: match.element.frame,
                label: index + 1
            )
            highlightWindows.append(window)
            window.orderFrontRegardless()
        }
    }

    /// Clear all highlight windows
    func clearHighlights() {
        print("Clearing \(highlightWindows.count) highlights")
        for window in highlightWindows {
            window.orderOut(nil)
            window.contentView = nil
        }
        highlightWindows.removeAll()
    }

    /// Convert Accessibility coordinates (top-left origin) to AppKit coordinates (bottom-left origin)
    private func convertToAppKitCoordinates(_ axFrame: CGRect) -> NSRect {
        guard let screen = NSScreen.main else {
            return axFrame
        }

        let screenHeight = screen.frame.height

        // AX: y=0 is at top, AppKit: y=0 is at bottom
        // Convert: AppKit_y = screenHeight - AX_y - height
        let appKitY = screenHeight - axFrame.origin.y - axFrame.size.height

        return NSRect(
            x: axFrame.origin.x,
            y: appKitY,
            width: axFrame.size.width,
            height: axFrame.size.height
        )
    }

    /// Create a single highlight window
    private func createHighlightWindow(frame: CGRect, label: Int) -> NSWindow {
        // Convert from Accessibility coordinates (top-left origin) to AppKit coordinates (bottom-left origin)
        let convertedFrame = convertToAppKitCoordinates(frame)

        let window = NSWindow(
            contentRect: convertedFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isReleasedWhenClosed = false

        // Create custom view for drawing
        let highlightView = HighlightView(frame: NSRect(origin: .zero, size: frame.size))
        highlightView.label = label
        window.contentView = highlightView

        return window
    }
}

/// Custom view that draws the green highlight and numeric label
private class HighlightView: NSView {
    var label: Int = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw semi-transparent green rectangle
        NSColor.green.withAlphaComponent(0.3).setFill()
        let path = NSBezierPath(rect: bounds)
        path.fill()

        // Draw green border
        NSColor.green.withAlphaComponent(0.8).setStroke()
        path.lineWidth = 2
        path.stroke()

        // Draw numeric label in top-left corner
        let labelText = "[\(label)]"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.green.withAlphaComponent(0.9)
        ]

        let attributedString = NSAttributedString(string: labelText, attributes: attributes)
        let labelSize = attributedString.size()

        // Add padding around label
        let padding: CGFloat = 4
        let labelRect = NSRect(
            x: padding,
            y: bounds.height - labelSize.height - padding,
            width: labelSize.width + padding * 2,
            height: labelSize.height + padding * 2
        )

        // Draw background for label
        NSColor.green.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4).fill()

        // Draw label text
        attributedString.draw(at: NSPoint(
            x: labelRect.origin.x + padding,
            y: labelRect.origin.y + padding
        ))
    }
}
