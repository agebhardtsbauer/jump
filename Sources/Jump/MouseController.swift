import AppKit
import CoreGraphics

/// Controls mouse cursor movement using CoreGraphics APIs
class MouseController {
    /// Move the mouse cursor to the specified point (in Accessibility coordinates)
    /// - Parameter axPoint: The point in Accessibility coordinates (top-left origin)
    func moveMouse(to axPoint: CGPoint) {
        // Convert to CoreGraphics coordinates (bottom-left origin)
        let cgPoint = CoordinateConverter.toAppKit(axPoint)

        // print("Moving mouse: AX(\(axPoint.x), \(axPoint.y)) -> CG(\(cgPoint.x), \(cgPoint.y))")

        // Create and post mouse move event
        if let moveEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .mouseMoved,
                                   mouseCursorPosition: cgPoint,
                                   mouseButton: .left)
        {
            moveEvent.post(tap: .cgSessionEventTap)
        }
    }

    /// Move the mouse to the center of a given rectangle (in Accessibility coordinates)
    /// - Parameter axFrame: The rectangle in Accessibility coordinates (top-left origin)
    func moveMouse(toCenter axFrame: CGRect) {
        // Calculate center point in Accessibility coordinates
        let centerPoint = CoordinateConverter.centerPoint(of: axFrame)
        print("Moving mouse to center of frame: \(axFrame)")
        moveMouse(to: centerPoint)
    }
}
