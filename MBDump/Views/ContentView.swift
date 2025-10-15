import SwiftUI

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
        if newItemText.starts(with: "http://") || newItemText.starts(with: "https://") {
            type = .link
        } else if newItemText.starts(with: "/") || newItemText.starts(with: "~") {
            type = .file
        } else {
            type = .text
        }

        let item = Item(content: newItemText, type: type)
        store.addItem(item, to: store.selectedCanvasId)
        newItemText = ""
    }
}
