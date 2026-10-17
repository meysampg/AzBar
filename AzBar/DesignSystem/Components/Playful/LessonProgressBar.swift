import SwiftUI

/// Capsule track (.quaternary) with a leading-aligned fill (right edge in RTL), a 0.3 white top
/// highlight and a spring animation. Accessibility: «پیشرفت جلسه» and "\(p.fa) درصد".
struct LessonProgressBar: View {
    var value: Double
    var tint: Color = Theme.Playful.correct
    var height: CGFloat = 16

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            let fillWidth = clamped == 0 ? 0 : max(height, proxy.size.width * clamped)
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(tint)
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .frame(height: height * 0.28)
                            .padding(.horizontal, height * 0.35)
                            .padding(.top, height * 0.18)
                    }
                    .frame(width: fillWidth)
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.25), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("پیشرفت جلسه")
        .accessibilityValue("\(Int((clamped * 100).rounded()).fa) درصد")
    }
}

#Preview {
    VStack(spacing: 16) {
        LessonProgressBar(value: 0)
        LessonProgressBar(value: 0.35)
        LessonProgressBar(value: 1, tint: .blue)
    }
    .padding()
    .persianRoot()
}
