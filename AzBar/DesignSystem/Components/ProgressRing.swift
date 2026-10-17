import SwiftUI

/// Circular progress indicator, filling clockwise from the top.
struct ProgressRing: View {
    var value: Double
    var lineWidth: CGFloat = 5
    var showsPercent: Bool = false

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.Palette.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Theme.Palette.teal, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: clamped)
            if showsPercent {
                Text("\(Int((clamped * 100).rounded()).fa)٪")
                    .font(.app(.caption2, weight: .medium))
                    .foregroundStyle(Theme.Palette.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(lineWidth + 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("پیشرفت")
        .accessibilityValue("\(Int((clamped * 100).rounded()).fa) درصد")
    }
}

#Preview {
    HStack(spacing: 20) {
        ProgressRing(value: 0.35, showsPercent: true).frame(width: 44, height: 44)
        ProgressRing(value: 1, showsPercent: true).frame(width: 44, height: 44)
        ProgressRing(value: 0).frame(width: 30, height: 30)
    }
    .padding()
    .azScreenBackground()
    .persianRoot()
}
