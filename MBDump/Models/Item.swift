import Foundation

struct Item: Identifiable, Codable {
    let id: UUID
    var content: String
    var type: ItemType
    var createdAt: Date

    init(id: UUID = UUID(), content: String, type: ItemType, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
    }

    var displayContent: String {
        if type == .link, let url = URL(string: content) {
            return url.host ?? content
        }
        return content
    }
}
