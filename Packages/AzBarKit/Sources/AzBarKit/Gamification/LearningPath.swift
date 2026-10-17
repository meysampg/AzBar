import Foundation

public enum PathNodeKind: String, Sendable, Hashable { case lesson, review, challenge }

public enum PathNodeState: Int, Sendable, Hashable, Comparable {
    case locked, available, current, completed, mastered

    public static func < (l: PathNodeState, r: PathNodeState) -> Bool { l.rawValue < r.rawValue }
}

public struct PathNode: Identifiable, Sendable, Hashable {
    /// `"L\(firstIdx)"`, `"R\(lastIdxCovered)"` or `"C"`.
    public let id: String
    public let kind: PathNodeKind
    /// Position in the node list, 0-based.
    public let ordinal: Int
    public let coupletIndices: [Int]
    /// 1-based, lessons only.
    public let lessonNumber: Int?
    public var state: PathNodeState

    public init(id: String, kind: PathNodeKind, ordinal: Int, coupletIndices: [Int],
                lessonNumber: Int?, state: PathNodeState = .locked) {
        self.id = id
        self.kind = kind
        self.ordinal = ordinal
        self.coupletIndices = coupletIndices
        self.lessonNumber = lessonNumber
        self.state = state
    }
}

public struct LearningPathConfig: Sendable, Hashable {
    public var lessonSize: Int
    public var reviewEvery: Int
    public var masteryStability: Double

    /// `lessonSize` is clamped to 1...5.
    public init(lessonSize: Int, reviewEvery: Int = 2, masteryStability: Double = 21) {
        self.lessonSize = min(max(lessonSize, 1), 5)
        self.reviewEvery = max(1, reviewEvery)
        self.masteryStability = masteryStability
    }
}

public enum LearningPath {
    /// Lessons are consecutive chunks; a review follows every `reviewEvery` lessons and a trailing
    /// partial group; the challenge is last. All states are `.locked`.
    public static func layout(memorizableIndices: [Int], config: LearningPathConfig) -> [PathNode] {
        guard !memorizableIndices.isEmpty else { return [] }
        // A single lesson needs no review and no challenge.
        if memorizableIndices.count <= config.lessonSize {
            return [PathNode(id: "L\(memorizableIndices[0])", kind: .lesson, ordinal: 0,
                             coupletIndices: memorizableIndices, lessonNumber: 1)]
        }
        var nodes: [PathNode] = []
        var sinceReview: [[Int]] = []
        var lessonNumber = 0

        func flushReview() {
            guard let lastLesson = sinceReview.last, let lastIdx = lastLesson.last else { return }
            nodes.append(PathNode(id: "R\(lastIdx)", kind: .review, ordinal: nodes.count,
                                  coupletIndices: sinceReview.flatMap { $0 }, lessonNumber: nil))
            sinceReview = []
        }

        var i = 0
        while i < memorizableIndices.count {
            let chunk = Array(memorizableIndices[i..<min(i + config.lessonSize, memorizableIndices.count)])
            i += config.lessonSize
            lessonNumber += 1
            nodes.append(PathNode(id: "L\(chunk[0])", kind: .lesson, ordinal: nodes.count,
                                  coupletIndices: chunk, lessonNumber: lessonNumber))
            sinceReview.append(chunk)
            if sinceReview.count == config.reviewEvery { flushReview() }
        }
        flushReview()
        nodes.append(PathNode(id: "C", kind: .challenge, ordinal: nodes.count,
                              coupletIndices: memorizableIndices, lessonNumber: nil))
        return nodes
    }

    public static func build(memorizableIndices: [Int], cards: [Int: FSRSCard], completedNodeIds: Set<String>,
                             config: LearningPathConfig) -> [PathNode] {
        var nodes = layout(memorizableIndices: memorizableIndices, config: config)
        func started(_ idx: Int) -> Bool { (cards[idx]?.state ?? .new) != .new }
        func allMastered(_ n: PathNode) -> Bool {
            n.coupletIndices.allSatisfy { isMastered(cards[$0], threshold: config.masteryStability) }
        }

        var lessonDone: [String: Bool] = [:]
        var foundCurrent = false
        for i in nodes.indices where nodes[i].kind == .lesson {
            let done = nodes[i].coupletIndices.allSatisfy(started)
            lessonDone[nodes[i].id] = done
            if done {
                nodes[i].state = allMastered(nodes[i]) ? .mastered : .completed
            } else if !foundCurrent {
                nodes[i].state = .current
                foundCurrent = true
            } else {
                nodes[i].state = .locked
            }
        }
        let doneIndices = Set(nodes.filter { $0.kind == .lesson && lessonDone[$0.id] == true }.flatMap(\.coupletIndices))
        for i in nodes.indices where nodes[i].kind != .lesson {
            let unlocked = nodes[i].coupletIndices.allSatisfy { doneIndices.contains($0) }
            if !unlocked {
                nodes[i].state = .locked
            } else if completedNodeIds.contains(nodes[i].id) {
                nodes[i].state = allMastered(nodes[i]) ? .mastered : .completed
            } else {
                nodes[i].state = .available
            }
        }
        return nodes
    }

    /// The first lesson that is not completed.
    public static func currentNode(in nodes: [PathNode]) -> PathNode? {
        nodes.first { $0.state == .current }
    }

    public static func isMastered(_ card: FSRSCard?, threshold: Double) -> Bool {
        guard let card else { return false }
        return card.state == .review && card.stability >= threshold
    }
}
