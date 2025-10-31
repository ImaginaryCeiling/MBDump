import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var canvases: [Canvas] = []
    @Published var selectedCanvasId: UUID?

    private let saveURL: URL

    init() {
        // Set up save location
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveURL = documentsPath.appendingPathComponent("mbdump_data.json")
        load()

        // If no canvases exist, create default Inbox
        if canvases.isEmpty {
            let inbox = Canvas(name: "Inbox")
            canvases.append(inbox)
            selectedCanvasId = inbox.id
            save()
        }
    }

    var selectedCanvas: Canvas? {
        guard let id = selectedCanvasId else { return nil }
        return findCanvas(byId: id, in: canvases)
    }

    func findCanvas(byId id: UUID, in canvases: [Canvas]) -> Canvas? {
        for canvas in canvases {
            if canvas.id == id {
                return canvas
            }
            if let found = findCanvas(byId: id, in: canvas.children) {
                return found
            }
        }
        return nil
    }

    // Get all canvases flattened (for "Move to..." menus)
    func getAllCanvases() -> [Canvas] {
        var result: [Canvas] = []
        func collectCanvases(_ canvases: [Canvas]) {
            for canvas in canvases {
                if !canvas.isFolder {
                    result.append(canvas)
                }
                collectCanvases(canvas.children)
            }
        }
        collectCanvases(canvases)
        return result
    }

    // Get all folders flattened
    func getAllFolders() -> [Canvas] {
        var result: [Canvas] = []
        func collectFolders(_ canvases: [Canvas]) {
            for canvas in canvases {
                if canvas.isFolder {
                    result.append(canvas)
                }
                collectFolders(canvas.children)
            }
        }
        collectFolders(canvases)
        return result
    }

    func addCanvas(name: String) {
        let canvas = Canvas(name: name)
        canvases.append(canvas)
        // Delay selection to avoid "Publishing changes from within view updates" warning
        DispatchQueue.main.async {
            self.selectedCanvasId = canvas.id
        }
        save()
    }

    func deleteCanvas(_ canvas: Canvas) {
        canvases.removeAll { $0.id == canvas.id }
        if selectedCanvasId == canvas.id {
            selectedCanvasId = canvases.first?.id
        }
        save()
    }

    func renameCanvas(_ canvas: Canvas, to newName: String) {
        updateCanvas(withId: canvas.id) { canvas in
            canvas.name = newName
        }
    }

    func updateCanvasType(_ canvas: Canvas, type: CanvasType?) {
        updateCanvas(withId: canvas.id) { canvas in
            canvas.type = type
        }
    }

    func addTag(to canvas: Canvas, tag: String) {
        updateCanvas(withId: canvas.id) { canvas in
            if !canvas.tags.contains(tag) {
                canvas.tags.append(tag)
            }
        }
    }

    func removeTag(from canvas: Canvas, tag: String) {
        updateCanvas(withId: canvas.id) { canvas in
            canvas.tags.removeAll { $0 == tag }
        }
    }

    func toggleItemCompletion(_ item: Item, in canvas: Canvas) {
        updateCanvas(withId: canvas.id) { canvas in
            if let itemIndex = canvas.items.firstIndex(where: { $0.id == item.id }) {
                canvas.items[itemIndex].isCompleted.toggle()

                // Sort items: incomplete first, completed at bottom
                if canvas.type == .todo {
                    canvas.items.sort { !$0.isCompleted && $1.isCompleted }
                }
            }
        }
    }

    func updateItemNotes(_ item: Item, in canvas: Canvas, notes: String?) {
        updateCanvas(withId: canvas.id) { canvas in
            if let itemIndex = canvas.items.firstIndex(where: { $0.id == item.id }) {
                canvas.items[itemIndex].notes = notes
            }
        }
    }

    // Helper to update a canvas anywhere in the tree
    private func updateCanvas(withId id: UUID, update: (inout Canvas) -> Void) {
        updateCanvasRecursive(id: id, canvases: &canvases, update: update)
    }

    private func updateCanvasRecursive(id: UUID, canvases: inout [Canvas], update: (inout Canvas) -> Void) {
        for i in canvases.indices {
            if canvases[i].id == id {
                update(&canvases[i])
                save()
                return
            }
            updateCanvasRecursive(id: id, canvases: &canvases[i].children, update: update)
        }
    }

    func addItem(_ item: Item, to canvasId: UUID? = nil) {
        guard let targetId = canvasId ?? canvases.first?.id else { return }
        updateCanvas(withId: targetId) { canvas in
            canvas.items.insert(item, at: 0)
        }
    }

    func updateItem(_ item: Item, in canvas: Canvas, newContent: String) {
        updateCanvas(withId: canvas.id) { canvas in
            if let itemIndex = canvas.items.firstIndex(where: { $0.id == item.id }) {
                // Determine new type based on content
                let type: ItemType
                if newContent.starts(with: "http://") || newContent.starts(with: "https://") {
                    type = .link
                } else if newContent.starts(with: "/") || newContent.starts(with: "~") {
                    type = .file
                } else {
                    type = .text
                }

                canvas.items[itemIndex].content = newContent
                canvas.items[itemIndex].type = type
            }
        }
    }

    func deleteItem(_ item: Item, from canvas: Canvas) {
        updateCanvas(withId: canvas.id) { canvas in
            canvas.items.removeAll { $0.id == item.id }
        }
    }

    func moveItem(_ item: Item, from sourceCanvas: Canvas, to targetCanvas: Canvas) {
        // Remove from source
        updateCanvas(withId: sourceCanvas.id) { canvas in
            canvas.items.removeAll { $0.id == item.id }
        }
        // Add to target
        updateCanvas(withId: targetCanvas.id) { canvas in
            canvas.items.insert(item, at: 0)
        }
    }
    
    func updateItemTitle(itemId: UUID, title: String?) {
        updateItemTitleRecursive(itemId: itemId, title: title, in: &canvases)
    }

    private func updateItemTitleRecursive(itemId: UUID, title: String?, in canvases: inout [Canvas]) {
        for i in canvases.indices {
            if let itemIndex = canvases[i].items.firstIndex(where: { $0.id == itemId }) {
                canvases[i].items[itemIndex].title = title
                save()
                return
            }
            updateItemTitleRecursive(itemId: itemId, title: title, in: &canvases[i].children)
        }
    }

    func reorderItems(in canvas: Canvas, from indices: IndexSet, to newOffset: Int) {
        updateCanvas(withId: canvas.id) { canvas in
            canvas.items.move(fromOffsets: indices, toOffset: newOffset)
        }
    }

    func reorderCanvases(from indices: IndexSet, to newOffset: Int) {
        canvases.move(fromOffsets: indices, toOffset: newOffset)
        save()
    }

    func createNewFolder(with canvas: Canvas) {
        // Generate folder name (Folder 1, Folder 2, etc.)
        let folderName = generateFolderName()

        // Find and remove the canvas
        guard let canvasIndex = canvases.firstIndex(where: { $0.id == canvas.id }) else {
            return
        }

        let removedCanvas = canvases.remove(at: canvasIndex)

        // Create a new folder with the canvas inside
        var folder = Canvas(name: folderName, isFolder: true)
        folder.children = [removedCanvas]

        // Insert folder where the canvas was
        canvases.insert(folder, at: canvasIndex)

        save()
    }

    func addCanvasToExistingFolder(_ canvas: Canvas, folder: Canvas) {
        // Remove canvas from wherever it is
        removeCanvas(withId: canvas.id, from: &canvases)

        // Add to folder
        updateCanvas(withId: folder.id) { folder in
            folder.children.append(canvas)
        }
    }

    func moveCanvasToRoot(_ canvas: Canvas) {
        // Remove canvas from wherever it is
        if let removed = removeCanvas(withId: canvas.id, from: &canvases) {
            // Add to root level
            canvases.append(removed)
            save()
        }
    }

    func isCanvasInFolder(_ canvas: Canvas) -> Bool {
        return getParentFolder(of: canvas) != nil
    }

    func getParentFolder(of canvas: Canvas) -> Canvas? {
        func findParent(in canvases: [Canvas]) -> Canvas? {
            for candidate in canvases {
                if candidate.children.contains(where: { $0.id == canvas.id }) {
                    return candidate
                }
                if let found = findParent(in: candidate.children) {
                    return found
                }
            }
            return nil
        }
        return findParent(in: canvases)
    }

    private func generateFolderName() -> String {
        var folderNumber = 1
        var folderName = "Folder 1"

        // Get all existing folder names
        let existingNames = getAllFolderNames()

        // Find the next available folder number
        while existingNames.contains(folderName) {
            folderNumber += 1
            folderName = "Folder \(folderNumber)"
        }

        return folderName
    }

    private func getAllFolderNames() -> Set<String> {
        var names = Set<String>()

        func collectNames(_ canvases: [Canvas]) {
            for canvas in canvases {
                if canvas.isFolder {
                    names.insert(canvas.name)
                }
                collectNames(canvas.children)
            }
        }

        collectNames(canvases)
        return names
    }

    private func removeCanvas(withId id: UUID, from canvases: inout [Canvas]) -> Canvas? {
        for i in canvases.indices {
            if canvases[i].id == id {
                let removed = canvases.remove(at: i)
                save()
                return removed
            }
            if let removed = removeCanvas(withId: id, from: &canvases[i].children) {
                return removed
            }
        }
        return nil
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(canvases)
            try data.write(to: saveURL)
        } catch {
            print("Failed to save: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            canvases = try JSONDecoder().decode([Canvas].self, from: data)
            if let firstCanvas = canvases.first {
                selectedCanvasId = firstCanvas.id
            }
        } catch {
            print("Failed to load (might be first run): \(error)")
        }
    }
}
