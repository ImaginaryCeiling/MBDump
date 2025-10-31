import SwiftUI

// Drop delegate for the root level (moves canvases out of folders)
struct RootDropDelegate: DropDelegate {
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

                    // Move canvas to root level
                    store.moveCanvasToRoot(draggedCanvas)
                }
            }
        }

        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.text])
    }
}
