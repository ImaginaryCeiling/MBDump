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

        // Add right-click menu
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

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
        guard let button = statusItem.button else { return }

        // Check if it's a right-click
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
        } else {
            // Left-click - toggle popover
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open MBDump", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
