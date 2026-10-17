import SwiftUI

// Deprecated shim: forwards to `AzTileStyle`. Removed in the final cleanup.

@available(*, deprecated, message: "Use AzTileStyle")
struct ChunkyTileStyle: ButtonStyle {
    var isSelected = false
    var state: TileState = .normal

    typealias TileState = AzTileStyle.TileState

    func makeBody(configuration: Configuration) -> some View {
        AzTileStyle(isSelected: isSelected, state: state).makeBody(configuration: configuration)
    }
}
