import Foundation

struct Canvas: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [Item] = []
}
