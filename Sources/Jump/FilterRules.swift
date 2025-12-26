import Foundation

/// Defines filter rules that can be applied to accessibility elements
enum FilterRule {
    case requireRole(String)
    case requireRoleDescription(Set<String>)
    case requireSubrole(String)
    case requireIdentifier(String)
    case requireEnabled(Bool)
    case requireFocused(Bool)
    case minChildrenCount(Int)
    case maxChildrenCount(Int)
    case minWidth(CGFloat)
    case maxWidth(CGFloat)
    case minHeight(CGFloat)
    case maxHeight(CGFloat)
    case minArea(CGFloat)
    case maxArea(CGFloat)
    case isSearchField  // Matches search text fields
    case takeFirstWhereParent(attribute: String, contains: String, limit: Int)  // Filter by parent attribute then limit
    case takeFirst(Int)  // Simple limit to first N elements
    case sortByVerticalPosition  // Sort top-to-bottom by Y coordinate
    case sortByHorizontalPosition  // Sort left-to-right by X coordinate
    case deduplicateKeepSmallest
    case deduplicateKeepLargest

    /// Apply this filter rule to a list of elements
    func apply(to elements: [AccessibleElement]) -> [AccessibleElement] {
        switch self {
        case .requireRole(let role):
            return elements.filter { $0.role == role }

        case .requireRoleDescription(let descriptions):
            return elements.filter { element in
                guard let roleDesc = element.roleDescription else { return false }
                return descriptions.contains(roleDesc)
            }

        case .requireSubrole(let subrole):
            return elements.filter { $0.subrole == subrole }

        case .requireIdentifier(let identifier):
            return elements.filter { $0.identifier == identifier }

        case .requireEnabled(let enabled):
            return elements.filter { $0.isEnabled == enabled }

        case .requireFocused(let focused):
            return elements.filter { $0.isFocused == focused }

        case .minChildrenCount(let count):
            return elements.filter { ($0.childrenCount ?? 0) >= count }

        case .maxChildrenCount(let count):
            return elements.filter { ($0.childrenCount ?? 0) <= count }

        case .minWidth(let width):
            return elements.filter { $0.frame.width >= width }

        case .maxWidth(let width):
            return elements.filter { $0.frame.width <= width }

        case .minHeight(let height):
            return elements.filter { $0.frame.height >= height }

        case .maxHeight(let height):
            return elements.filter { $0.frame.height <= height }

        case .minArea(let area):
            return elements.filter { $0.frame.width * $0.frame.height >= area }

        case .maxArea(let area):
            return elements.filter { $0.frame.width * $0.frame.height <= area }

        case .isSearchField:
            return elements.filter { element in
                // Match text fields with search-related roles or identifiers
                if element.subrole == "AXSearchField" {
                    return true
                }
                if element.role == "AXTextField" {
                    let identifier = element.identifier?.lowercased() ?? ""
                    let label = element.label?.lowercased() ?? ""
                    return identifier.contains("search") || label.contains("search")
                }
                return false
            }

        case .takeFirstWhereParent(let attribute, let value, let limit):
            // Filter elements where parent's specified attribute contains the value
            let filtered = elements.filter { element in
                let attributeValue: String?
                switch attribute.lowercased() {
                case "role":
                    attributeValue = element.parentRole
                case "roledescription", "role_description":
                    attributeValue = element.parentRoleDescription
                case "label":
                    attributeValue = element.parentLabel
                case "identifier":
                    attributeValue = element.parentIdentifier
                default:
                    attributeValue = nil
                }

                guard let attrValue = attributeValue else { return false }
                return attrValue.contains(value)
            }
            return Array(filtered.prefix(limit))

        case .takeFirst(let count):
            return Array(elements.prefix(count))

        case .sortByVerticalPosition:
            // Sort by Y coordinate (top to bottom)
            return elements.sorted { $0.frame.minY < $1.frame.minY }

        case .sortByHorizontalPosition:
            // Sort by X coordinate (left to right)
            return elements.sorted { $0.frame.minX < $1.frame.minX }

        case .deduplicateKeepSmallest:
            return deduplicate(elements, keepSmallest: true)

        case .deduplicateKeepLargest:
            return deduplicate(elements, keepSmallest: false)
        }
    }

    /// Deduplicate elements by frame size when text content matches
    private func deduplicate(_ elements: [AccessibleElement], keepSmallest: Bool) -> [AccessibleElement] {
        var textToElements: [String: [AccessibleElement]] = [:]

        // Group elements by their text content
        for element in elements {
            let text = element.label ?? element.description ?? element.title ?? ""
            if !text.isEmpty {
                textToElements[text, default: []].append(element)
            }
        }

        var result: [AccessibleElement] = []

        // For each text group, keep element with smallest or largest frame area
        for (_, group) in textToElements {
            if keepSmallest {
                if let smallest = group.min(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) {
                    result.append(smallest)
                }
            } else {
                if let largest = group.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) {
                    result.append(largest)
                }
            }
        }

        return result
    }

    /// Get a human-readable description of this filter rule
    var description: String {
        switch self {
        case .requireRole(let role):
            return "requireRole(\(role))"
        case .requireRoleDescription(let descs):
            return "requireRoleDescription(\(descs.joined(separator: ", ")))"
        case .requireSubrole(let subrole):
            return "requireSubrole(\(subrole))"
        case .requireIdentifier(let identifier):
            return "requireIdentifier(\(identifier))"
        case .requireEnabled(let enabled):
            return "requireEnabled(\(enabled))"
        case .requireFocused(let focused):
            return "requireFocused(\(focused))"
        case .minChildrenCount(let count):
            return "minChildrenCount(\(count))"
        case .maxChildrenCount(let count):
            return "maxChildrenCount(\(count))"
        case .minWidth(let width):
            return "minWidth(\(width))"
        case .maxWidth(let width):
            return "maxWidth(\(width))"
        case .minHeight(let height):
            return "minHeight(\(height))"
        case .maxHeight(let height):
            return "maxHeight(\(height))"
        case .minArea(let area):
            return "minArea(\(area))"
        case .maxArea(let area):
            return "maxArea(\(area))"
        case .isSearchField:
            return "isSearchField"
        case .takeFirstWhereParent(let attribute, let value, let limit):
            return "takeFirstWhereParent(attribute: \(attribute), contains: \(value), limit: \(limit))"
        case .takeFirst(let count):
            return "takeFirst(\(count))"
        case .sortByVerticalPosition:
            return "sortByVerticalPosition"
        case .sortByHorizontalPosition:
            return "sortByHorizontalPosition"
        case .deduplicateKeepSmallest:
            return "deduplicateKeepSmallest"
        case .deduplicateKeepLargest:
            return "deduplicateKeepLargest"
        }
    }
}
