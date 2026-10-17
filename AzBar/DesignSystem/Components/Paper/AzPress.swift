import SwiftUI

/// The shared "paper chunky" surface: a face with a bottom edge that disappears when pressed.
struct AzEdgedSurface: ViewModifier {
    var fill: Color
    var edge: Color?
    var border: Color? = nil
    var borderWidth: CGFloat = 1.5
    var radius: CGFloat
    var depth: CGFloat
    var pressed: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(fill, in: shape)
            .overlay {
                if let border { shape.strokeBorder(border, lineWidth: borderWidth) }
            }
            .background {
                if let edge {
                    shape.fill(edge)
                        .offset(y: depth)
                        .opacity(pressed ? 0 : 1)
                }
            }
            .offset(y: pressed && edge != nil ? depth : 0)
            .padding(.bottom, edge != nil ? depth : 0)
            .contentShape(.rect)
    }
}
