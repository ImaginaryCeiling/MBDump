import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var store = DataStore()
    var statusBarView: StatusBarView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Set up button with custom icon
        if let image = NSImage(named: "MenuBarIcon") {
            image.isTemplate = false  // Makes it adapt to light/dark mode
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
        popover.behavior = .transient  // Closes when clicking outside
        popover.animates = true  // Enable smooth animations
        popover.delegate = self  // Set delegate for handling events

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
                // Ensure the popover is properly positioned and shown
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Make sure the popover becomes the key window for proper focus handling
                DispatchQueue.main.async {
                    self.popover.contentViewController?.view.window?.makeKey()
                }
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
    
    // MARK: - NSPopoverDelegate
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        // Allow the popover to close when clicking outside
        return true
    }
    
    func popoverDidClose(_ notification: Notification) {
        // Optional: Handle any cleanup when popover closes
        // This is called when the popover is dismissed
    }
}
