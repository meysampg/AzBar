import SwiftUI

/// Word tile / option tile: secondary-background face with a 3 pt gray edge.
/// `.placeholder` is an empty gray slot that keeps the tile's size.
struct ChunkyTileStyle: ButtonStyle {
    var isSelected = false
    var state: TileState = .normal

    enum TileState { case normal, correct, wrong, placeholder }

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, style: self)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        let style: ChunkyTileStyle

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        private let edgeHeight: CGFloat = 3

        private var colors: (Color, Color) {
            switch style.state {
            case .normal:
                (style.isSelected ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground),
                 style.isSelected ? Color.blue : Color(.systemGray3))
            case .correct: (Theme.Playful.correct.opacity(0.18), Theme.Playful.correct)
            case .wrong: (Theme.Playful.wrong.opacity(0.18), Theme.Playful.wrong)
            case .placeholder: (Color(.systemGray5), Color(.systemGray5))
            }
        }

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: Theme.Radius.small + 4, style: .continuous)
            let isPlaceholder = style.state == .placeholder
            let pressed = configuration.isPressed && !isPlaceholder
            let (face, edge) = colors

            configuration.label
                .font(.app(.body, weight: .medium))
                .opacity(isPlaceholder ? 0 : 1)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .frame(minHeight: 44)
                .background(face, in: shape)
                .background {
                    if !isPlaceholder {
                        shape.fill(edge)
                            .offset(y: edgeHeight)
                            .opacity(pressed ? 0 : 1)
                    }
                }
                .offset(y: pressed ? edgeHeight : 0)
                .padding(.bottom, edgeHeight)
                .contentShape(.rect)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: style.state)
        }
    }
}

#Preview {
    HStack {
        Button("دل") {}.buttonStyle(ChunkyTileStyle())
        Button("جان") {}.buttonStyle(ChunkyTileStyle(isSelected: true))
        Button("عشق") {}.buttonStyle(ChunkyTileStyle(state: .correct))
        Button("غم") {}.buttonStyle(ChunkyTileStyle(state: .wrong))
        Button("جا") {}.buttonStyle(ChunkyTileStyle(state: .placeholder))
    }
    .padding()
    .persianRoot()
}
