import Testing
import Foundation
import CoreGraphics
@testable import AzBarKit

@Suite struct PathGeometryTests {
    func metrics(width: Double = 390, n: Int = 12, labelWidth: Double = 180) -> PathGeometry.Metrics {
        .init(width: width, diameters: Array(repeating: 64, count: n), rowHeight: 150, topInset: 60,
              bottomInset: 80, labelWidth: labelWidth)
    }

    @Test func pointsAndBounds() {
        let m = metrics()
        let g = PathGeometry(metrics: m)
        #expect(g.points.count == 12)
        #expect(g.points[0].x == 195)
        for p in g.points {
            #expect(p.x >= 32 + 12 && p.x <= 390 - 32 - 12)
        }
        for i in 1..<g.points.count { #expect(g.points[i].y > g.points[i - 1].y) }
        #expect(g.size.width == 390)
        #expect(g.size.height == g.points.last!.y + 32 + 80)
    }

    @Test func segmentsAreContinuous() {
        let g = PathGeometry(metrics: metrics(n: 8))
        let s = g.segments
        #expect(s.count == 7)
        for i in s.indices {
            #expect(s[i].from == g.points[i] && s[i].to == g.points[i + 1])
            if i + 1 < s.count { #expect(s[i].to == s[i + 1].from) }
            #expect(s[i].c1.x == s[i].from.x && s[i].c2.x == s[i].to.x)
        }
    }

    @Test func narrowWidthIsStraight() {
        let g = PathGeometry(metrics: metrics(width: 120))
        #expect(g.amplitude == 0)
        #expect(Set(g.points.map(\.x)) == [60])
    }

    @Test func emptyAndSingle() {
        #expect(PathGeometry(metrics: metrics(n: 0)).segments.isEmpty)
        #expect(PathGeometry(metrics: metrics(n: 1)).segments.isEmpty)
    }

    @Test func waveAndReached() {
        #expect(PathGeometry.wave(0) == 0)
        #expect(PathGeometry.reachedSegmentCount([.completed, .available, .current, .locked, .locked]) == 2)
        #expect(PathGeometry.reachedSegmentCount([.locked, .locked]) == 0)
        #expect(PathGeometry.reachedSegmentCount([]) == 0)
    }
}
