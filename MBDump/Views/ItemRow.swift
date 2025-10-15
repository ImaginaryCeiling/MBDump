import SwiftUI

struct ItemRow: View {
    let item: Item
    let canvas: Canvas
    let store: DataStore

    @State private var isEditing = false
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
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
                    Text(item.displayContent)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            startEditing()
                        }
                }

                if !isEditing && item.type == .link {
                    Text(item.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if !isEditing {
                    Text(item.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive, action: {
                store.deleteItem(item, from: canvas)
            }) {
                Label("", systemImage: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)

        }
        .padding(.vertical, 4)
    }

    private func startEditing() {
        editText = item.content
        isEditing = true
        isFocused = true
    }

    private func saveEdit() {
        if !editText.isEmpty && editText != item.content {
            store.updateItem(item, in: canvas, newContent: editText)
        }
        isEditing = false
    }

    private var iconName: String {
        switch item.type {
        case .link: return "link"
        case .text: return "text.quote"
        case .file: return "doc"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .link: return .blue
        case .text: return .primary
        case .file: return .orange
        }
    }
}
