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
        // Create the status item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Set up button
        statusItem.button?.image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "MBDump")
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self

        // Add drag & drop overlay view
        if let button = statusItem.button {
            statusBarView = StatusBarView(store: store)
            statusBarView.frame = button.bounds
            statusBarView.autoresizingMask = [.width, .height]
            button.addSubview(statusBarView)
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

        // Register for drag types
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        NSLog("Drag entered!")
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        NSLog("Drag exited!")
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        NSLog("Prepare for drag")
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        NSLog("Perform drag operation")

        let pasteboard = sender.draggingPasteboard

        // Try to get URL first
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            let content = url.absoluteString
            let type: ItemType = url.isFileURL ? .file : .link
            addItemToInbox(content: content, type: type)
            return true
        }

        // Try to get string
        if let string = pasteboard.string(forType: .string) {
            let type: ItemType
            if string.starts(with: "http://") || string.starts(with: "https://") {
                type = .link
            } else if string.starts(with: "/") || string.starts(with: "~") {
                type = .file
            } else {
                type = .text
            }
            addItemToInbox(content: string, type: type)
            return true
        }

        return false
    }

    private func addItemToInbox(content: String, type: ItemType) {
        NSLog("Adding to inbox: \(content)")
        let item = Item(content: content, type: type)

        // Add to first folder (Inbox)
        if let inboxId = store.folders.first?.id {
            store.addItem(item, to: inboxId)
        }

        // Visual feedback
        NSSound.beep()
    }
}

