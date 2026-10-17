import SwiftUI

enum ReviewQueueWindow {
    /// Cards due before the end of today are part of today's review.
    static func endOfToday(calendar: Calendar = .current, now: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
            ?? now.addingTimeInterval(86_400)
    }
}

@MainActor @Observable
final class ReviewSessionModel {
    enum Phase { case loading, empty, session, summary }

    private(set) var phase: Phase = .loading
    private(set) var engine: ReviewSessionEngine?
    private(set) var previewDate: Date = .now
    private(set) var streak = 0
    private(set) var reward: SessionReward?
    /// XP awarded for ratings during this session.
    private(set) var sessionXP = 0

    private var poems: [PoemID: Poem] = [:]
    private var progress: ProgressStore?
    private var settings: AppSettings?
    private var gamification: GamificationStore?
    private var didLoad = false

    func load(content: ContentRepository, progress: ProgressStore, settings: AppSettings,
              gamification: GamificationStore) async {
        guard !didLoad else { return }
        didLoad = true
        self.progress = progress
        self.settings = settings
        self.gamification = gamification
        let items = progress.dueItems(until: ReviewQueueWindow.endOfToday(), limit: settings.dailyReviewLimit)
        let plans = Dictionary(progress.activePlans().map { ($0.poemId, $0.poetId) }, uniquingKeysWith: { a, _ in a })
        var usable: [ReviewItem] = []
        for item in items {
            let poemId = item.key.poemId
            if poems[poemId] == nil {
                poems[poemId] = await loadPoem(poemId, preferredPoet: plans[poemId], content: content)
            }
            if let poem = poems[poemId], poem.couplet(at: item.key.coupletIndex) != nil {
                usable.append(item)
            }
        }
        guard !usable.isEmpty else {
            phase = .empty
            return
        }
        let scheduler = FSRSScheduler(parameters: settings.fsrsParameters)
        engine = ReviewSessionEngine(items: usable, scheduler: scheduler)
        previewDate = .now
        gamification.beginSession()
        phase = .session
    }

    private func loadPoem(_ id: PoemID, preferredPoet: PoetID?, content: ContentRepository) async -> Poem? {
        var candidates: [PoetID] = []
        if let preferredPoet { candidates.append(preferredPoet) }
        candidates += content.catalog.enabledPoets.map(\.id).filter { $0 != preferredPoet }
        for poetId in candidates {
            if let poem = try? await content.poem(id, poetId: poetId) { return poem }
        }
        return nil
    }

    // MARK: Derived state

    var current: ReviewItem? { engine?.current }
    var isRevealed: Bool { engine?.isRevealed ?? false }
    var total: Int { engine?.total ?? 0 }
    var counts: [Rating: Int] { engine?.counts ?? [:] }
    /// Total XP shown on the summary.
    var totalXP: Int { max(reward?.xpEarned ?? 0, sessionXP) }
    var reviewedCount: Int { counts.values.reduce(0, +) }

    var position: Int {
        guard let engine else { return 0 }
        return min(engine.position + 1, max(engine.total, 1))
    }

    var progressValue: Double {
        guard let engine, engine.total > 0 else { return 0 }
        return min(1, Double(engine.position) / Double(engine.total))
    }

    var poem: Poem? { current.flatMap { poems[$0.key.poemId] } }
    var couplet: Couplet? {
        guard let current, let poem else { return nil }
        return poem.couplet(at: current.key.coupletIndex)
    }
    var previousCouplet: Couplet? {
        guard let current, let poem else { return nil }
        return poem.previousMemorizable(before: current.key.coupletIndex)
    }
    var mode: ReviewPromptMode? {
        guard let engine, let current, let poem else { return nil }
        return engine.mode(for: current, poem: poem)
    }

    var cloze: ClozeEngine? {
        guard let poem, let couplet else { return nil }
        return ClozeEngine(poemId: poem.id, couplet: couplet)
    }

    var contextTitle: String {
        guard let poem, let current else { return "" }
        return "\(poem.title) · بیت \((poem.memorizableCouplets.firstIndex { $0.index == current.key.coupletIndex }.map { $0 + 1 } ?? current.key.coupletIndex + 1).fa)"
    }

    var heading: String {
        switch mode {
        case .recallSecond: "مصراع دوم را به یاد آور"
        case .recallChain: "بیت بعد چیست؟"
        case .recallFromHints: "بیت را با کمک حرف نخست به یاد آور"
        case nil: ""
        }
    }

    var stepKey: String {
        guard let engine, let current else { return "none" }
        return "\(engine.position)-\(current.key.stringValue)"
    }

    func ratingPreviews() -> [Rating: SchedulingResult]? {
        guard let current, let settings else { return nil }
        return FSRSScheduler(parameters: settings.fsrsParameters).preview(current.card, now: previewDate)
    }

    // MARK: Actions

    func reveal() {
        previewDate = .now
        engine?.reveal()
    }

    func rate(_ rating: Rating) {
        guard let progress, let settings, let item = engine?.current else { return }
        let now = Date.now
        let poetId = poems[item.key.poemId]?.poetId ?? 0
        engine?.rate(rating, now: now)
        progress.record(rating, key: item.key, poetId: poetId, isLearning: false,
                        scheduler: FSRSScheduler(parameters: settings.fsrsParameters), now: now)
        sessionXP += gamification?.award([XPAward(.reviewRated, XPTable.reviewRated(rating))])
            ?? XPTable.reviewRated(rating)
        if engine?.isFinished == true {
            reward = gamification?.completeReviewSession(cardsReviewed: reviewedCount)
            streak = progress.currentStreak()
            phase = .summary
        }
    }
}
