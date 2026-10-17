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
    private var finished: Set<Int> = []
    private var peakProgress: Double = 0

    public init(poem: Poem, coupletIndices: [Int]) {
        self.poem = poem
        self.queue = coupletIndices.map { LearnItem(coupletIndex: $0, isRetry: false) }
    }

    public var currentItem: LearnItem? { queue.indices.contains(itemPosition) ? queue[itemPosition] : nil }

    public func steps(for item: LearnItem) -> [LearnStep] {
        let isSingle = poem.couplet(at: item.coupletIndex)?.kind == .single
        if item.isRetry { return isSingle ? [.cloze(level: 2), .cloze(level: 3)] : [.cloze(level: 2), .recallSecond] }
        let hasChain = poem.previousMemorizable(before: item.coupletIndex) != nil
        var s: [LearnStep] = [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3)]
        if isSingle {
            // Without a chain the final step is cloze(3), treated as the recall step.
            if hasChain { s.append(contentsOf: [.firstLetters, .recallChain]) }
        } else {
            s.append(contentsOf: [.firstLetters, .recallSecond])
            if hasChain { s.append(.recallChain) }
        }
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
        case nil: return false
        default: return isLastStep
        }
    }

    private var isLastStep: Bool {
        guard let item = currentItem else { return false }
        return stepPosition == steps(for: item).count - 1
    }

    public var awaitsRating: Bool { isRevealed && isLastStep }
    public var isFinished: Bool { currentItem == nil }

    /// Completed steps / total steps (including retries). Never decreases.
    public var progress: Double { max(peakProgress, rawProgress) }

    private var rawProgress: Double {
        let total = queue.reduce(0) { $0 + steps(for: $1).count }
        guard total > 0 else { return 1 }
        if isFinished { return 1 }
        let done = queue.prefix(itemPosition).reduce(0) { $0 + steps(for: $1).count } + stepPosition
        return min(1, Double(done) / Double(total))
    }

    /// Number of couplets whose learning (including a possible retry) is complete.
    public var learnedCount: Int { finished.count }

    /// Moves to the next step. Valid when not on a recall step, or on a revealed non-final recall step.
    public mutating func advance() {
        guard let item = currentItem else { return }
        guard !isRecallStep || (isRevealed && !awaitsRating) else { return }
        if stepPosition < steps(for: item).count - 1 {
            stepPosition += 1
            isRevealed = false
            peakProgress = max(peakProgress, rawProgress)
        }
    }

    public mutating func reveal() { isRevealed = true }

    @discardableResult
    public mutating func rate(_ r: Rating) -> LearnRatingEvent {
        guard let item = currentItem else { return LearnRatingEvent(coupletIndex: -1, rating: r) }
        if r == .again && !item.isRetry {
            queue.append(LearnItem(coupletIndex: item.coupletIndex, isRetry: true))
        } else {
            finished.insert(item.coupletIndex)
        }
        peakProgress = max(peakProgress, rawProgress)
        itemPosition += 1
        stepPosition = 0
        isRevealed = false
        peakProgress = max(peakProgress, rawProgress)
        return LearnRatingEvent(coupletIndex: item.coupletIndex, rating: r)
    }
}
