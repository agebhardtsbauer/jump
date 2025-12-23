# Jump

**Keyboard-based UI navigation for macOS**

Jump is a macOS application that allows you to navigate to any UI element using only your keyboard. Similar to ShortCat and Homerow, Jump eliminates the need for mouse movement by letting you search and select UI elements through keyboard shortcuts.

## Features

- **Global Hotkey Activation**: Press `cmd + ctrl + shift + opt + space` (hyper + space) from anywhere
- **Substring Matching**: Type text to find UI elements containing that text (case-insensitive)
- **Visual Feedback**: Matching elements are highlighted with transparent green overlays and numbered labels
- **Numeric Selection**: Select numbered elements with `hyper + number` (e.g., `cmd + ctrl + shift + opt + 1`)
- **Automatic Mouse Movement**: Mouse cursor moves to the center of the selected element
- **Focus Restoration**: Automatically returns keyboard focus to your original application

## Requirements

- macOS 12.0 or later
- Swift 5.9 or later
- Accessibility permissions

## Installation

### Build from Source

```bash
# Clone the repository
git clone <repository-url>
cd jump

# Build the application
swift build -c release

# Run the application
.build/release/Jump
```

### Create Alias (Optional)

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias jump='/path/to/jump/.build/release/Jump'
```

## Usage

### 1. Grant Accessibility Permissions

On first run, Jump will request Accessibility permissions. You need to:

1. Open **System Preferences** (or **System Settings** on macOS 13+)
2. Go to **Privacy & Security** > **Accessibility**
3. Add and enable Jump in the list

### 2. Start Jump

```bash
.build/release/Jump
```

The application runs in the background (no dock icon). Press `Ctrl+C` in the terminal to quit.

### 3. Use Jump

1. **Activate**: Press `cmd + ctrl + shift + opt + space` (hyper key + space)
2. **Search**: Type text to search for UI elements (e.g., "close", "submit", "settings")
   - You can type numbers in your search (e.g., "tab2", "button1")
3. **Select**:
   - If **one element** matches: Press `Enter`
   - If **multiple elements** match: Press `hyper + number` (e.g., `cmd + ctrl + shift + opt + 1`) to select that numbered highlight
   - Or continue typing to narrow down the matches
4. **Cancel**: Press `Esc` to close the search without selecting
5. **Focus returns** to your original application automatically

### Example Workflow

```
1. Press cmd + ctrl + shift + opt + space
2. Type "close"
3. See green highlights appear over "Close" buttons with numbers [1], [2], [3]...
4. Select:
   - Press Enter (if only one match), OR
   - Press cmd + ctrl + shift + opt + 1 (to select element [1]), OR
   - Keep typing to narrow down matches
5. Mouse moves to the selected button
6. Focus returns to your original application
```

## How It Works

Jump uses macOS Accessibility APIs to:

1. **Scan** the frontmost application's UI hierarchy (before Jump activates)
2. **Extract** labels, titles, and descriptions from UI elements
3. **Match** your search text against element properties using substring matching
4. **Highlight** matching elements with transparent green overlays and numbered labels
5. **Move** the mouse cursor to the selected element's center
6. **Restore** keyboard focus to your original application

## Architecture

- **HotkeyManager**: Registers global hotkey using Carbon Event Manager
- **OverlayWindow**: Displays search text field overlay
- **AccessibilityScanner**: Scans UI elements using AXUIElement APIs
- **ElementMatcher**: Performs fuzzy text matching with Levenshtein distance
- **HighlightRenderer**: Draws green overlay windows with numeric labels
- **MouseController**: Moves mouse cursor using CoreGraphics
- **AppCoordinator**: Orchestrates all components

## Troubleshooting

### "Accessibility permissions not granted"

Enable Jump in **System Preferences** > **Privacy & Security** > **Accessibility**, then restart Jump.

### Hotkey not working

- Ensure no other application is using the same hotkey combination
- Try restarting Jump
- Check Console.app for error messages

### Elements not being detected

- Some applications don't expose all UI elements via Accessibility APIs
- Try different search terms (e.g., search for the label text, not the element type)
- Some apps actively block accessibility scanning

### Highlights appear in wrong position

- This may occur with apps that use custom coordinate systems
- Report the specific application for investigation

## Known Limitations

- Not all applications expose UI elements through Accessibility APIs
- Some apps (e.g., games, custom renderers) may not work
- Maximum 9 numbered selections supported (can continue typing to narrow down)

## Future Enhancements

- Configurable hotkey
- Click simulation after mouse movement
- Support for custom element filters
- Performance optimizations with caching
- History of recent selections

## License

See [LICENSE](LICENSE) file for details.

## Similar Projects

- [ShortCat](https://shortcat.app/)
- [Homerow](https://www.homerow.app/)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
