import Foundation

public struct PoemProgress: Sendable, Hashable {
    public var total: Int
    public var notStarted: Int
    public var learning: Int
    public var young: Int
    public var mature: Int

    public init(total: Int, notStarted: Int, learning: Int, young: Int, mature: Int) {
        self.total = total
        self.notStarted = notStarted
        self.learning = learning
        self.young = young
        self.mature = mature
    }

    public static let empty = PoemProgress(total: 0, notStarted: 0, learning: 0, young: 0, mature: 0)

    public var fraction: Double {
        guard total > 0 else { return 0 }
        return (0.25 * Double(learning) + 0.6 * Double(young) + 1.0 * Double(mature)) / Double(total)
    }

    public static func compute(cards: [FSRSCard], totalMemorizable: Int) -> PoemProgress {
        var learning = 0, young = 0, mature = 0
        for c in cards {
            switch c.state {
            case .new: break
            case .learning, .relearning: learning += 1
            case .review: if c.stability >= 21 { mature += 1 } else { young += 1 }
            }
        }
        let started = learning + young + mature
        return PoemProgress(total: totalMemorizable, notStarted: max(0, totalMemorizable - started),
                            learning: learning, young: young, mature: mature)
    }
}
