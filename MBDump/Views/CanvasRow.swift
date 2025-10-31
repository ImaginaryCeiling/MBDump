import SwiftUI

struct CanvasRow: View {
    let canvas: Canvas
    let store: DataStore

    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var isHovering = false
    @State private var showingTypeTagPopover = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            if canvas.isFolder {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
            }

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        saveEdit()
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        if !newValue && isEditing {
                            saveEdit()
                        }
                    }
            } else {
                HStack(spacing: 4) {
                    Text(canvas.name)
                        .onTapGesture(count: 2) {
                            startEditing()
                        }

                    // Type badge
                    if let type = canvas.type {
                        TagBadge(text: type.displayName, isType: true)
                    }

                    // Tag badges (show first 2)
                    ForEach(canvas.tags.prefix(2), id: \.self) { tag in
                        TagBadge(text: tag, isType: false)
                    }

                    // Show "+N" if there are more tags
                    if canvas.tags.count > 2 {
                        Text("+\(canvas.tags.count - 2)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Gear button (appears on hover or when popover is showing)
            if (isHovering || showingTypeTagPopover) && !isEditing {
                Button(action: {
                    showingTypeTagPopover = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingTypeTagPopover, arrowEdge: .trailing) {
                    CanvasTypeTagEditor(canvas: canvas, store: store)
                }
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            // Don't allow dragging the Inbox
            if canvas.name == "Inbox" {
                return NSItemProvider()
            }
            // Provide canvas ID for drag
            let canvasData = "CANVAS:\(canvas.id.uuidString)"
            return NSItemProvider(object: canvasData as NSString)
        }
    }

    private func startEditing() {
        editText = canvas.name
        isEditing = true
        isFocused = true
    }

    private func saveEdit() {
        if !editText.isEmpty && editText != canvas.name {
            store.renameCanvas(canvas, to: editText)
        }
        isEditing = false
    }
}
