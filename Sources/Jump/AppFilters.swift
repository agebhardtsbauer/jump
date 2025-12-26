import Foundation

/// Configuration for default highlights shown when text box is empty
struct DefaultHighlightConfig {
    let rules: [FilterRule]
    let limit: Int? // Max number of elements to highlight
}

/// Configuration defining which filter rules apply to a specific app
struct AppFilterConfig {
    let bundleIdentifier: String
    let rules: [FilterRule] // Applied when filtering search results
    let defaultHighlights: DefaultHighlightConfig? // Applied when text is empty
}

/// Registry of app-specific filter configurations
enum AppFilters {
    /// Messages app - deduplicate to keep only smaller text bubbles (not larger parent containers)
    /// Default: Show first 9 conversations from the conversation list
    static let messages = AppFilterConfig(
        bundleIdentifier: "com.apple.MobileSMS",
        rules: [
            .deduplicateKeepSmallest,
        ],
        defaultHighlights: DefaultHighlightConfig(
            rules: [
                .takeFirstWhereParent(
                    attribute: "identifier",
                    contains: "ConversationList",
                    limit: 100  // Get all conversations first
                ),
                .sortByVerticalPosition,  // Sort top to bottom
                .takeFirst(9)  // Take first 9 visually
            ],
            limit: 9
        )
    )

    /// Global default configuration for apps without specific configs
    /// Shows search fields by default
    static let globalDefault = AppFilterConfig(
        bundleIdentifier: "*",
        rules: [],
        defaultHighlights: DefaultHighlightConfig(
            rules: [
                .isSearchField,
            ],
            limit: nil
        )
    )

    // Add more app configurations here as needed:
    //
    // Example: Safari - only show enabled links and buttons
    // static let safari = AppFilterConfig(
    //     bundleIdentifier: "com.apple.Safari",
    //     rules: [
    //         .requireRoleDescription(Set(["link", "button"])),
    //         .requireEnabled(true)
    //     ]
    // )
    //
    // Example: Filter by size - only show medium-sized elements
    // static let someApp = AppFilterConfig(
    //     bundleIdentifier: "com.example.app",
    //     rules: [
    //         .minWidth(50),
    //         .maxWidth(500),
    //         .minHeight(20),
    //         .maxHeight(200)
    //     ]
    // )
    //
    // Example: Filter by area and deduplicate
    // static let anotherApp = AppFilterConfig(
    //     bundleIdentifier: "com.example.another",
    //     rules: [
    //         .minArea(1000),      // At least 1000 sq pixels
    //         .maxArea(100000),    // At most 100000 sq pixels
    //         .deduplicateKeepLargest
    //     ]
    // )
    //
    // Example: Filter by children count - only show containers
    // static let containerApp = AppFilterConfig(
    //     bundleIdentifier: "com.example.container",
    //     rules: [
    //         .minChildrenCount(3),  // Must have at least 3 children
    //         .requireEnabled(true)
    //     ]
    // )
    //
    // Example: Filter by identifier and subrole
    // static let specificApp = AppFilterConfig(
    //     bundleIdentifier: "com.example.specific",
    //     rules: [
    //         .requireSubrole("AXSecureTextField"),
    //         .requireIdentifier("loginButton")
    //     ]
    // )

    /// Get filter configuration for a specific bundle identifier
    /// Returns app-specific config if available, otherwise returns global default
    static func config(for bundleIdentifier: String) -> AppFilterConfig? {
        switch bundleIdentifier {
        case "com.apple.MobileSMS":
            return messages
        // Add more cases here
        default:
            return globalDefault
        }
    }
}
