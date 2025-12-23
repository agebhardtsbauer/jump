import CoreGraphics
import AppKit

/// Controls mouse cursor movement using CoreGraphics APIs
class MouseController {

    /// Move the mouse cursor to the specified point
    /// - Parameter point: The screen coordinates to move to (origin: top-left)
    func moveMouse(to point: CGPoint) {
        // Convert to CoreGraphics coordinates (origin: bottom-left)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgPoint = CGPoint(x: point.x, y: screenHeight - point.y)

        // Create and post mouse move event
        if let moveEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .mouseMoved,
                                   mouseCursorPosition: cgPoint,
                                   mouseButton: .left) {
            moveEvent.post(tap: .cgSessionEventTap)
        }
    }

    /// Move the mouse to the center of a given rectangle
    /// - Parameter rect: The rectangle in screen coordinates
    func moveMouse(toCenter rect: CGRect) {
        let centerPoint = CGPoint(
            x: rect.origin.x + rect.size.width / 2,
            y: rect.origin.y + rect.size.height / 2
        )
        print("Moving mouse to element at: \(centerPoint) (from frame: \(rect))")
        moveMouse(to: centerPoint)
    }
}
