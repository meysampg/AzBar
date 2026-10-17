import SwiftUI

struct AzIconBadge: View {
    let systemImage: String
    var tone: AzTone
    var size: CGFloat

    init(_ systemImage: String, tone: AzTone = .teal, size: CGFloat = 36) {
        self.systemImage = systemImage
        self.tone = tone
        self.size = size
    }

    init(systemImage: String, tone: AzTone = .teal, size: CGFloat = 36) {
        self.init(systemImage, tone: tone, size: size)
    }

    var body: some View {
        Circle()
            .fill(tone.soft)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tone.foreground)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        AzIconBadge("rectangle.stack.fill", tone: .teal)
        AzIconBadge("sparkles", tone: .gold)
        AzIconBadge("books.vertical", tone: .teal, size: 32)
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}
