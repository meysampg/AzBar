import SwiftUI

/// The continuous learning-path map.
///
/// Everything is drawn in ONE left-to-right coordinate space (`geo.points`, x from the left): the three
/// curve strokes and every medallion/label/bubble are placed from the very same point array, so they can
/// never drift apart (RTL layout, Dynamic Type or width changes only change the metrics). The root ZStack
/// pins `layoutDirection = .leftToRight` (Shapes are not mirrored); text re-applies `.rightToLeft`.
struct PathMapView: View {
    let nodes: [PathNode]
    /// First and last memorizable position (1-based) per lesson node id.
    let beytRanges: [String: ClosedRange<Int>]
    /// Id of a current lesson that was already started («ادامه»).
    let partialNodeId: String?
    let onStart: (LearnMode) -> Void
    /// Fixed width instead of measuring (used by snapshot tests where no layout pass reports geometry).
    var fixedWidth: CGFloat?

    @State private var measuredWidth: CGFloat = 360
    @ScaledMetric(relativeTo: .title3) private var lessonBase: CGFloat = 64
    @ScaledMetric(relativeTo: .footnote) private var line: CGFloat = 20
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    init(nodes: [PathNode], beytRanges: [String: ClosedRange<Int>], partialNodeId: String?,
         fixedWidth: CGFloat? = nil, onStart: @escaping (LearnMode) -> Void) {
        self.nodes = nodes
        self.beytRanges = beytRanges
        self.partialNodeId = partialNodeId
        self.fixedWidth = fixedWidth
        self.onStart = onStart
    }

    private var width: CGFloat { fixedWidth ?? measuredWidth }
    private var lesson: CGFloat { min(lessonBase, 84) }
    private var labelBlock: CGFloat { 2 * line + 6 }
    private var bubble: CGFloat { line + 14 }

    private func diameter(_ node: PathNode) -> CGFloat {
        switch node.kind {
        case .lesson: lesson
        case .review: lesson * 0.875
        case .challenge: lesson * 1.2
        }
    }

    /// Metrics are derived from the current Dynamic Type size and the measured width.
    var geometry: PathGeometry {
        let diameters = nodes.map { Double(diameter($0)) }
        let maxD = diameters.max() ?? 0
        let rowHeight = maxD + Double(labelBlock + bubble) + 24
        return PathGeometry(metrics: .init(
            width: Double(width),
            diameters: diameters,
            rowHeight: rowHeight,
            topInset: Double(bubble) + 16 + maxD / 2,
            bottomInset: Double(labelBlock) + 24,
            labelWidth: Double(min(width - 32, 9 * line))))
    }

