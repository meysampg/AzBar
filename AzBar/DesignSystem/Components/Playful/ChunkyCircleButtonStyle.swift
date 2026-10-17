// STUB (P-A): implement, keep signatures
import SwiftUI

/// Round 3D button used by the learning-path nodes.
struct ChunkyCircleButtonStyle: ButtonStyle {
    var tint: Color
    var diameter: CGFloat = 72
    var depth: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: diameter, height: diameter)
            .background(tint, in: Circle())
    }
}
