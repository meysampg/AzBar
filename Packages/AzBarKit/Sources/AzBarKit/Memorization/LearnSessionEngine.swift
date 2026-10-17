// STUB (WP2): replace implementation, keep signatures
import Foundation

public enum LearnStep: Hashable, Sendable {
    case read, cloze(level: Int), firstLetters, recallSecond, recallChain
}

public struct LearnItem: Hashable, Sendable {
    public var coupletIndex: Int
    public var isRetry: Bool

    public init(coupletIndex: Int, isRetry: Bool) {
        self.coupletIndex = coupletIndex
        self.isRetry = isRetry
    }
}

public struct LearnRatingEvent: Sendable {
    public var coupletIndex: Int
    public var rating: Rating

    public init(coupletIndex: Int, rating: Rating) {
        self.coupletIndex = coupletIndex
        self.rating = rating
    }
}

public struct LearnSessionEngine: Sendable {
    private let poem: Poem
    public private(set) var queue: [LearnItem]
    public private(set) var itemPosition: Int = 0
    public private(set) var stepPosition: Int = 0
    public private(set) var isRevealed: Bool = false
    private var rated: Int = 0

    public init(poem: Poem, coupletIndices: [Int]) {
        self.poem = poem
        self.queue = coupletIndices.map { LearnItem(coupletIndex: $0, isRetry: false) }
    }

    public var currentItem: LearnItem? { queue.indices.contains(itemPosition) ? queue[itemPosition] : nil }

    public func steps(for item: LearnItem) -> [LearnStep] {
        let couplet = poem.couplet(at: item.coupletIndex)
        let isSingle = couplet?.kind == .single
        if item.isRetry { return isSingle ? [.cloze(level: 2), .cloze(level: 3)] : [.cloze(level: 2), .recallSecond] }
        var s: [LearnStep] = [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3)]
        if isSingle { s.append(.firstLetters) } else { s.append(contentsOf: [.firstLetters, .recallSecond]) }
        if poem.previousMemorizable(before: item.coupletIndex) != nil { s.append(.recallChain) }
        return s
    }

    public var currentStep: LearnStep? {
        guard let item = currentItem else { return nil }
        let s = steps(for: item)
        return s.indices.contains(stepPosition) ? s[stepPosition] : nil
    }

    public var isRecallStep: Bool {
        switch currentStep {
        case .recallSecond, .recallChain: return true
        default: return isLastStep
        }
    }

    private var isLastStep: Bool {
        guard let item = currentItem else { return false }
        return stepPosition == steps(for: item).count - 1
    }

    public var awaitsRating: Bool { isRevealed && isLastStep }
    public var isFinished: Bool { currentItem == nil }

    public var progress: Double {
        let total = queue.reduce(0) { $0 + steps(for: $1).count }
        guard total > 0 else { return 1 }
        let done = queue.prefix(itemPosition).reduce(0) { $0 + steps(for: $1).count } + (isFinished ? 0 : stepPosition)
        return min(1, Double(done) / Double(total))
    }

    public var learnedCount: Int { rated }

    public mutating func advance() {
        guard let item = currentItem else { return }
        if stepPosition < steps(for: item).count - 1 {
            stepPosition += 1
            isRevealed = false
        }
    }

    public mutating func reveal() { isRevealed = true }

    @discardableResult
    public mutating func rate(_ r: Rating) -> LearnRatingEvent {
        guard let item = currentItem else { return LearnRatingEvent(coupletIndex: -1, rating: r) }
        if r == .again && !item.isRetry { queue.append(LearnItem(coupletIndex: item.coupletIndex, isRetry: true)) }
        if !item.isRetry && r != .again { rated += 1 }
        itemPosition += 1
        stepPosition = 0
        isRevealed = false
        return LearnRatingEvent(coupletIndex: item.coupletIndex, rating: r)
    }
}
