import SwiftUI

/// Word / option tile: white face with a 3 pt edge. `.placeholder` is an empty slot that keeps the tile's size.
struct AzTileStyle: ButtonStyle {
    var isSelected = false
    var state: TileState = .normal

    enum TileState { case normal, correct, wrong, placeholder }

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, style: self)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        let style: AzTileStyle
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        private var colors: (face: Color, edge: Color?) {
            switch style.state {
            case .normal:
                style.isSelected ? (Theme.Palette.tealSoft, Theme.Palette.teal) : (Theme.Palette.card, Color(hex: 0xE3D9C3))
            case .correct: (Theme.Palette.successSoft, Theme.Palette.success)
            case .wrong: (Theme.Palette.dangerSoft, Theme.Palette.danger)
            case .placeholder: (Theme.Palette.paperDeep, nil)
            }
        }

        var body: some View {
            let isPlaceholder = style.state == .placeholder
            let pressed = configuration.isPressed && !isPlaceholder
            let c = colors
            configuration.label
                .font(.app(.body, weight: .medium))
                .foregroundStyle(Theme.Palette.ink)
                .opacity(isPlaceholder ? 0 : 1)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .frame(minHeight: 44)
                .modifier(AzEdgedSurface(
                    fill: c.face, edge: c.edge, border: c.edge, borderWidth: 1.5,
                    radius: Theme.Radius.tile, depth: 3, pressed: pressed))
                .padding(.bottom, isPlaceholder ? 3 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: style.state)
        }
    }
}

#Preview {
    HStack {
        Button("دل") {}.buttonStyle(AzTileStyle())
        Button("جان") {}.buttonStyle(AzTileStyle(isSelected: true))
        Button("عشق") {}.buttonStyle(AzTileStyle(state: .correct))
        Button("غم") {}.buttonStyle(AzTileStyle(state: .wrong))
        Button("جا") {}.buttonStyle(AzTileStyle(state: .placeholder))
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}
