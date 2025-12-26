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
    let roleDescription: String?
    let identifier: String?
    let subrole: String?
    let isEnabled: Bool?
    let isFocused: Bool?
    let childrenCount: Int?
    // Parent element attributes
    let parentRole: String?
    let parentRoleDescription: String?
    let parentLabel: String?
    let parentIdentifier: String?
}

/// Scans applications using Accessibility APIs to find UI elements
class AccessibilityScanner {
    private let maxDepth = 15 // Prevent infinite recursion

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
    /// - Returns: Array of accessible elements with their properties (filtered if app has specific filters)
    func scanApplication(_ app: NSRunningApplication) -> [AccessibleElement] {
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var elements: [AccessibleElement] = []
        traverseElement(appElement, depth: 0, parent: nil, result: &elements)

        // Apply app-specific filter rules if they exist
        if let bundleId = app.bundleIdentifier,
           let config = AppFilters.config(for: bundleId)
        {
            var result = elements
            print("📋 Filtering \(bundleId): \(result.count) elements")

            // Apply each filter rule in sequence
            for rule in config.rules {
                let before = result.count
                result = rule.apply(to: result)
                print("   → \(rule.description): \(before) -> \(result.count)")
            }

            print("   ✓ Final: \(result.count) elements")
            return result
        }

        return elements
    }

    /// Recursively traverse the accessibility hierarchy
    private func traverseElement(
        _ element: AXUIElement,
        depth: Int,
        parent: ParentInfo?,
        result: inout [AccessibleElement]
    ) {
        // Stop if we've gone too deep
        guard depth < maxDepth else { return }

        // Extract element properties
        if let accessibleElement = extractElementInfo(element, parent: parent) {
            // Only include elements with meaningful text and valid frames
            let hasText = accessibleElement.label != nil ||
                accessibleElement.title != nil ||
                accessibleElement.value != nil
            let hasValidFrame = accessibleElement.frame.width > 0 &&
                accessibleElement.frame.height > 0

            if hasText, hasValidFrame {
                result.append(accessibleElement)
            }
        }

        // Create parent info for children
        let currentParentInfo = ParentInfo(
            role: getAttribute(element, attribute: kAXRoleAttribute),
            roleDescription: getAttribute(element, attribute: kAXRoleDescriptionAttribute),
            label: getAttribute(element, attribute: kAXTitleAttribute),
            identifier: getAttribute(element, attribute: kAXIdentifierAttribute)
        )

        // Get children and recurse
        if let children = getChildren(of: element) {
            for child in children {
                traverseElement(child, depth: depth + 1, parent: currentParentInfo, result: &result)
            }
        }
    }

    /// Parent element information passed during traversal
    private struct ParentInfo {
        let role: String?
        let roleDescription: String?
        let label: String?
        let identifier: String?
    }

    /// Extract information from an AXUIElement
    private func extractElementInfo(_ element: AXUIElement, parent: ParentInfo?) -> AccessibleElement? {
        let label = getAttribute(element, attribute: kAXTitleAttribute) ??
            getAttribute(element, attribute: kAXDescriptionAttribute)
        let title = getAttribute(element, attribute: kAXTitleAttribute)
        let value = getValueAttribute(element)
        let description = getAttribute(element, attribute: kAXDescriptionAttribute)
        let role = getAttribute(element, attribute: kAXRoleAttribute)
        let roleDescription = getAttribute(element, attribute: kAXRoleDescriptionAttribute)
        let identifier = getAttribute(element, attribute: kAXIdentifierAttribute)
        let subrole = getAttribute(element, attribute: kAXSubroleAttribute)
        let isEnabled = getBoolAttribute(element, attribute: kAXEnabledAttribute)
        let isFocused = getBoolAttribute(element, attribute: kAXFocusedAttribute)
        let childrenCount = getChildren(of: element)?.count

        guard let frame = getFrame(of: element) else {
            return nil
        }

        return AccessibleElement(
            label: label,
            title: title,
            value: value,
            description: description,
            frame: frame,
            role: role,
            roleDescription: roleDescription,
            identifier: identifier,
            subrole: subrole,
            isEnabled: isEnabled,
            isFocused: isFocused,
            childrenCount: childrenCount,
            parentRole: parent?.role,
            parentRoleDescription: parent?.roleDescription,
            parentLabel: parent?.label,
            parentIdentifier: parent?.identifier
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

    /// Get boolean attribute from element
    private func getBoolAttribute(_ element: AXUIElement, attribute: String) -> Bool? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        if result == .success, let boolValue = value as? Bool {
            return boolValue
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
              let size = sizeValue
        else {
            return nil
        }

        var point = CGPoint.zero
        var cgSize = CGSize.zero

        if AXValueGetValue(position as! AXValue, .cgPoint, &point),
           AXValueGetValue(size as! AXValue, .cgSize, &cgSize)
        {
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
