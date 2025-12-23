import ApplicationServices
import Cocoa

/// Represents an accessible UI element
struct AccessibleElement {
    let label: String?
    let title: String?
    let value: String?
    let description: String?
    let frame: CGRect
    let role: String?
}

/// Scans applications using Accessibility APIs to find UI elements
class AccessibilityScanner {
    private let maxDepth = 15  // Prevent infinite recursion

    /// Scan the frontmost application for accessible elements
    /// - Returns: Array of accessible elements with their properties
    func scanFrontmostApplication() -> [AccessibleElement] {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return []
        }
        return scanApplication(frontmostApp)
    }

    /// Scan a specific application for accessible elements
    /// - Parameter app: The running application to scan
    /// - Returns: Array of accessible elements with their properties
    func scanApplication(_ app: NSRunningApplication) -> [AccessibleElement] {
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var elements: [AccessibleElement] = []
        traverseElement(appElement, depth: 0, result: &elements)

        return elements
    }

    /// Recursively traverse the accessibility hierarchy
    private func traverseElement(
        _ element: AXUIElement,
        depth: Int,
        result: inout [AccessibleElement]
    ) {
        // Stop if we've gone too deep
        guard depth < maxDepth else { return }

        // Extract element properties
        if let accessibleElement = extractElementInfo(element) {
            // Only include elements with meaningful text and valid frames
            let hasText = accessibleElement.label != nil ||
                         accessibleElement.title != nil ||
                         accessibleElement.value != nil
            let hasValidFrame = accessibleElement.frame.width > 0 &&
                               accessibleElement.frame.height > 0

            if hasText && hasValidFrame {
                result.append(accessibleElement)
            }
        }

        // Get children and recurse
        if let children = getChildren(of: element) {
            for child in children {
                traverseElement(child, depth: depth + 1, result: &result)
            }
        }
    }

    /// Extract information from an AXUIElement
    private func extractElementInfo(_ element: AXUIElement) -> AccessibleElement? {
        let label = getAttribute(element, attribute: kAXTitleAttribute) ??
                   getAttribute(element, attribute: kAXDescriptionAttribute)
        let title = getAttribute(element, attribute: kAXTitleAttribute)
        let value = getValueAttribute(element)
        let description = getAttribute(element, attribute: kAXDescriptionAttribute)
        let role = getAttribute(element, attribute: kAXRoleAttribute)

        guard let frame = getFrame(of: element) else {
            return nil
        }

        return AccessibleElement(
            label: label,
            title: title,
            value: value,
            description: description,
            frame: frame,
            role: role
        )
    }

    /// Get string attribute from element
    private func getAttribute(_ element: AXUIElement, attribute: String) -> String? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        if result == .success, let stringValue = value as? String, !stringValue.isEmpty {
            return stringValue
        }
        return nil
    }

    /// Get value attribute (handles various types)
    private func getValueAttribute(_ element: AXUIElement) -> String? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)

        if result == .success {
            if let stringValue = value as? String, !stringValue.isEmpty {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue.stringValue
            }
        }
        return nil
    }

    /// Get the frame (position and size) of an element
    private func getFrame(of element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?

        let positionResult = AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        )
        let sizeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            &sizeValue
        )

        guard positionResult == .success,
              sizeResult == .success,
              let position = positionValue,
              let size = sizeValue else {
            return nil
        }

        var point = CGPoint.zero
        var cgSize = CGSize.zero

        if AXValueGetValue(position as! AXValue, .cgPoint, &point),
           AXValueGetValue(size as! AXValue, .cgSize, &cgSize) {
            return CGRect(origin: point, size: cgSize)
        }

        return nil
    }

    /// Get children of an element
    private func getChildren(of element: AXUIElement) -> [AXUIElement]? {
        var childrenValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenValue
        )

        if result == .success, let children = childrenValue as? [AXUIElement] {
            return children
        }
        return nil
    }

    /// Check if accessibility permissions are granted
    static func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Request accessibility permissions
    static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
