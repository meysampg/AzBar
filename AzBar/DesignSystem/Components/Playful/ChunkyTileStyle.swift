// STUB (P-A): implement, keep signatures
import SwiftUI

/// Word tile / option tile: white (secondarySystemBackground) with a 3 pt gray edge.
/// `.placeholder` is an empty gray slot that keeps the tile's size.
struct ChunkyTileStyle: ButtonStyle {
    var isSelected = false
    var state: TileState = .normal

    enum TileState { case normal, correct, wrong, placeholder }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: Theme.Radius.small))
    }
}
