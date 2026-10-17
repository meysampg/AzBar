import Foundation
import SwiftData

/// All reads/writes of memorization progress. Main-actor only.
@MainActor @Observable
final class ProgressStore {
    private let container: ModelContainer
    /// Bump after every write; read in every query method so views invalidate.
    private(set) var revision = 0

    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: Helpers

    private static func dayKey(_ date: Date) -> String {
        DayKey(date, calendar: DayKey.gregorian()).string
    }

    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        (try? context.fetch(descriptor)) ?? []
    }

    private func save() {
        try? context.save()
        revision += 1
    }

    private func cardModel(key: String) -> CoupletCard? {
        var d = FetchDescriptor<CoupletCard>(predicate: #Predicate { $0.key == key })
        d.fetchLimit = 1
        return fetch(d).first
    }

    private func planModel(poemId: Int) -> MemorizationPlan? {
        var d = FetchDescriptor<MemorizationPlan>(predicate: #Predicate { $0.poemId == poemId })
        d.fetchLimit = 1
        return fetch(d).first
    }

    private static func snapshot(_ m: CoupletCard) -> FSRSCard {
        FSRSCard(stability: m.stability, difficulty: m.difficulty, due: m.due, lastReview: m.lastReview,
                 reps: m.reps, lapses: m.lapses, state: CardState(rawValue: m.stateRaw) ?? .new)
    }

    // MARK: Plans

    func plan(poemId: PoemID) -> MemorizationPlan? {
        _ = revision
        return planModel(poemId: poemId)
    }

    func activePlans() -> [MemorizationPlan] {
        _ = revision
        let d = FetchDescriptor<MemorizationPlan>(predicate: #Predicate { !$0.isArchived })
        return fetch(d).sorted { ($0.lastStudiedAt ?? $0.addedAt) > ($1.lastStudiedAt ?? $1.addedAt) }
    }

    func addPlan(poem: Poem, poetName: String) {
        if let existing = planModel(poemId: poem.id) {
            existing.isArchived = false
            existing.title = poem.title
            existing.poetName = poetName
            existing.memorizableCount = poem.memorizableCouplets.count
        } else {
            let first = poem.memorizableCouplets.first?.index ?? -1
            context.insert(MemorizationPlan(poemId: poem.id, poetId: poem.poetId, title: poem.title,
                                            poetName: poetName, memorizableCount: poem.memorizableCouplets.count,
                                            nextCoupletIndex: first))
        }
        save()
    }

    /// Deletes the plan and all of its cards.
    func removePlan(poemId: PoemID) {
        if let p = planModel(poemId: poemId) { context.delete(p) }
        for c in fetch(FetchDescriptor<CoupletCard>(predicate: #Predicate { $0.poemId == poemId })) {
            context.delete(c)
        }
        save()
    }

    func advancePlan(poemId: PoemID, to nextIndex: Int) {
        guard let p = planModel(poemId: poemId) else { return }
        p.nextCoupletIndex = nextIndex
        p.lastStudiedAt = .now
        save()
    }

    // MARK: Cards

    func card(_ key: CoupletKey) -> FSRSCard? {
        _ = revision
        return cardModel(key: key.stringValue).map(Self.snapshot)
    }

    func cards(poemId: PoemID) -> [CoupletKey: FSRSCard] {
        _ = revision
        var out: [CoupletKey: FSRSCard] = [:]
        for m in fetch(FetchDescriptor<CoupletCard>(predicate: #Predicate { $0.poemId == poemId })) {
            out[CoupletKey(poemId: m.poemId, coupletIndex: m.coupletIndex)] = Self.snapshot(m)
        }
        return out
    }

    /// Cards with `due < until`, sorted by (due, poemId, coupletIndex).
    func dueItems(until: Date, limit: Int?) -> [ReviewItem] {
        _ = revision
        var d = FetchDescriptor<CoupletCard>(
            predicate: #Predicate { $0.due < until },
            sortBy: [SortDescriptor(\.due), SortDescriptor(\.poemId), SortDescriptor(\.coupletIndex)])
        if let limit { d.fetchLimit = max(0, limit) }
        return fetch(d).map {
            ReviewItem(key: CoupletKey(poemId: $0.poemId, coupletIndex: $0.coupletIndex), card: Self.snapshot($0))
        }
    }

    func dueCount(until: Date) -> Int {
        _ = revision
        return (try? context.fetchCount(FetchDescriptor<CoupletCard>(predicate: #Predicate { $0.due < until }))) ?? 0
    }

    /// Cards due by the end of the given calendar day (overdue cards included).
    func dueCount(on day: Date) -> Int {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: day)) ?? day
        return dueCount(until: end)
    }

    func nextDueDate() -> Date? {
        _ = revision
        var d = FetchDescriptor<CoupletCard>(sortBy: [SortDescriptor(\.due)])
        d.fetchLimit = 1
        return fetch(d).first?.due
    }

    @discardableResult
    func record(_ rating: Rating, key: CoupletKey, poetId: PoetID, isLearning: Bool,
                scheduler: FSRSScheduler, now: Date = .now) -> SchedulingResult {
        let model: CoupletCard
        if let existing = cardModel(key: key.stringValue) {
            model = existing
        } else {
            model = CoupletCard(key: key.stringValue, poemId: key.poemId, poetId: poetId,
                                coupletIndex: key.coupletIndex, due: now, createdAt: now)
            context.insert(model)
        }
        let before = Self.snapshot(model)
        let result = scheduler.next(before, rating: rating, now: now)
        let c = result.card
        model.stateRaw = c.state.rawValue
        model.stability = c.stability
        model.difficulty = c.difficulty
        model.due = c.due
        model.lastReview = c.lastReview
        model.reps = c.reps
        model.lapses = c.lapses

        context.insert(ReviewLogEntry(cardKey: key.stringValue, ratingRaw: rating.rawValue, reviewedAt: now,
                                      elapsedDays: result.elapsedDays, scheduledDays: result.scheduledDays,
                                      stateBeforeRaw: before.state.rawValue, isLearning: isLearning))

        let dk = Self.dayKey(now)
        var d = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dayKey == dk })
        d.fetchLimit = 1
        let activity: DailyActivity
        if let a = fetch(d).first { activity = a } else {
            activity = DailyActivity(dayKey: dk)
            context.insert(activity)
        }
        if isLearning { activity.learnedCount += 1 } else { activity.reviewCount += 1 }

        if let p = planModel(poemId: key.poemId) { p.lastStudiedAt = now }
        save()
        return result
    }

    func progress(poemId: PoemID, totalMemorizable: Int) -> PoemProgress {
        PoemProgress.compute(cards: Array(cards(poemId: poemId).values), totalMemorizable: totalMemorizable)
    }

    // MARK: Favorites

    func isFavorite(_ poemId: PoemID) -> Bool {
        _ = revision
        var d = FetchDescriptor<FavoritePoem>(predicate: #Predicate { $0.poemId == poemId })
        d.fetchLimit = 1
        return !fetch(d).isEmpty
    }

    func toggleFavorite(poemId: PoemID, poetId: PoetID, title: String) {
        let found = fetch(FetchDescriptor<FavoritePoem>(predicate: #Predicate { $0.poemId == poemId }))
        if found.isEmpty {
            context.insert(FavoritePoem(poemId: poemId, poetId: poetId, title: title))
        } else {
            found.forEach { context.delete($0) }
        }
        save()
    }

    func favorites() -> [FavoritePoem] {
        _ = revision
        return fetch(FetchDescriptor<FavoritePoem>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)]))
    }

    // MARK: Activity and streak

    private func activity(on date: Date) -> DailyActivity? {
        let dk = Self.dayKey(date)
        var d = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dayKey == dk })
        d.fetchLimit = 1
        return fetch(d).first
    }

    func hasActivity(on: Date) -> Bool {
        _ = revision
        return activeDays().contains(DayKey(on, calendar: DayKey.gregorian()))
    }

    func todayActivity() -> (reviews: Int, learned: Int) {
        _ = revision
        guard let a = activity(on: .now) else { return (0, 0) }
        return (a.reviewCount, a.learnedCount)
    }

    /// Consecutive active days (freeze-aware), counting back from today if it is active, else from yesterday.
    func currentStreak(now: Date = .now) -> Int {
        _ = revision
        let cal = DayKey.gregorian()
        return StreakCalculator.current(active: activeDays(), frozen: frozenDays(),
                                        today: DayKey(now, calendar: cal), calendar: cal)
    }

    // MARK: Gamification queries

    /// Lets other stores that write into the shared container invalidate views observing this store.
    func noteExternalChange() {
        revision += 1
    }

    /// Cards that have left the `.new` state.
    func learnedCoupletCount() -> Int {
        _ = revision
        let new = CardState.new.rawValue
        return (try? context.fetchCount(FetchDescriptor<CoupletCard>(predicate: #Predicate { $0.stateRaw != new }))) ?? 0
    }

    /// Cards in `.review` with `stability >= threshold`.
    func matureCoupletCount(threshold: Double = 21) -> Int {
        _ = revision
        let review = CardState.review.rawValue
        return (try? context.fetchCount(FetchDescriptor<CoupletCard>(
            predicate: #Predicate { $0.stateRaw == review && $0.stability >= threshold }))) ?? 0
    }

    /// Review log entries that are not learning entries.
    func reviewCount() -> Int {
        _ = revision
        return (try? context.fetchCount(FetchDescriptor<ReviewLogEntry>(predicate: #Predicate { !$0.isLearning }))) ?? 0
    }

    /// Plans whose memorizable couplets all have a card. Single-beyt poems do not count
    /// (they could otherwise farm the first-ghazal / ten-ghazals badges).
    func completedPoemCount() -> Int {
        _ = revision
        var count = 0
        for plan in fetch(FetchDescriptor<MemorizationPlan>()) where plan.memorizableCount >= 2 {
            let pid = plan.poemId
            let cards = (try? context.fetchCount(FetchDescriptor<CoupletCard>(predicate: #Predicate { $0.poemId == pid }))) ?? 0
            if cards >= plan.memorizableCount { count += 1 }
        }
        return count
    }

    /// Days with `DailyActivity` (review + learned > 0) or `DailyXP` (xp > 0).
    func activeDays() -> Set<DayKey> {
        _ = revision
        var out = Set<DayKey>()
        for a in fetch(FetchDescriptor<DailyActivity>()) where a.reviewCount + a.learnedCount > 0 {
            if let k = DayKey(string: a.dayKey) { out.insert(k) }
        }
        for x in fetch(FetchDescriptor<DailyXP>(predicate: #Predicate { $0.xp > 0 })) {
            if let k = DayKey(string: x.dayKey) { out.insert(k) }
        }
        return out
    }

    /// Days covered by a streak freeze.
    func frozenDays() -> Set<DayKey> {
        _ = revision
        return Set(fetch(FetchDescriptor<FrozenDay>()).compactMap { DayKey(string: $0.dayKey) })
    }
}
