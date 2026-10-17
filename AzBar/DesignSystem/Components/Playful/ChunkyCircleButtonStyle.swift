import SwiftUI

/// Round 3D button used by the learning-path nodes.
struct ChunkyCircleButtonStyle: ButtonStyle {
    var tint: Color
    var diameter: CGFloat = 72
    var depth: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, style: self)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        let style: ChunkyCircleButtonStyle

        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = configuration.isPressed
            configuration.label
                .foregroundStyle(.white)
                .frame(width: style.diameter, height: style.diameter)
                .background(style.tint, in: Circle())
                .background {
                    Circle().fill(style.tint.mix(with: .black, by: 0.25))
                        .offset(y: style.depth)
                        .opacity(pressed ? 0 : 1)
                }
                .offset(y: pressed ? style.depth : 0)
                .padding(.bottom, style.depth)
                .contentShape(.circle)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
                .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, new in new }
        }
    }
}

#Preview {
    Button { } label: { Image(systemName: "star.fill").font(.title) }
        .buttonStyle(ChunkyCircleButtonStyle(tint: .green))
        .padding()
        .persianRoot()
}
