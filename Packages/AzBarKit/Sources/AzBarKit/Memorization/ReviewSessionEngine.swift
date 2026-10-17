import Foundation

public enum ReviewPromptMode: Sendable { case recallSecond, recallChain, recallFromHints }

public struct ReviewItem: Sendable, Hashable {
    public var key: CoupletKey
    public var card: FSRSCard

    public init(key: CoupletKey, card: FSRSCard) {
        self.key = key
        self.card = card
    }
}

public struct ReviewSessionEngine: Sendable {
    private var items: [ReviewItem]
    private var requeues: [CoupletKey: Int] = [:]
    private let scheduler: FSRSScheduler
    public private(set) var position: Int = 0
    public private(set) var isRevealed: Bool = false
    public private(set) var counts: [Rating: Int] = [:]
    public let total: Int

    public init(items: [ReviewItem], scheduler: FSRSScheduler) {
        self.items = items
        self.scheduler = scheduler
        self.total = items.count
    }

    public var current: ReviewItem? { items.indices.contains(position) ? items[position] : nil }
    public var isFinished: Bool { current == nil }

    public func mode(for item: ReviewItem, poem: Poem) -> ReviewPromptMode {
        let idx = item.key.coupletIndex
        let c = poem.couplet(at: idx)
        let hasPrev = poem.previousMemorizable(before: idx) != nil
        if hasPrev && item.card.reps % 2 == 1 { return .recallChain }
        if c?.kind == .beyt { return .recallSecond }
        if hasPrev { return .recallChain }
        return .recallFromHints
    }

    public mutating func reveal() { isRevealed = true }

    @discardableResult
    public mutating func rate(_ r: Rating, now: Date) -> SchedulingResult {
        guard let item = current else {
            return SchedulingResult(card: FSRSCard.new(now: now), elapsedDays: 0, scheduledDays: 0)
        }
        let result = scheduler.next(item.card, rating: r, now: now)
        counts[r, default: 0] += 1
        if r == .again, requeues[item.key, default: 0] < 2 {
            requeues[item.key, default: 0] += 1
            let at = min(position + 3, items.count)
            items.insert(ReviewItem(key: item.key, card: result.card), at: at)
        }
        position += 1
        isRevealed = false
        return result
    }
}
