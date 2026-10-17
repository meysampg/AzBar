import SwiftUI

// Deprecated shim: forwards to the Az* paper styles. Removed in the final cleanup.

@available(*, deprecated, message: "Use .azPrimary / .azSecondary")
struct ChunkyButtonStyle: PrimitiveButtonStyle {
    var tint: Color = Theme.Palette.success
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        if filled {
            Button(configuration).buttonStyle(AzPrimaryButtonStyle(tone: tone))
        } else {
            Button(configuration).buttonStyle(AzSecondaryButtonStyle())
        }
    }

    private var tone: AzPrimaryTone {
        if tint == Theme.Palette.danger { .danger }
        else if tint == Theme.Palette.success { .success }
        else { .teal }
    }
}

@available(*, deprecated, message: "Use .azPrimary / .azSecondary")
extension PrimitiveButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ tint: Color = Theme.Palette.success, filled: Bool = true) -> ChunkyButtonStyle {
        ChunkyButtonStyle(tint: tint, filled: filled)
    }
}
