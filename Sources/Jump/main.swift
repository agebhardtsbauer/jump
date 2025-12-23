import Cocoa

/// Jump - Keyboard-based UI navigation for macOS
/// Activate with: cmd + ctrl + shift + opt + space

// Create application instance
let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Run as background accessory (no dock icon)

// Initialize coordinator
let coordinator = AppCoordinator()

// Print welcome message
print("""
╔═══════════════════════════════════════════════════════╗
║                   Jump v1.0                           ║
║     Keyboard-based UI Navigation for macOS            ║
╚═══════════════════════════════════════════════════════╝

🎯 Hotkey: cmd + ctrl + shift + opt + space

Usage:
1. Press the hotkey to activate Jump
2. Type text to search for UI elements
3. Matching elements will be highlighted in green
4. Press Enter when one element matches (or type a number for multiple matches)
5. The mouse will move to the selected element

Press Ctrl+C to quit.
""")

// Check accessibility permissions on startup
if !AccessibilityScanner.checkAccessibilityPermissions() {
    print("⚠  WARNING: Accessibility permissions not granted!")
    print("   Grant permissions in: System Preferences > Privacy & Security > Accessibility")
    print("")

    // Request permissions
    AccessibilityScanner.requestAccessibilityPermissions()
}

// Run the application
app.run()
