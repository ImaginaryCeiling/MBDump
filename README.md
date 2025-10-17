# MBDump - Menu Bar Dump 💩

A lightweight macOS menu bar app for quickly capturing and organizing links, notes, and files.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)

## Features

- **Quick Capture**: Drag & drop files directly onto the menu bar icon
- **Multiple Canvases**: Organize items into separate canvases (think of them as collections)
- **Smart Detection**: Automatically detects URLs, file paths, and plain text
- **Persistent Storage**: Everything saves automatically
- **Simple UI**: Clean, native macOS interface

## Installation

### Download

1. Go to [Releases](../../releases)
2. Download the latest `MBDump.zip`
3. Unzip and drag `MBDump.app` to your Applications folder
4. Right-click → Open (first time only, to bypass security warning)

### Build from Source

Requires Xcode 14+ and macOS 13+

```bash
git clone https://github.com/YOUR_USERNAME/mbdump.git
cd mbdump
open MBDump.xcodeproj
```

Then in Xcode:
1. Select your development team in Signing & Capabilities
2. Build and run (⌘R)

## Usage

### Quick Start

1. **Launch** - The tray icon appears in your menu bar
2. **Add items**:
   - Drag files onto the menu bar icon → goes to Inbox
   - Click icon → paste/type links or notes
3. **Organize**:
   - Create canvases with the "+ New Canvas" button
   - Drag items between canvases
   - Right-click items for more options

### Creating Canvases

- Click **"+ New Canvas"** at the bottom of the sidebar
- Name your canvas (e.g., "Startup Ideas", "Reading List", "Movies")
- Each canvas keeps its own items

### Moving Items

**Drag & Drop:**
- Click and hold an item
- Drag it to a canvas name in the sidebar

**Context Menu:**
- Right-click item → "Move to..." → Select canvas

### Item Types

The app automatically detects:
- 🔗 **Links** - URLs starting with http:// or https://
- 📄 **Files** - File paths starting with / or ~
- 📝 **Text** - Everything else

## Data Storage

All data is saved to: `~/Documents/mbdump_data.json`

## Known Issues

- Drag & drop from Arc browser doesn't work (Arc uses proprietary drag formats)
  - **Workaround**: Copy the URL (⌘C) and paste it in the app
- Some system warnings in console (harmless, can be ignored)

## Roadmap

- [ ] Search functionality
- [ ] Tags
- [ ] Keyboard shortcuts
- [ ] Export to markdown
- [ ] iCloud sync

## Contributing

Pull requests welcome! For major changes, please open an issue first.

## License

MIT

## Credits

Built with Swift and SwiftUI
