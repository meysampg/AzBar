import SwiftUI

/// 3D button: a darker edge sits under the shape; pressing moves the face down by `depth` and hides the edge.
/// Label font `.app(.headline, weight: .bold)`, minHeight 50, maxWidth .infinity; light impact haptic.
struct ChunkyButtonStyle: ButtonStyle {
    var tint: Color = .green
    var filled: Bool = true
    var depth: CGFloat = 5
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, style: self)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        let style: ChunkyButtonStyle

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = configuration.isPressed && isEnabled
            let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
            let face: Color = !isEnabled ? Color(.systemGray5)
                : style.filled ? style.tint : Color(.systemBackground)
            let edge: Color = !isEnabled ? Color(.systemGray4)
                : style.filled ? style.tint.mix(with: .black, by: 0.25) : style.tint.opacity(0.55)
            let text: Color = !isEnabled ? Color.secondary : style.filled ? .white : style.tint

            configuration.label
                .font(.app(.headline, weight: .bold))
                .foregroundStyle(text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 50)
                .padding(.horizontal, Theme.Spacing.m)
                .background(face, in: shape)
                .overlay {
                    if !style.filled && isEnabled { shape.strokeBorder(edge, lineWidth: 2) }
                }
                .background {
                    shape.fill(edge)
                        .offset(y: style.depth)
                        .opacity(pressed ? 0 : 1)
                }
                .offset(y: pressed ? style.depth : 0)
                .padding(.bottom, style.depth)
                .contentShape(.rect)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
                .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, new in new }
        }
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ tint: Color = .green, filled: Bool = true) -> ChunkyButtonStyle {
        ChunkyButtonStyle(tint: tint, filled: filled)
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("ادامه") {}.buttonStyle(.chunky())
        Button("نادرست", action: {}).buttonStyle(.chunky(.red))
        Button("بعداً", action: {}).buttonStyle(.chunky(.blue, filled: false))
        Button("غیرفعال", action: {}).buttonStyle(.chunky()).disabled(true)
    }
    .padding()
    .persianRoot()
}
