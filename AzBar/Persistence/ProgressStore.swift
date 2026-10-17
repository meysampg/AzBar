// STUB (WP2): replace implementation, keep signatures
import Foundation
import SwiftData

@MainActor @Observable
final class ProgressStore {
    private let container: ModelContainer
    /// Bump after every write; read in every query method so views invalidate.
    private(set) var revision = 0

    init(container: ModelContainer) {
        self.container = container
    }

    func plan(poemId: PoemID) -> MemorizationPlan? { _ = revision; return nil }
    func activePlans() -> [MemorizationPlan] { _ = revision; return [] }
    func addPlan(poem: Poem, poetName: String) {}
    func removePlan(poemId: PoemID) {}

    func card(_ key: CoupletKey) -> FSRSCard? { _ = revision; return nil }
    func cards(poemId: PoemID) -> [CoupletKey: FSRSCard] { _ = revision; return [:] }
    func dueItems(until: Date, limit: Int?) -> [ReviewItem] { _ = revision; return [] }
    func dueCount(until: Date) -> Int { _ = revision; return 0 }
    func dueCount(on day: Date) -> Int { _ = revision; return 0 }
    func nextDueDate() -> Date? { _ = revision; return nil }

    @discardableResult
    func record(_ rating: Rating, key: CoupletKey, poetId: PoetID, isLearning: Bool,
                scheduler: FSRSScheduler, now: Date = .now) -> SchedulingResult {
        let result = scheduler.next(FSRSCard.new(now: now), rating: rating, now: now)
        return result
    }

    func advancePlan(poemId: PoemID, to nextIndex: Int) {}
    func progress(poemId: PoemID, totalMemorizable: Int) -> PoemProgress {
        _ = revision
        return PoemProgress.compute(cards: [], totalMemorizable: totalMemorizable)
    }

    func isFavorite(_ poemId: PoemID) -> Bool { _ = revision; return false }
    func toggleFavorite(poemId: PoemID, poetId: PoetID, title: String) {}
    func favorites() -> [FavoritePoem] { _ = revision; return [] }

    func currentStreak(now: Date = .now) -> Int { _ = revision; return 0 }
    func hasActivity(on: Date) -> Bool { _ = revision; return false }
    func todayActivity() -> (reviews: Int, learned: Int) { _ = revision; return (0, 0) }
}
