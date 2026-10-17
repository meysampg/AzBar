import Foundation
import SwiftUI
import Testing
import AzBarKit
@testable import AzBar

/// Renders the continuous path map with `ImageRenderer` and writes PNGs for visual review
/// (`tmp/AzBarSnapshots` in the app container).
@MainActor
struct PathSnapshotTests {
    private static func nodes(lessons: Int, reachedLessons: Int) -> [PathNode] {
        var result: [PathNode] = []
        for i in 0..<lessons {
            let state: PathNodeState = i < reachedLessons ? (i % 4 == 3 ? .mastered : .completed)
                : (i == reachedLessons ? .current : .locked)
            result.append(PathNode(id: "L\(i * 2)", kind: .lesson, ordinal: result.count,
                                   coupletIndices: [i * 2, i * 2 + 1], lessonNumber: i + 1, state: state))
            if lessons > 1, i % 2 == 1 || i == lessons - 1 {
                let done = i < reachedLessons
                result.append(PathNode(id: "R\(i * 2 + 1)", kind: .review, ordinal: result.count,
                                       coupletIndices: [i * 2, i * 2 + 1], lessonNumber: nil,
                                       state: done ? .available : .locked))
            }
        }
        if lessons > 1 {
            result.append(PathNode(id: "C", kind: .challenge, ordinal: result.count,
                                   coupletIndices: [0], lessonNumber: nil, state: .locked))
        }
        return result
    }

    private static func ranges(_ nodes: [PathNode]) -> [String: ClosedRange<Int>] {
        var out: [String: ClosedRange<Int>] = [:]
        for n in nodes where n.kind == .lesson {
            if let a = n.coupletIndices.first, let b = n.coupletIndices.last { out[n.id] = (a + 1)...(b + 1) }
        }
        return out
    }

    private static let outputDirectory: URL = {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("AzBarSnapshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let lessons: Int
        let reached: Int
        var testDescription: String { name }
    }

    nonisolated static let scenarios: [Scenario] = [
        Scenario(name: "seven-beyts", lessons: 4, reached: 2),
        Scenario(name: "single-lesson", lessons: 1, reached: 0),
        Scenario(name: "fifteen-lessons", lessons: 15, reached: 6),
    ]

    nonisolated static let cases: [Case] = scenarios.flatMap { s in
        [320.0, 390.0].flatMap { w in [false, true].map { Case(scenario: s, width: w, accessibility: $0) } }
    }

    struct Case: Sendable, CustomTestStringConvertible {
        let scenario: Scenario
        let width: CGFloat
        let accessibility: Bool
        var testDescription: String { "\(scenario.name)-\(Int(width))-\(accessibility ? "ax3" : "large")" }
    }

    @Test(arguments: cases)
    func rendersPath(_ c: Case) throws {
        let scenario = c.scenario, width = c.width
        let type: DynamicTypeSize = c.accessibility ? .accessibility3 : .large
        let nodes = Self.nodes(lessons: scenario.lessons, reachedLessons: scenario.reached)
        let view = PathMapView(nodes: nodes, beytRanges: Self.ranges(nodes), partialNodeId: nil,
                               fixedWidth: width, onStart: { _ in })
            .frame(width: width)
            .background(Theme.Palette.paper)
            .dynamicTypeSize(type)
            .persianRoot()
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let image = try #require(renderer.uiImage)
        let png = try #require(image.pngData())
        let typeName = type == .large ? "large" : "ax3"
        try png.write(to: Self.outputDirectory.appendingPathComponent("path-\(scenario.name)-\(Int(width))-\(typeName).png"))
        #expect(image.size.width >= width - 1)
        #expect(image.size.height > 100)
    }

    @Test func pointsStayInsideBounds() {
        for width in [320.0, 390.0] {
            for diameter in [64.0, 84.0] {
                let ds = (0..<12).map { _ in diameter }
                let geo = PathGeometry(metrics: .init(width: width, diameters: ds, rowHeight: diameter + 120,
                                                      topInset: 60, bottomInset: 70, labelWidth: min(width - 32, 180)))
                for p in geo.points {
                    #expect(p.x - diameter / 2 >= 0 && p.x + diameter / 2 <= width)
                    #expect(p.y - diameter / 2 >= 0 && p.y + diameter / 2 <= geo.size.height)
                }
            }
        }
    }
}
