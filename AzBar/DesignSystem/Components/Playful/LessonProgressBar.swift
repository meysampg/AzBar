import SwiftUI

// Deprecated shim: forwards to `AzProgressBar`. Removed in the final cleanup.

@available(*, deprecated, message: "Use AzProgressBar")
struct LessonProgressBar: View {
    var value: Double
    var tint: Color = Theme.Palette.teal
    var height: CGFloat = 12

    var body: some View {
        AzProgressBar(value: value, tint: tint, height: height, label: "پیشرفت جلسه")
    }
}
