// STUB (WP2): replace implementation, keep signatures
import Foundation

public struct FSRSScheduler: Sendable {
    public let parameters: FSRSParameters
    public let calendar: Calendar

    public init(parameters: FSRSParameters = FSRSParameters(), calendar: Calendar = .current) {
        self.parameters = parameters
        self.calendar = calendar
    }

    public func retrievability(_ c: FSRSCard, at now: Date) -> Double {
        guard let last = c.lastReview, c.stability > 0 else { return 1 }
        let t = max(0, now.timeIntervalSince(last) / 86400)
        return pow(1 + (19.0 / 81.0) * t / c.stability, -0.5)
    }

    /// Stub: always schedules the card one day ahead with unchanged memory state.
    public func next(_ c: FSRSCard, rating: Rating, now: Date) -> SchedulingResult {
        var card = c
        card.reps += 1
        card.lastReview = now
        if rating == .again {
            card.lapses += c.state == .review ? 1 : 0
            card.state = c.state == .new ? .learning : .relearning
            card.due = now.addingTimeInterval(Double(parameters.againStepMinutes) * 60)
            return SchedulingResult(card: card, elapsedDays: 0, scheduledDays: 0)
        }
        card.state = .review
        card.stability = max(card.stability, 1)
        card.difficulty = max(card.difficulty, 5)
        card.due = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        return SchedulingResult(card: card, elapsedDays: 0, scheduledDays: 1)
    }

    public func preview(_ c: FSRSCard, now: Date) -> [Rating: SchedulingResult] {
        Dictionary(uniqueKeysWithValues: Rating.allCases.map { ($0, next(c, rating: $0, now: now)) })
    }
}
