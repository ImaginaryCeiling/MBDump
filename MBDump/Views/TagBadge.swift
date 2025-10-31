import SwiftUI

struct TagBadge: View {
    let text: String
    let isType: Bool // true for type badge, false for tag badge

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForText(text).opacity(0.2))
            .foregroundColor(colorForText(text))
            .cornerRadius(4)
    }

    // Generate a consistent color based on the text hash
    private func colorForText(_ text: String) -> Color {
        let hash = abs(text.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}