    var body: some View {
        let geo = geometry
        VStack(spacing: 0) {
            map(geo)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { measuredWidth = $0 }
    }

    private func map(_ geo: PathGeometry) -> some View {
        let segments = geo.segments
        let reached = PathGeometry.reachedSegmentCount(nodes.map(\.state))
        let remainingEnd = max(segments.count, reached)
        let labelWidth = CGFloat(min(Double(width) - 32, Double(9 * line)))

        return ZStack(alignment: .topLeading) {
            // The continuous curve: road, remaining (dashed sand), completed (teal).
            Group {
                PathCurveShape(segments: segments, range: 0..<segments.count)
                    .stroke(Theme.Palette.track, style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                PathCurveShape(segments: segments, range: reached..<remainingEnd)
                    .stroke(Theme.Palette.sand, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10]))
                PathCurveShape(segments: segments, range: 0..<reached)
                    .stroke(Theme.Palette.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            }
            .accessibilityHidden(true)

            ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                let p = geo.points[i]
                let d = diameter(node)

                // Scroll anchor: a clear square exactly over the node (id resolves to this frame).
                Color.clear
                    .frame(width: d, height: d)
                    .id(node.id)
                    .padding(.leading, p.x - d / 2)
                    .padding(.top, p.y - d / 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                PathNodeMedallion(node: node, diameter: d, caption: caption(node),
                                  isPartial: node.id == partialNodeId, onStart: onStart)
                    .position(p)
                    .accessibilitySortPriority(Double(nodes.count - i))

                label(node)
                    .frame(width: labelWidth, height: labelBlock, alignment: .top)
                    .environment(\.layoutDirection, .rightToLeft)
                    .position(x: p.x, y: p.y + d / 2 + 6 + labelBlock / 2)
                    .accessibilityHidden(true)

                if node.state == .current {
                    startBubble(isPartial: node.id == partialNodeId)
                        .environment(\.layoutDirection, .rightToLeft)
                        .position(x: p.x, y: p.y - d / 2 - 10 - bubble / 2)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
        .onAppear { bob = true }
    }

    // MARK: Labels

    private func caption(_ node: PathNode) -> String {
        switch node.kind {
        case .lesson:
            if let n = node.lessonNumber, let r = beytRanges[node.id] {
                "درس \(n.fa) · بیت \(r.lowerBound.fa)–\(r.upperBound.fa)"
            } else {
                "درس \(node.lessonNumber?.fa ?? "")"
            }
        case .review: "مرور درس‌ها"
        case .challenge: "آزمون پایانی"
        }
    }

    @ViewBuilder
    private func label(_ node: PathNode) -> some View {
        let locked = node.state == .locked
        VStack(spacing: 0) {
            switch node.kind {
            case .lesson:
                Text("درس \(node.lessonNumber?.fa ?? "")")
                    .font(.app(.footnote, weight: .semibold))
                    .foregroundStyle(locked ? Theme.Palette.inkTertiary : Theme.Palette.ink)
                if let r = beytRanges[node.id] {
                    Text("بیت \(r.lowerBound.fa)–\(r.upperBound.fa)")
                        .font(.azCaption)
                        .foregroundStyle(locked ? Theme.Palette.inkTertiary : Theme.Palette.inkSecondary)
                }
            case .review:
                Text("مرور درس‌ها")
                    .font(.app(.footnote, weight: .semibold))
                    .foregroundStyle(locked ? Theme.Palette.inkTertiary : Theme.Palette.ink)
            case .challenge:
                Text("آزمون پایانی")
                    .font(.app(.footnote, weight: .semibold))
                    .foregroundStyle(locked ? Theme.Palette.inkTertiary : Theme.Palette.ink)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .multilineTextAlignment(.center)
    }

    private func startBubble(isPartial: Bool) -> some View {
        VStack(spacing: 0) {
            Text(isPartial ? "ادامه" : "شروع")
                .font(.app(.footnote, weight: .bold))
                .foregroundStyle(Theme.Palette.teal)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(height: bubble - 8)
                .background(Theme.Palette.card, in: Capsule())
                .overlay { Capsule().strokeBorder(Theme.Palette.hairline, lineWidth: 1) }
                .azShadow(Theme.Shadow.elevated)
            BubbleTail()
                .fill(Theme.Palette.card)
                .frame(width: 14, height: 8)
        }
        .frame(height: bubble)
        .offset(y: bob && !reduceMotion ? -3 : 0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bob)
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    let nodes: [PathNode] = [
        PathNode(id: "L0", kind: .lesson, ordinal: 0, coupletIndices: [0, 1], lessonNumber: 1, state: .completed),
        PathNode(id: "L2", kind: .lesson, ordinal: 1, coupletIndices: [2, 3], lessonNumber: 2, state: .current),
        PathNode(id: "R3", kind: .review, ordinal: 2, coupletIndices: [0, 1, 2, 3], lessonNumber: nil, state: .locked),
        PathNode(id: "C", kind: .challenge, ordinal: 3, coupletIndices: [0, 1, 2, 3], lessonNumber: nil, state: .locked),
    ]
    return ScrollView {
        PathMapView(nodes: nodes, beytRanges: ["L0": 1...2, "L2": 3...4], partialNodeId: nil, onStart: { _ in })
    }
    .azScreenBackground()
    .persianRoot()
}
