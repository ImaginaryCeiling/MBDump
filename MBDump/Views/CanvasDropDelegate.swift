import SwiftUI

// Drop delegate for canvas sidebar items
struct CanvasDropDelegate: DropDelegate {
    let canvas: Canvas
    let store: DataStore

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }

        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            guard let data = data as? Data,
                  let draggedData = String(data: data, encoding: .utf8) else {
                return
            }

            // Parse the item ID and source canvas ID
            let components = draggedData.split(separator: "|")
            guard components.count == 2,
                  let itemId = UUID(uuidString: String(components[0])),
                  let sourceCanvasId = UUID(uuidString: String(components[1])),
                  let sourceCanvas = store.canvases.first(where: { $0.id == sourceCanvasId }),
                  let item = sourceCanvas.items.first(where: { $0.id == itemId }) else {
                return
            }

            // Move the item
            DispatchQueue.main.async {
                store.moveItem(item, from: sourceCanvas, to: canvas)
            }
        }

        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.text])
    }
}
