import SwiftUI

enum AzMedallionKind: Sendable { case circle, roundedSquare }

struct AzMedallionShape: InsettableShape {
    var kind: AzMedallionKind
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        switch kind {
        case .circle:
            return Path(ellipseIn: r)
        case .roundedSquare:
            let radius = max(0, min(Theme.Radius.medallionSquare, min(rect.width, rect.height) * 0.36) - inset)
            return Path(roundedRect: r, cornerRadius: radius, style: .continuous)
        }
    }

    func inset(by amount: CGFloat) -> AzMedallionShape {
        var copy = self
        copy.inset += amount
        return copy
    }
}

private struct AzMedallionPressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Set by `AzMedallionButtonStyle` so the medallion can sink its face onto the edge.
    var azMedallionPressed: Bool {
        get { self[AzMedallionPressedKey.self] }
        set { self[AzMedallionPressedKey.self] = newValue }
    }
}

/// Face plus a 4 pt bottom edge, optional rim and the medallion shadow.
/// The edge is drawn below the face and does not take layout space.
struct AzMedallion<Content: View>: View {
    var shape: AzMedallionKind = .circle
    var diameter: CGFloat
    var fill: Color
    var rim: Color?
    var rimWidth: CGFloat = 3
    var edge: Color
    var edgeDepth: CGFloat = 4
    @ViewBuilder var content: Content

    @Environment(\.azMedallionPressed) private var pressed

    init(shape: AzMedallionKind = .circle, diameter: CGFloat, fill: Color, rim: Color? = nil,
         rimWidth: CGFloat = 3, edge: Color, edgeDepth: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.shape = shape
        self.diameter = diameter
        self.fill = fill
        self.rim = rim
        self.rimWidth = rimWidth
        self.edge = edge
        self.edgeDepth = edgeDepth
        self.content = content()
    }

    var body: some View {
        let s = AzMedallionShape(kind: shape)
        ZStack {
            s.fill(edge)
                .frame(width: diameter, height: diameter)
                .offset(y: edgeDepth)
                .opacity(pressed ? 0 : 1)
            s.fill(fill)
                .frame(width: diameter, height: diameter)
                .overlay {
                    if let rim { s.strokeBorder(rim, lineWidth: rimWidth) }
                }
                .overlay { content }
                .azShadow(Theme.Shadow.medallion)
                .offset(y: pressed ? edgeDepth : 0)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Press moves the face down by the edge depth. Haptic included.
struct AzMedallionButtonStyle: ButtonStyle {
    var edgeDepth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .environment(\.azMedallionPressed, configuration.isPressed)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
                .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, new in new }
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        Button { } label: {
            AzMedallion(diameter: 64, fill: Theme.Palette.teal, rim: Theme.Palette.gold, rimWidth: 5, edge: Theme.Palette.tealDeep) {
                Image(systemName: "star.fill").font(.title2).foregroundStyle(.white)
            }
        }
        .buttonStyle(AzMedallionButtonStyle())
        AzMedallion(shape: .roundedSquare, diameter: 56, fill: .white, rim: Theme.Palette.teal, edge: Theme.Palette.whiteEdge) {
            Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Theme.Palette.teal)
        }
    }
    .padding(30)
    .azScreenBackground()
    .persianRoot()
}
