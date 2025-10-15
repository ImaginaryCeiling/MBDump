import SwiftUI

struct ContentView: View {
    @ObservedObject var store: DataStore
    @State private var newItemText = ""
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $store.selectedFolderId) {
                ForEach(store.folders) { folder in
                    Text(folder.name)
                        .tag(folder.id)
                        .contextMenu {
                            Button("Rename") {
                                // TODO: Add rename functionality
                            }
                            if folder.name != "Inbox" {
                                Button("Delete", role: .destructive) {
                                    store.deleteFolder(folder)
                                }
                            }
                        }
                }
            }
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem {
                    Button(action: { showingNewFolderAlert = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newFolderName.isEmpty {
                        store.addFolder(name: newFolderName)
                        newFolderName = ""
                    }
                }
            }
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                if let folder = store.selectedFolder {
                    // Input area
                    VStack {
                        HStack {
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
                    if folder.items.isEmpty {
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
                            ForEach(folder.items) { item in
                                ItemRow(item: item)
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
                                            ForEach(store.folders.filter { $0.id != folder.id }) { targetFolder in
                                                Button(targetFolder.name) {
                                                    store.moveItem(item, from: folder, to: targetFolder)
                                                }
                                            }
                                        }

                                        Divider()

                                        Button("Delete", role: .destructive) {
                                            store.deleteItem(item, from: folder)
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    Text("Select a folder")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(store.selectedFolder?.name ?? "")
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
        store.addItem(item)
        newItemText = ""
    }
}

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayContent)
                    .lineLimit(1)

                if item.type == .link {
                    Text(item.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(item.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch item.type {
        case .link: return "link"
        case .text: return "text.quote"
        case .file: return "doc"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .link: return .blue
        case .text: return .primary
        case .file: return .orange
        }
    }
}
