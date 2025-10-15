import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var store = DataStore()
    var statusBarView: StatusBarView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Set up button with custom icon
        if let image = NSImage(named: "MenuBarIcon") {
            image.isTemplate = true  // Makes it adapt to light/dark mode
            statusItem.button?.image = image
        }
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
        popover.behavior = .semitransient  // Closes when clicking outside

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
