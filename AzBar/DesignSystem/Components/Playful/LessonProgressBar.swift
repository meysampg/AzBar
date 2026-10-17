// STUB (P-A): implement, keep signatures
import SwiftUI

/// Capsule track (.quaternary) with a leading-aligned fill, a 0.3 white top highlight and a spring animation.
/// Accessibility: «پیشرفت جلسه» and "\(p.fa) درصد".
struct LessonProgressBar: View {
    var value: Double
    var tint: Color = Theme.Playful.correct
    var height: CGFloat = 16

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(.quaternary)
            Capsule().fill(tint)
                .containerRelativeFrame(.horizontal) { w, _ in w * clamped }
        }
        .frame(height: height)
        .animation(.spring, value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("پیشرفت جلسه")
        .accessibilityValue("\(Int((clamped * 100).rounded()).fa) درصد")
    }
}
