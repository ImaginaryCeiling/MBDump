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

struct Canvas: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [Item] = []
}

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
        canvases.first { $0.id == selectedCanvasId }
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
        if let index = canvases.firstIndex(where: { $0.id == canvas.id }) {
            canvases[index].name = newName
            save()
        }
    }

    func addItem(_ item: Item, to canvasId: UUID? = nil) {
        let targetId = canvasId ?? canvases.first?.id
        if let index = canvases.firstIndex(where: { $0.id == targetId }) {
            canvases[index].items.insert(item, at: 0)
            save()
        }
    }

    func deleteItem(_ item: Item, from canvas: Canvas) {
        if let canvasIndex = canvases.firstIndex(where: { $0.id == canvas.id }) {
            canvases[canvasIndex].items.removeAll { $0.id == item.id }
            save()
        }
    }

    func moveItem(_ item: Item, from sourceCanvas: Canvas, to targetCanvas: Canvas) {
        if let sourceIndex = canvases.firstIndex(where: { $0.id == sourceCanvas.id }),
           let targetIndex = canvases.firstIndex(where: { $0.id == targetCanvas.id }) {
            canvases[sourceIndex].items.removeAll { $0.id == item.id }
            canvases[targetIndex].items.insert(item, at: 0)
            save()
        }
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
