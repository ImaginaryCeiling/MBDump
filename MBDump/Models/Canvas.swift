import Foundation

enum CanvasType: String, Codable, CaseIterable {
    case todo = "todo"
    case articles = "articles"

    var displayName: String {
        switch self {
        case .todo: return "Todo"
        case .articles: return "Articles"
        }
    }
}

struct Canvas: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [Item] = []
    var children: [Canvas] = []
    var isFolder: Bool = false
    var type: CanvasType? = nil
    var tags: [String] = []

    // For List with hierarchical children - show children if folder or if has children
    var childrenForList: [Canvas]? {
        isFolder || !children.isEmpty ? children : nil
    }

    // Helper to get all canvases recursively (for finding by ID)
    func findCanvas(byId id: UUID) -> Canvas? {
        if self.id == id {
            return self
        }
        for child in children {
            if let found = child.findCanvas(byId: id) {
                return found
            }
        }
        return nil
    }

    // Custom Codable implementation to handle old JSON without children/isFolder/type/tags
    enum CodingKeys: String, CodingKey {
        case id, name, items, children, isFolder, type, tags
    }

    init(id: UUID = UUID(), name: String, items: [Item] = [], children: [Canvas] = [], isFolder: Bool = false, type: CanvasType? = nil, tags: [String] = []) {
        self.id = id
        self.name = name
        self.items = items
        self.children = children
        self.isFolder = isFolder
        self.type = type
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        items = try container.decode([Item].self, forKey: .items)
        // Use default values if these keys don't exist (for backward compatibility)
        children = try container.decodeIfPresent([Canvas].self, forKey: .children) ?? []
        isFolder = try container.decodeIfPresent(Bool.self, forKey: .isFolder) ?? false

        // Handle backward compatibility: try to decode as CanvasType first,
        // then fall back to String and convert
        if let canvasType = try? container.decodeIfPresent(CanvasType.self, forKey: .type) {
            type = canvasType
        } else if let typeString = try? container.decodeIfPresent(String.self, forKey: .type) {
            // Convert old string types to new enum
            type = CanvasType(rawValue: typeString)
        } else {
            type = nil
        }

        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
