import Testing
import Foundation
@testable import AzBarKit

@Suite struct LearningPathTests {
    let config = LearningPathConfig(lessonSize: 2)
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func ids(_ n: [PathNode]) -> [String] { n.map(\.id) }

    func card(_ state: CardState = .learning, stability: Double = 1) -> FSRSCard {
        FSRSCard(stability: stability, difficulty: 5, due: t0, lastReview: t0, reps: 1, lapses: 0, state: state)
    }

    func cards(_ idx: [Int], state: CardState = .learning, stability: Double = 1) -> [Int: FSRSCard] {
        Dictionary(uniqueKeysWithValues: idx.map { ($0, card(state, stability: stability)) })
    }

    @Test func layouts() {
        #expect(ids(LearningPath.layout(memorizableIndices: Array(0...6), config: config)) == ["L0", "L2", "R3", "L4", "L6", "R6", "C"])
        #expect(ids(LearningPath.layout(memorizableIndices: Array(0...4), config: config)) == ["L0", "L2", "R3", "L4", "R4", "C"])
        #expect(ids(LearningPath.layout(memorizableIndices: [0, 1, 2, 3], config: config)) == ["L0", "L2", "R3", "C"])
        #expect(ids(LearningPath.layout(memorizableIndices: [5, 7, 8, 12, 20], config: config)) == ["L5", "L8", "R12", "L20", "R20", "C"])
        #expect(LearningPath.layout(memorizableIndices: [], config: config).isEmpty)
    }

    @Test func layoutDetails() {
        let n = LearningPath.layout(memorizableIndices: Array(0...6), config: config)
        #expect(n.map(\.ordinal) == Array(0..<7))
        #expect(n.map(\.lessonNumber) == [1, 2, nil, 3, 4, nil, nil])
        #expect(n[2].coupletIndices == [0, 1, 2, 3])
        #expect(n[5].coupletIndices == [4, 5, 6])
        #expect(n[6].coupletIndices == Array(0...6) && n[6].kind == .challenge)
        #expect(n.allSatisfy { $0.state == .locked })
    }

    @Test func lessonSizeClamped() {
        #expect(LearningPathConfig(lessonSize: 0).lessonSize == 1)
        #expect(LearningPathConfig(lessonSize: 9).lessonSize == 5)
        let one = LearningPath.layout(memorizableIndices: [0, 1, 2], config: LearningPathConfig(lessonSize: 1))
        #expect(ids(one) == ["L0", "L1", "R1", "L2", "R2", "C"])
    }

    func build(_ idx: [Int] = Array(0...6), cards c: [Int: FSRSCard] = [:], done: Set<String> = []) -> [PathNode] {
        LearningPath.build(memorizableIndices: idx, cards: c, completedNodeIds: done, config: config)
    }

    @Test func noCards() {
        let n = build()
        #expect(n.map(\.state) == [.current, .locked, .locked, .locked, .locked, .locked, .locked])
        #expect(LearningPath.currentNode(in: n)?.id == "L0")
    }

    @Test func progressThroughPath() {
        var n = build(cards: cards([0, 1]))
        #expect(n[0].state == .completed && n[1].state == .current && n[2].state == .locked)
        #expect(LearningPath.currentNode(in: n)?.id == "L2")
        n = build(cards: cards([0, 1, 2, 3]))
        #expect(n[2].id == "R3" && n[2].state == .available)
        #expect(n[3].state == .current)
        n = build(cards: cards([0, 1, 2, 3]), done: ["R3"])
        #expect(n[2].state == .completed)
        // A partly learned lesson is still the current one.
        n = build(cards: cards([0, 1, 2]))
        #expect(n[1].state == .current)
    }

    @Test func masteryAndChallenge() {
        let mature = cards(Array(0...6), state: .review, stability: 30)
        var n = build(cards: mature)
        #expect(n.filter { $0.kind == .lesson }.allSatisfy { $0.state == .mastered })
        #expect(n.last?.state == .available)
        #expect(LearningPath.currentNode(in: n) == nil)
        n = build(cards: mature, done: ["R3", "R6", "C"])
        #expect(n.allSatisfy { $0.state == .mastered })
        let young = cards(Array(0...6), state: .review, stability: 5)
        n = build(cards: young, done: ["C"])
        #expect(n.last?.state == .completed)
        #expect(n.first?.state == .completed)
    }

    @Test func challengeLockedUntilAllLessonsDone() {
        let n = build(cards: cards(Array(0...5)))
        #expect(n.last?.state == .locked)
        #expect(n[5].state == .locked)   // R6 needs lesson L6
    }

    @Test func masteryRule() {
        #expect(LearningPath.isMastered(card(.review, stability: 21), threshold: 21))
        #expect(!LearningPath.isMastered(card(.review, stability: 20.9), threshold: 21))
        #expect(!LearningPath.isMastered(card(.learning, stability: 99), threshold: 21))
        #expect(!LearningPath.isMastered(nil, threshold: 21))
        #expect(PathNodeState.locked < .mastered && PathNodeState.current < .completed)
    }
}
