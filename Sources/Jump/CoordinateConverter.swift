import AppKit
import CoreGraphics

/// Utility for converting between coordinate systems
/// - Accessibility API: Origin at top-left (y increases downward)
/// - AppKit/CoreGraphics: Origin at bottom-left (y increases upward)
enum CoordinateConverter {

    /// Find the screen that contains a given point
    /// - Parameter point: Point in screen coordinates (Accessibility coordinates)
    /// - Returns: The screen containing the point, or main screen if not found
    private static func screen(containing point: CGPoint) -> NSScreen {
        print("📐 Finding screen for AX point: \(point)")
        print("📐 Available screens:")
        for (index, screen) in NSScreen.screens.enumerated() {
            print("   Screen \(index): frame=\(screen.frame)")
            // Note: screen.frame is in AppKit coordinates, but we need to check against AX coordinates
            // We need to check if the X coordinate matches and if the Y makes sense
            if screen.frame.minX <= point.x && point.x <= screen.frame.maxX {
                print("   ✓ Screen \(index) contains X coordinate \(point.x)")
                return screen
            }
        }
        let fallback = NSScreen.main ?? NSScreen.screens[0]
        print("   ⚠️ No screen found, using main screen: \(fallback.frame)")
        return fallback
    }

    /// Find the screen that contains a given frame
    /// - Parameter frame: Frame in screen coordinates
    /// - Returns: The screen containing the frame's center, or main screen if not found
    private static func screen(containing frame: CGRect) -> NSScreen {
        let centerPoint = CGPoint(
            x: frame.origin.x + frame.size.width / 2,
            y: frame.origin.y + frame.size.height / 2
        )
        return screen(containing: centerPoint)
    }

    /// Convert an Accessibility frame to AppKit/CoreGraphics coordinates
    /// - Parameter axFrame: Frame from AXUIElement (top-left origin)
    /// - Returns: Frame in AppKit coordinates (bottom-left origin)
    static func toAppKit(_ axFrame: CGRect) -> CGRect {
        // Find the screen containing this frame (important for multi-monitor)
        let targetScreen = screen(containing: axFrame)
        let screenFrame = targetScreen.frame

        // Convert: AppKit_y = screenTop + screenHeight - AX_y - height
        let appKitY = screenFrame.origin.y + screenFrame.height - axFrame.origin.y - axFrame.size.height

        return CGRect(
            x: axFrame.origin.x,
            y: appKitY,
            width: axFrame.size.width,
            height: axFrame.size.height
        )
    }

    /// Convert an Accessibility point to CGEvent coordinates
    /// - Parameter axPoint: Point from AXUIElement
    /// - Returns: Point for CGEvent.mouseCursorPosition
    static func toAppKit(_ axPoint: CGPoint) -> CGPoint {
        // CGEvent.mouseCursorPosition appears to use the same coordinate system as Accessibility
        // (both use top-left origin), so no Y conversion is needed
        print("📐 Point conversion: AX(\(axPoint.x), \(axPoint.y)) -> CG(\(axPoint.x), \(axPoint.y)) [no Y flip]")
        return axPoint
    }

    /// Get the center point of a frame in Accessibility coordinates
    /// - Parameter axFrame: Frame from AXUIElement (top-left origin)
    /// - Returns: Center point in Accessibility coordinates
    static func centerPoint(of axFrame: CGRect) -> CGPoint {
        return CGPoint(
            x: axFrame.origin.x + axFrame.size.width / 2,
            y: axFrame.origin.y + axFrame.size.height / 2
        )
    }
}
