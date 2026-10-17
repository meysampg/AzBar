import SwiftUI

/// Capsule progress bar; fills from the leading edge (the right side in RTL).
struct AzProgressBar: View {
    var value: Double
    var tint: Color = Theme.Palette.teal
    var height: CGFloat = 8
    var label: LocalizedStringKey = "پیشرفت"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { value.isFinite ? min(max(value, 0), 1) : 0 }

    var body: some View {
        GeometryReader { proxy in
            let fillWidth = clamped == 0 ? 0 : max(height, proxy.size.width * clamped)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.track)
                Capsule().fill(tint).frame(width: fillWidth)
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(Int((clamped * 100).rounded()).fa) درصد")
    }
}

#Preview {
    VStack(spacing: 16) {
        AzProgressBar(value: 0)
        AzProgressBar(value: 0.35)
        AzProgressBar(value: 0.7, tint: Theme.Palette.gold, height: 6)
        AzProgressBar(value: 1, height: 12, label: "پیشرفت جلسه")
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}
