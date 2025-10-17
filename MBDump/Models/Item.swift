import Foundation

struct Item: Identifiable, Codable {
    let id: UUID
    var content: String
    var type: ItemType
    var createdAt: Date
    var title: String?  // Website title for links

    init(id: UUID = UUID(), content: String, type: ItemType, createdAt: Date = Date(), title: String? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.title = title
    }

    var displayContent: String {
        if type == .link {
            // Show title if available, otherwise show host or URL
            if let title = title, !title.isEmpty {
                return title
            }
            if let url = URL(string: content) {
                return url.host ?? content
            }
        }
        return content
    }
}
