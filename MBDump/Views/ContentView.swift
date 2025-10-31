import SwiftUI
import SwiftSoup

struct ContentView: View {
    @ObservedObject var store: DataStore
    @State private var newItemText = ""
    @State private var showingNewCanvasAlert = false
    @State private var newCanvasName = ""
    @State private var editingTypeTagsFor: Canvas? = nil

    // Computed binding that prevents folder selection
    private var canvasSelection: Binding<UUID?> {
        Binding(
            get: { store.selectedCanvasId },
            set: { newId in
                // Only allow selection if it's not a folder
                if let newId = newId,
                   let canvas = store.findCanvas(byId: newId, in: store.canvases),
                   !canvas.isFolder {
                    store.selectedCanvasId = newId
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                List(store.canvases, children: \.childrenForList, selection: canvasSelection) { canvas in
                    CanvasRow(canvas: canvas, store: store)
                        .tag(canvas.id)
                        .onDrop(of: [.text], delegate: CanvasDropDelegate(canvas: canvas, store: store))
                        .contextMenu {
                            Button("Edit Type & Tags...") {
                                editingTypeTagsFor = canvas
                            }

                            Divider()

                            if !canvas.isFolder {
                                // Check if canvas is inside a folder
                                if store.isCanvasInFolder(canvas) {
                                    Button("Move to Root") {
                                        store.moveCanvasToRoot(canvas)
                                    }
                                } else {
                                    Button("Add to New Folder") {
                                        createFolderWithCanvas(canvas)
                                    }
                                }

                                // Show existing folders to add this canvas to
                                let folders = store.getAllFolders().filter { $0.id != store.getParentFolder(of: canvas)?.id }
                                if !folders.isEmpty {
                                    Menu("Move to Folder") {
                                        ForEach(folders) { folder in
                                            Button(folder.name) {
                                                store.addCanvasToExistingFolder(canvas, folder: folder)
                                            }
                                        }
                                    }
                                }
                            }

                            if canvas.name != "Inbox" {
                                Button("Delete", role: .destructive) {
                                    store.deleteCanvas(canvas)
                                }
                            }
                        }
                }

                // Drop zone for moving canvases to root
                Spacer()
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    .onDrop(of: [.text], delegate: RootDropDelegate(store: store))

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
            .navigationTitle("Canvases")
            .sheet(item: $editingTypeTagsFor) { canvas in
                VStack {
                    HStack {
                        Text("Edit Type & Tags: \(canvas.name)")
                            .font(.headline)
                        Spacer()
                        Button("Done") {
                            editingTypeTagsFor = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()

                    CanvasTypeTagEditor(canvas: canvas, store: store)
                    Spacer()
                }
                .frame(width: 300, height: 280)
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
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                if let canvas = store.selectedCanvas {
                    // Canvas - show input and items
                    VStack(spacing: 0) {
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
                                    Text(canvas.name).bold()
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
                                                    ForEach(store.getAllCanvases().filter { $0.id != canvas.id }) { targetCanvas in
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
                                    .onMove { indices, newOffset in
                                        moveItems(at: indices, to: newOffset, in: canvas)
                                    }
                                }
                                .listStyle(.plain)
                            }
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
            fetchWebsiteTitle(for: item, store: store)
        }
    }

    private func moveItems(at indices: IndexSet, to newOffset: Int, in canvas: Canvas) {
        store.reorderItems(in: canvas, from: indices, to: newOffset)
    }

    private func moveCanvases(from indices: IndexSet, to newOffset: Int) {
        store.reorderCanvases(from: indices, to: newOffset)
    }

    private func createFolderWithCanvas(_ canvas: Canvas) {
        store.createNewFolder(with: canvas)
    }
    

}
