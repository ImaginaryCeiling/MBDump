import SwiftUI

struct CanvasTypeTagEditor: View {
    let canvas: Canvas
    let store: DataStore

    @State private var selectedType: CanvasType?
    @State private var newTagText: String = ""
    @FocusState private var isTagFieldFocused: Bool

    init(canvas: Canvas, store: DataStore) {
        self.canvas = canvas
        self.store = store
        _selectedType = State(initialValue: canvas.type)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type section
            VStack(alignment: .leading, spacing: 4) {
                Text("Type")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedType) {
                    Text("None").tag(nil as CanvasType?)
                    ForEach(CanvasType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type as CanvasType?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedType) { oldValue, newValue in
                    store.updateCanvasType(canvas, type: newValue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Tags section
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Display existing tags
                if !canvas.tags.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(canvas.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                TagBadge(text: tag, isType: false)
                                Button(action: {
                                    store.removeTag(from: canvas, tag: tag)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .cornerRadius(4)
                        }
                    }
                }

                // Add new tag
                HStack {
                    TextField("Add tag...", text: $newTagText)
                        .textFieldStyle(.plain)
                        .focused($isTagFieldFocused)
                        .onSubmit {
                            addTag()
                        }

                    if !newTagText.isEmpty {
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            }
        }
        .padding(12)
        .frame(width: 250)
    }

    private func addTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty {
            store.addTag(to: canvas, tag: trimmedTag)
            newTagText = ""
            isTagFieldFocused = true
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
