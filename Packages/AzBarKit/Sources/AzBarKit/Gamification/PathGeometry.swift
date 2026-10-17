import Foundation
import CoreGraphics

public struct BezierSegment: Sendable, Hashable {
    public let from: CGPoint
    public let c1: CGPoint
    public let c2: CGPoint
    public let to: CGPoint

    public init(from: CGPoint, c1: CGPoint, c2: CGPoint, to: CGPoint) {
        self.from = from
        self.c1 = c1
        self.c2 = c2
        self.to = to
    }
}

/// Pure layout of the learning-path map: node centres in left-to-right coordinates (x from the left)
/// and the cubic segments joining them. Tangents are vertical at every node (C1-continuous).
public struct PathGeometry: Sendable, Hashable {
    public struct Metrics: Sendable, Hashable {
        public var width: Double
        /// One diameter per node.
        public var diameters: [Double]
        public var rowHeight: Double
        public var topInset: Double
        public var bottomInset: Double
        public var labelWidth: Double
        public var maxAmplitude: Double
        public var sideMargin: Double

        public init(width: Double, diameters: [Double], rowHeight: Double, topInset: Double,
                    bottomInset: Double, labelWidth: Double, maxAmplitude: Double = 110, sideMargin: Double = 12) {
            self.width = width
            self.diameters = diameters
            self.rowHeight = rowHeight
            self.topInset = topInset
            self.bottomInset = bottomInset
            self.labelWidth = labelWidth
            self.maxAmplitude = maxAmplitude
            self.sideMargin = sideMargin
        }
    }

    public let points: [CGPoint]
    public let amplitude: Double
    public let size: CGSize
    private let rowHeight: Double

    public init(metrics m: Metrics) {
        let maxD = m.diameters.max() ?? 0
        let a = max(0, min(m.maxAmplitude, m.width * 0.28,
                           (m.width - m.labelWidth) / 2 - m.sideMargin,
                           (m.width - maxD) / 2 - m.sideMargin))
        amplitude = a
        rowHeight = m.rowHeight
        points = m.diameters.indices.map { i in
            CGPoint(x: m.width / 2 + a * Self.wave(i), y: m.topInset + Double(i) * m.rowHeight)
        }
        let lastY: Double = points.last.map { Double($0.y) } ?? m.topInset
        size = CGSize(width: m.width, height: lastY + maxD / 2 + m.bottomInset)
    }

    /// Horizontal swing of node `i` in units of the amplitude; `wave(0) == 0`.
    public static func wave(_ i: Int) -> Double { sin(Double(i) * .pi / 4) }

    public var segments: [BezierSegment] {
        guard points.count > 1 else { return [] }
        let h = rowHeight * 0.5
        return (0..<(points.count - 1)).map { i in
            let a = points[i], b = points[i + 1]
            return BezierSegment(from: a, c1: CGPoint(x: a.x, y: a.y + h),
                                 c2: CGPoint(x: b.x, y: b.y - h), to: b)
        }
    }

    /// Number of leading segments drawn as "reached": the index of the last non-locked node.
    public static func reachedSegmentCount(_ states: [PathNodeState]) -> Int {
        states.lastIndex(where: { $0 != .locked }) ?? 0
    }
}
