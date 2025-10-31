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

            DispatchQueue.main.async {
                // Check if it's a canvas being dragged
                if draggedData.starts(with: "CANVAS:") {
                    let canvasIdString = String(draggedData.dropFirst("CANVAS:".count))
                    guard let draggedCanvasId = UUID(uuidString: canvasIdString),
                          let draggedCanvas = store.findCanvas(byId: draggedCanvasId, in: store.canvases) else {
                        return
                    }

                    // If dropping onto a folder, add canvas to folder
                    if canvas.isFolder {
                        store.addCanvasToExistingFolder(draggedCanvas, folder: canvas)
                    }
                    // If dropping onto a regular canvas, do nothing (user can use context menu)
                } else {
                    // It's an item being dragged
                    let components = draggedData.split(separator: "|")
                    guard components.count == 2,
                          let itemId = UUID(uuidString: String(components[0])),
                          let sourceCanvasId = UUID(uuidString: String(components[1])),
                          let sourceCanvas = store.findCanvas(byId: sourceCanvasId, in: store.canvases),
                          let item = sourceCanvas.items.first(where: { $0.id == itemId }) else {
                        return
                    }

                    // Move the item (only works for non-folder targets)
                    if !canvas.isFolder {
                        store.moveItem(item, from: sourceCanvas, to: canvas)
                    }
                }
            }
        }

        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.text])
    }
}
