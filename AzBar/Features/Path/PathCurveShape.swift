import SwiftUI

/// A run of consecutive cubic segments of the learning-path curve, in the map's LTR coordinate space.
/// Ignores `rect` on purpose: the segments are absolute positions shared with the node medallions, so the
/// shape must never be mirrored (`flipsForRightToLeftLayoutDirection` stays false).
struct PathCurveShape: Shape {
    let segments: [BezierSegment]
    let range: Range<Int>

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lower = max(range.lowerBound, 0)
        let upper = min(range.upperBound, segments.count)
        guard lower < upper else { return path }
        path.move(to: segments[lower].from)
        for i in lower..<upper {
            let s = segments[i]
            path.addCurve(to: s.to, control1: s.c1, control2: s.c2)
        }
        return path
    }
}
