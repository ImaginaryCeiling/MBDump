import Foundation

enum ItemType: Codable {
    case text
    case link
    case file
}

struct Item: Identifiable, Codable {
    var id = UUID()
    var content: String
    var type: ItemType
    var createdAt: Date = Date()

    var displayContent: String {
        if type == .link, let url = URL(string: content) {
            return url.host ?? content
        }
        return content
    }
}

struct Folder: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [Item] = []
}

class DataStore: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var selectedFolderId: UUID?

    private let saveURL: URL

    init() {
        // Set up save location
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveURL = documentsPath.appendingPathComponent("mbdump_data.json")

        load()

        // If no folders exist, create default Inbox
        if folders.isEmpty {
            let inbox = Folder(name: "Inbox")
            folders.append(inbox)
            selectedFolderId = inbox.id
            save()
        }
    }

    var selectedFolder: Folder? {
        folders.first { $0.id == selectedFolderId }
    }

    func addFolder(name: String) {
        let folder = Folder(name: name)
        folders.append(folder)
        save()
    }

    func deleteFolder(_ folder: Folder) {
        folders.removeAll { $0.id == folder.id }
        if selectedFolderId == folder.id {
            selectedFolderId = folders.first?.id
        }
        save()
    }

    func renameFolder(_ folder: Folder, to newName: String) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].name = newName
            save()
        }
    }

    func addItem(_ item: Item, to folderId: UUID? = nil) {
        let targetId = folderId ?? folders.first?.id
        if let index = folders.firstIndex(where: { $0.id == targetId }) {
            folders[index].items.insert(item, at: 0)
            save()
        }
    }

    func deleteItem(_ item: Item, from folder: Folder) {
        if let folderIndex = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[folderIndex].items.removeAll { $0.id == item.id }
            save()
        }
    }

    func moveItem(_ item: Item, from sourceFolder: Folder, to targetFolder: Folder) {
        if let sourceIndex = folders.firstIndex(where: { $0.id == sourceFolder.id }),
           let targetIndex = folders.firstIndex(where: { $0.id == targetFolder.id }) {
            folders[sourceIndex].items.removeAll { $0.id == item.id }
            folders[targetIndex].items.insert(item, at: 0)
            save()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: saveURL)
        } catch {
            print("Failed to save: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            folders = try JSONDecoder().decode([Folder].self, from: data)
            if let firstFolder = folders.first {
                selectedFolderId = firstFolder.id
            }
        } catch {
            print("Failed to load (might be first run): \(error)")
        }
    }
}
