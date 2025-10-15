import SwiftUI

@main
struct MBDumpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var store = DataStore()
    var statusBarView: StatusBarView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // Configure the button with drag & drop support
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "MBDump")
            button.action = #selector(togglePopover)
            button.target = self

            // Register the button itself for drag types
            button.registerForDraggedTypes([
                .fileURL,
                .URL,
                .string,
                NSPasteboard.PasteboardType(rawValue: "public.url"),
                NSPasteboard.PasteboardType(rawValue: "public.url-name"),
                NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")
            ])

            // Create and add our overlay view that intercepts drags
            statusBarView = StatusBarView(store: store)
            statusBarView.frame = button.bounds
            statusBarView.autoresizingMask = [.width, .height]
            statusBarView.wantsLayer = true
            statusBarView.layer?.backgroundColor = NSColor.clear.cgColor
            button.addSubview(statusBarView, positioned: .above, relativeTo: nil)
        }

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 600, height: 400)
        popover.behavior = .transient

        let contentView = ContentView(store: store)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

// Custom view that accepts drag & drop
class StatusBarView: NSView {
    var store: DataStore
    var onTap: (() -> Void)?

    init(store: DataStore) {
        self.store = store
        super.init(frame: .zero)

        // Register for all common drag types including browser URLs
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            NSPasteboard.PasteboardType(rawValue: "public.url"),
            NSPasteboard.PasteboardType(rawValue: "public.url-name"),
            NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text"),
            NSPasteboard.PasteboardType(rawValue: "org.chromium.web-custom-data")
        ])
    }

    // Allow hit testing - this is key for receiving drag events
    override func hitTest(_ point: NSPoint) -> NSView? {
        return self.bounds.contains(point) ? self : nil
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        // Visual feedback could go here
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // Try to get URL from pasteboard (this works for file URLs and some web URLs)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            let content = url.absoluteString
            let type: ItemType = url.isFileURL ? .file : .link
            addItemToInbox(content: content, type: type)
            return true
        }

        // Try public.url type (common for browser drags)
        if let urlData = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: "public.url")),
           let urlString = String(data: urlData, encoding: .utf8) {
            addItemToInbox(content: urlString, type: .link)
            return true
        }

        // Try to get string (fallback for text and some URLs)
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            let type: ItemType
            if trimmed.starts(with: "http://") || trimmed.starts(with: "https://") {
                type = .link
            } else if trimmed.starts(with: "/") || trimmed.starts(with: "~") {
                type = .file
            } else {
                type = .text
            }
            addItemToInbox(content: trimmed, type: type)
            return true
        }

        return false
    }

    private func addItemToInbox(content: String, type: ItemType) {
        let item = Item(content: content, type: type)

        // Add to first canvas (Inbox)
        if let inboxId = store.canvases.first?.id {
            store.addItem(item, to: inboxId)
        }

        // Visual feedback
        NSSound.beep()
    }
}

