# MBDump - Menu Bar Link Dumper

A macOS menu bar app for quickly capturing links, notes, and files to organize later.

## Features

- **Quick Capture**: Drag & drop links, files, or text directly onto the menu bar icon
- **Inbox System**: Items land in your Inbox for later organization
- **Custom Folders**: Create your own folders to organize items
- **Multiple Item Types**: Supports links, text notes, and file references
- **Persistent Storage**: All data is automatically saved to disk
- **Context Menu Actions**: Copy, open links, move items between folders, delete
  
## Usage

1. **Launch the app** - An inbox tray icon will appear in your menu bar
2. **Quick capture**:
   - Drag a URL from your browser onto the menu bar icon
   - Drag a file onto the icon
   - Or click the icon to open the interface and type/paste directly
3. **Organize**:
   - Click the menu bar icon to open the interface
   - Create folders using the + button in the sidebar
   - Move items from Inbox to folders via right-click → "Move to..."
4. **Access**:
   - Right-click items to copy or open links
   - Click links to see full URL
   - Items show how long ago they were added

## Data Storage

Data is saved to: `~/Documents/mbdump_data.json`

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later (for building)

## Architecture

- **MBDumpApp.swift**: Main app entry point, menu bar setup, drag & drop handling
- **Models.swift**: Data models (Item, Folder, DataStore) and persistence
- **ContentView.swift**: SwiftUI interface with sidebar and item list

## Tips

- The first folder is always your Inbox
- Drag & drop adds items directly to Inbox
- You can create as many folders as you need
- Items are timestamped automatically
- The app runs in the menu bar only (no dock icon)
