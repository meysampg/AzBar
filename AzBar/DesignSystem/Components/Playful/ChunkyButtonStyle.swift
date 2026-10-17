// STUB (P-A): implement, keep signatures
import SwiftUI

/// 3D button: a darker edge sits under the shape; pressing moves the label down by `depth` and hides the edge.
/// Label font `.app(.headline, weight: .bold)`, minHeight 50, maxWidth .infinity; light impact haptic.
struct ChunkyButtonStyle: ButtonStyle {
    var tint: Color = .green
    var filled: Bool = true
    var depth: CGFloat = 5
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(.headline, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(filled ? Color.white : tint)
            .background(filled ? tint : Color.clear, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ tint: Color = .green, filled: Bool = true) -> ChunkyButtonStyle {
        ChunkyButtonStyle(tint: tint, filled: filled)
    }
}
