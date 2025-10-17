import SwiftUI
import SwiftSoup

struct ContentView: View {
    @ObservedObject var store: DataStore
    @State private var newItemText = ""
    @State private var showingNewCanvasAlert = false
    @State private var newCanvasName = ""
    @State private var canvasToRename: Canvas?
    @State private var renameText = ""

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $store.selectedCanvasId) {
                ForEach(store.canvases) { canvas in
                    Text(canvas.name)
                        .tag(canvas.id)
                        .onDrop(of: [.text], delegate: CanvasDropDelegate(canvas: canvas, store: store))
                        .contextMenu {
                            Button("Rename") {
                                canvasToRename = canvas
                                renameText = canvas.name
                            }
                            if canvas.name != "Inbox" {
                                Button("Delete", role: .destructive) {
                                    store.deleteCanvas(canvas)
                                }
                            }
                        }
                }
            }
            .navigationTitle("Canvases")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingNewCanvasAlert = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button(action: { showingNewCanvasAlert = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Canvas")
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(8)
                    Spacer()
                }
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .alert("New Canvas", isPresented: $showingNewCanvasAlert) {
                TextField("Canvas Name", text: $newCanvasName)
                Button("Cancel", role: .cancel) {
                    newCanvasName = ""
                }
                Button("Create") {
                    if !newCanvasName.isEmpty {
                        store.addCanvas(name: newCanvasName)
                        newCanvasName = ""
                    }
                }
            }
            .alert("Rename Canvas", isPresented: Binding(
                get: { canvasToRename != nil },
                set: { if !$0 { canvasToRename = nil } }
            )) {
                TextField("Canvas Name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    canvasToRename = nil
                    renameText = ""
                }
                Button("Rename") {
                    if let canvas = canvasToRename, !renameText.isEmpty {
                        store.renameCanvas(canvas, to: renameText)
                    }
                    canvasToRename = nil
                    renameText = ""
                }
            }
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                if let canvas = store.selectedCanvas {
                    // Input area
                    VStack {
                        HStack {
                            Button(action: {
                                NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                            }) {
                                Image(systemName: "sidebar.left")
                            }
                            .buttonStyle(.plain)
                            .help("Toggle Sidebar")

                            TextField("Type or paste a link, note, or file path...", text: $newItemText)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    addNewItem()
                                }

                            Button(action: addNewItem) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .disabled(newItemText.isEmpty)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))

                        Divider()
                    }

                    // Items list
                    if canvas.items.isEmpty {
                        VStack {
                            Spacer()
                            Text("No items yet")
                                .foregroundColor(.secondary)
                            Text("Add something to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(canvas.items) { item in
                                ItemRow(item: item, canvas: canvas, store: store)
                                    .onDrag {
                                        // Store item ID as drag data
                                        let itemData = "\(item.id.uuidString)|\(canvas.id.uuidString)"
                                        return NSItemProvider(object: itemData as NSString)
                                    }
                                    .contextMenu {
                                        Button("Copy") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(item.content, forType: .string)
                                        }

                                        if item.type == .link {
                                            Button("Open") {
                                                if let url = URL(string: item.content) {
                                                    NSWorkspace.shared.open(url)
                                                }
                                            }
                                        }

                                        Menu("Move to...") {
                                            ForEach(store.canvases.filter { $0.id != canvas.id }) { targetCanvas in
                                                Button(targetCanvas.name) {
                                                    store.moveItem(item, from: canvas, to: targetCanvas)
                                                }
                                            }
                                        }

                                        Divider()

                                        Button("Delete", role: .destructive) {
                                            store.deleteItem(item, from: canvas)
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    Text("Select a canvas")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(store.selectedCanvas?.name ?? "")
        }
    }

    private func addNewItem() {
        guard !newItemText.isEmpty else { return }

        let type: ItemType
        if isURL(newItemText) {
            type = .link
        } else if newItemText.starts(with: "/") || newItemText.starts(with: "~") {
            type = .file
        } else {
            type = .text
        }

        let item = Item(content: newItemText, type: type)
        store.addItem(item, to: store.selectedCanvasId)
        newItemText = ""
        
        // Fetch title for links asynchronously
        if type == .link {
            fetchWebsiteTitle(for: item)
        }
    }
    
    private func isURL(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it already has a protocol
        if trimmedText.starts(with: "http://") || trimmedText.starts(with: "https://") || 
           trimmedText.starts(with: "ftp://") || trimmedText.starts(with: "file://") {
            return URL(string: trimmedText) != nil
        }
        
        // Check for www. prefix
        if trimmedText.starts(with: "www.") {
            let withoutWww = String(trimmedText.dropFirst(4))
            if let url = URL(string: "https://\(trimmedText)") {
                return url.host != nil
            }
        }
        
        // Check if it looks like a domain name (contains at least one dot and valid TLD)
        let domainPattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}(/.*)?$"#
        
        if let regex = try? NSRegularExpression(pattern: domainPattern) {
            let range = NSRange(location: 0, length: trimmedText.utf16.count)
            if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
                // Try to create a URL with https:// prefix
                if let url = URL(string: "https://\(trimmedText)") {
                    return url.host != nil
                }
            }
        }
        
        // Check for common TLD patterns
        let tldPattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.(com|org|net|edu|gov|mil|int|co|uk|de|fr|jp|au|ca|us|io|ai|app|dev|tech|online|site|website|blog|news|info|biz|name|mobi|tv|cc|me|ly|be|at|ch|dk|es|fi|it|nl|no|se|pl|br|mx|in|cn|ru|kr|nz|za|eg|ng|ke|ma|tn|dz|sd|so|et|ug|tz|zm|bw|sz|ls|mg|mu|sc|re|yt|km|dj|er|ss|cf|td|ne|ml|bf|ci|gh|sn|gm|gn|gw|lr|sl|tg|bj|cv|st|gq|ga|cg|cd|ao|mz|mw|zw)(/.*)?$"#
        
        if let regex = try? NSRegularExpression(pattern: tldPattern) {
            let range = NSRange(location: 0, length: trimmedText.utf16.count)
            if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func fetchWebsiteTitle(for item: Item) {
        // Ensure we have a valid URL
        let urlString = item.content
        let finalURL: String
        
        if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
            finalURL = urlString
        } else if urlString.starts(with: "www.") {
            finalURL = "https://\(urlString)"
        } else {
            finalURL = "https://\(urlString)"
        }
        
        guard let url = URL(string: finalURL) else { return }
        
        // Create a URL session configuration with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        let session = URLSession(configuration: config)
        
        // Create a URL session task to fetch the page
        let task = session.dataTask(with: url) { data, response, error in
            // Handle errors gracefully
            if let error = error {
                print("Failed to fetch title for \(urlString): \(error.localizedDescription)")
                return
            }
            
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                print("Failed to decode HTML for \(urlString)")
                return
            }
            
            // Extract title using SwiftSoup
            let title = self.extractTitleWithSwiftSoup(from: html)
            
            // Update the item on the main thread
            DispatchQueue.main.async {
                self.store.updateItemTitle(itemId: item.id, title: title)
            }
        }
        
        task.resume()
    }
    
    private func extractTitleWithSwiftSoup(from html: String) -> String? {
        do {
            let doc = try SwiftSoup.parse(html)
            let title = try doc.title()
            
            // Clean up the title
            let cleanedTitle = title
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
            
            // Clean up multiple spaces
            let finalTitle = cleanedTitle.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            return finalTitle.isEmpty ? nil : finalTitle
        } catch {
            print("Failed to parse HTML with SwiftSoup: \(error)")
            return nil
        }
    }
}
