import Foundation
import SwiftData

/// XP, levels, streak freezes, badges and the learning path. Main-actor only.
/// Shares the main context with `ProgressStore`; reads never write (except the idempotent lazy
/// `PoemPathState` row), writes bump `revision`.
@MainActor @Observable
final class GamificationStore {
    private let container: ModelContainer
    private let progress: ProgressStore
    private let settings: AppSettings

    /// Bump after every write; read in every query so views invalidate.
    private(set) var revision = 0
    /// Badges waiting for the toast overlay, oldest first.
    private(set) var pendingToasts: [BadgeID] = []

    private struct SessionBefore {
        var level: Int
        var goalMet: Bool
        var activeToday: Bool
    }

    private var sessionBefore: SessionBefore?
    private var sessionXP = 0

    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer, progress: ProgressStore, settings: AppSettings) {
        self.container = container
        self.progress = progress
        self.settings = settings
    }

    func dismissToast() {
        guard !pendingToasts.isEmpty else { return }
        let id = pendingToasts.removeFirst()
        let raw = id.rawValue
        var d = FetchDescriptor<AchievementRecord>(predicate: #Predicate { $0.badgeId == raw })
        d.fetchLimit = 1
        if let rec = fetch(d).first, !rec.isSeen {
            rec.isSeen = true
            save()
        }
    }

    // MARK: Helpers

    private static var maxFreezes: Int { 2 }

    private var calendar: Calendar { DayKey.gregorian() }

    private func key(_ date: Date) -> String { DayKey(date, calendar: calendar).string }

    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        (try? context.fetch(descriptor)) ?? []
    }

    private func save() {
        try? context.save()
        revision += 1
        progress.noteExternalChange()
    }

    private func stateModel() -> GamificationState? {
        var d = FetchDescriptor<GamificationState>(predicate: #Predicate { $0.key == "main" })
        d.fetchLimit = 1
        return fetch(d).first
    }

    private func ensureState() -> GamificationState {
        if let s = stateModel() { return s }
        let s = GamificationState()
        context.insert(s)
        return s
    }

    private func dailyModel(_ dayKey: String) -> DailyXP? {
        var d = FetchDescriptor<DailyXP>(predicate: #Predicate { $0.dayKey == dayKey })
        d.fetchLimit = 1
        return fetch(d).first
    }

    private func ensureDaily(_ dayKey: String) -> DailyXP {
        if let d = dailyModel(dayKey) { return d }
        let d = DailyXP(dayKey: dayKey, goal: settings.dailyXPGoal)
        context.insert(d)
        return d
    }

    /// Persian week key "yyyy-ww", weeks start on Saturday.
    static func weekKey(_ date: Date) -> String {
        var c = Calendar(identifier: .persian)
        c.firstWeekday = 7
        c.minimumDaysInFirstWeek = 1
        return String(format: "%04d-%02d", c.component(.yearForWeekOfYear, from: date),
                      c.component(.weekOfYear, from: date))
    }

    // MARK: Reads

    var totalXP: Int {
        _ = revision
        let legacy = stateModel()?.legacyXP ?? 0
        return legacy + fetch(FetchDescriptor<DailyXP>()).reduce(0) { $0 + $1.xp }
    }

    var levelInfo: LevelInfo { LevelCurve.info(totalXP: totalXP) }

    var todayXP: Int { xp(on: .now) }

    var dailyGoal: Int { settings.dailyXPGoal }

    var freezesAvailable: Int {
        _ = revision
        return stateModel()?.freezesAvailable ?? 0
    }

    var longestStreak: Int {
        _ = revision
        return max(stateModel()?.longestStreak ?? 0, progress.currentStreak())
    }

    func xp(on day: Date) -> Int {
        _ = revision
        return dailyModel(key(day))?.xp ?? 0
    }

    /// Seven entries, oldest first, ending on the given day.
    func weekXP(endingOn: Date = .now) -> [(day: DayKey, xp: Int)] {
        _ = revision
        let cal = calendar
        let end = DayKey(endingOn, calendar: cal)
        return (0..<7).map { i in
            let k = end.adding(days: i - 6, calendar: cal)
            return (k, dailyModel(k.string)?.xp ?? 0)
        }
    }

    func unlocked() -> [BadgeID: Date] {
        _ = revision
        var out: [BadgeID: Date] = [:]
        for r in fetch(FetchDescriptor<AchievementRecord>()) {
            if let id = BadgeID(rawValue: r.badgeId) { out[id] = r.unlockedAt }
        }
        return out
    }

    func snapshot() -> GamificationSnapshot {
        _ = revision
        let state = stateModel()
        let lessonRaw = LessonKind.lesson.rawValue
        let challengeRaw = LessonKind.challenge.rawValue
        let lessons = (try? context.fetchCount(FetchDescriptor<LessonRecord>(
            predicate: #Predicate { $0.kindRaw == lessonRaw && $0.passed }))) ?? 0
        let challenges = (try? context.fetchCount(FetchDescriptor<LessonRecord>(
            predicate: #Predicate { $0.kindRaw == challengeRaw && $0.passed }))) ?? 0
        let perfect = fetch(FetchDescriptor<DailyXP>()).reduce(0) { $0 + $1.perfectLessons }
        return GamificationSnapshot(
            lessonsCompleted: lessons,
            perfectLessons: perfect,
            poemsCompleted: progress.completedPoemCount(),
            challengesPassed: challenges,
            longestStreak: max(state?.longestStreak ?? 0, progress.currentStreak()),
            reviewsTotal: progress.reviewCount(),
            matureCouplets: progress.matureCoupletCount(),
            level: levelInfo.level,
            nightSessions: state?.nightSessions ?? 0,
            earlySessions: state?.earlySessions ?? 0,
            falOpened: state?.falOpenCount ?? 0)
    }

    // MARK: Path

    /// Fixed per poem on first use; falls back to the setting.
    func lessonSize(poemId: PoemID) -> Int {
        _ = revision
        var d = FetchDescriptor<PoemPathState>(predicate: #Predicate { $0.poemId == poemId })
        d.fetchLimit = 1
        if let existing = fetch(d).first { return existing.lessonSize }
        let size = min(max(settings.newCoupletsPerSession, 1), 5)
        // Idempotent lazy creation; deliberately does not bump `revision` (the value never changes).
        context.insert(PoemPathState(poemId: poemId, lessonSize: size))
        try? context.save()
        return size
    }

    func completedNodeIds(poemId: PoemID) -> Set<String> {
        _ = revision
        let records = fetch(FetchDescriptor<LessonRecord>(predicate: #Predicate { $0.poemId == poemId && $0.passed }))
        return Set(records.map(\.nodeId).filter { !$0.isEmpty && !$0.hasSuffix("-p") })
    }

    func path(for poem: Poem) -> [PathNode] {
        _ = revision
        let cards = progress.cards(poemId: poem.id)
        var byIndex: [Int: FSRSCard] = [:]
        for (key, card) in cards { byIndex[key.coupletIndex] = card }
        return LearningPath.build(
            memorizableIndices: poem.memorizableCouplets.map(\.index),
            cards: byIndex,
            completedNodeIds: completedNodeIds(poemId: poem.id),
            config: LearningPathConfig(lessonSize: lessonSize(poemId: poem.id)))
    }

    // MARK: Writes

    private func captureBefore(_ now: Date) -> SessionBefore {
        let k = DayKey(now, calendar: calendar)
        return SessionBefore(level: levelInfo.level,
                             goalMet: xp(on: now) >= settings.dailyXPGoal,
                             activeToday: progress.activeDays().contains(k))
    }

    /// Call when a learn, practice, challenge or review session starts (captures level/goal/streak "before").
    func beginSession(now: Date = .now) {
        sessionBefore = captureBefore(now)
        sessionXP = 0
    }

    /// Adds XP to today; returns the total awarded.
    @discardableResult
    func award(_ awards: [XPAward], now: Date = .now) -> Int {
        let total = awards.reduce(0) { $0 + max(0, $1.amount) }
        guard total > 0 else { return 0 }
        let levelBefore = levelInfo.level
        let row = ensureDaily(key(now))
        let goal = settings.dailyXPGoal
        let before = row.xp
        row.xp += total
        row.goal = goal
        if row.goalMetAt == nil, DailyGoal.justMet(before: before, after: row.xp, goal: goal) {
            row.goalMetAt = now
        }
        sessionXP += total
        save()
        let gained = levelInfo.level - levelBefore
        if gained > 0 { addFreezes(gained) }
        return total
    }

    private func addFreezes(_ n: Int) {
        let s = ensureState()
        s.freezesAvailable = min(Self.maxFreezes, s.freezesAvailable + n)
        save()
    }

    func completeLesson(_ outcome: LessonOutcome) -> SessionReward {
        let before = sessionBefore ?? captureBefore(outcome.finishedAt)
        let day = key(outcome.finishedAt)
        let passed = outcome.kind == .challenge ? outcome.passed : true

        award(XPTable.completionAwards(kind: outcome.kind, gradedCount: outcome.gradedCount,
                                       mistakes: outcome.mistakes, passed: outcome.passed),
              now: outcome.finishedAt)
        let xpEarned = sessionXP

        context.insert(LessonRecord(poemId: outcome.poemId, nodeId: outcome.nodeId ?? "",
                                    kindRaw: outcome.kind.rawValue, completedAt: outcome.finishedAt, dayKey: day,
                                    gradedCount: outcome.gradedCount, mistakes: outcome.mistakes,
                                    xp: xpEarned, passed: passed))
        if passed {
            let row = ensureDaily(day)
            row.lessons += 1
            if outcome.kind == .lesson, outcome.gradedCount >= 2, outcome.mistakes == 0 { row.perfectLessons += 1 }
            noteSessionTime(outcome.finishedAt)
        }
        save()

        let reward = finish(before: before, xpEarned: xpEarned, now: outcome.finishedAt,
                            accuracy: outcome.gradedCount > 0
                                ? LessonScoring.accuracy(graded: outcome.gradedCount, mistakes: outcome.mistakes) : nil)
        return reward
    }

    func completeReviewSession(cardsReviewed: Int, now: Date = .now) -> SessionReward {
        let before = sessionBefore ?? captureBefore(now)
        award(XPTable.reviewSessionAwards(cardsReviewed: cardsReviewed), now: now)
        let xpEarned = sessionXP
        if cardsReviewed > 0 { noteSessionTime(now) }
        save()
        return finish(before: before, xpEarned: xpEarned, now: now, accuracy: nil)
    }

    func recordFalOpened(now: Date = .now) {
        let s = ensureState()
        s.falOpenCount += 1
        let new = unlockBadges(seen: false, now: now)
        pendingToasts.append(contentsOf: new)
        save()
    }

    private func noteSessionTime(_ date: Date) {
        let hour = calendar.component(.hour, from: date)
        let s = ensureState()
        switch SessionTime.classify(hour: hour) {
        case .night: s.nightSessions += 1
        case .early: s.earlySessions += 1
        case nil: break
        }
    }

    /// Updates the longest streak, unlocks badges (shown as celebrations) and builds the reward.
    private func finish(before: SessionBefore, xpEarned: Int, now: Date, accuracy: Double?) -> SessionReward {
        refreshLongestStreak(now: now)
        var celebrations: [Celebration] = []
        let goal = settings.dailyXPGoal
        if !before.goalMet, xp(on: now) >= goal { celebrations.append(.dailyGoal(goal: goal)) }
        if !before.activeToday, progress.activeDays().contains(DayKey(now, calendar: calendar)) {
            celebrations.append(.streak(days: progress.currentStreak(now: now)))
        }
        let level = levelInfo.level
        if level > before.level { celebrations.append(.levelUp(level: level)) }
        for b in unlockBadges(seen: true, now: now) { celebrations.append(.badge(b)) }
        save()
        sessionBefore = nil
        sessionXP = 0
        return SessionReward(xpEarned: xpEarned, accuracy: accuracy, celebrations: celebrations)
    }

    private func refreshLongestStreak(now: Date) {
        let s = ensureState()
        let current = progress.currentStreak(now: now)
        if current > s.longestStreak { s.longestStreak = current }
    }

    /// Inserts records for newly earned badges and returns them. Caller saves.
    private func unlockBadges(seen: Bool, now: Date) -> [BadgeID] {
        let existing = Set(fetch(FetchDescriptor<AchievementRecord>()).compactMap { BadgeID(rawValue: $0.badgeId) })
        let new = BadgeCatalog.newlyUnlocked(snapshot: snapshot(), alreadyUnlocked: existing)
        for id in new { context.insert(AchievementRecord(badgeId: id.rawValue, unlockedAt: now, isSeen: seen)) }
        return new
    }

    /// Run at launch and on `scenePhase == .active`: backfill, weekly freeze, auto-freeze, badge check.
    func reconcile(now: Date = .now) {
        let cal = calendar
        let today = DayKey(now, calendar: cal)
        let week = Self.weekKey(now)

        let s = ensureState()
        var silentBadges = false
        if !s.didBackfill {
            s.legacyXP = XPTable.legacyXP(learnedCards: progress.learnedCoupletCount(),
                                          reviewLogs: progress.reviewCount())
            s.freezesAvailable = 1
            s.lastFreezeGrantWeek = week
            s.longestStreak = StreakCalculator.longest(active: progress.activeDays(),
                                                       frozen: progress.frozenDays(), calendar: cal)
            s.didBackfill = true
            silentBadges = true
            try? context.save()
        } else if s.lastFreezeGrantWeek != week {
            s.freezesAvailable = min(Self.maxFreezes, s.freezesAvailable + 1)
            s.lastFreezeGrantWeek = week
        }

        let plan = StreakCalculator.freezePlan(active: progress.activeDays(), frozen: progress.frozenDays(),
                                               today: today, available: s.freezesAvailable, calendar: cal)
        for day in plan {
            context.insert(FrozenDay(dayKey: day.string, appliedAt: now))
        }
        s.freezesAvailable = max(0, s.freezesAvailable - plan.count)
        try? context.save()

        refreshLongestStreak(now: now)
        _ = unlockBadges(seen: silentBadges, now: now)
        save()

        let unseen = fetch(FetchDescriptor<AchievementRecord>(predicate: #Predicate { !$0.isSeen }))
            .sorted { $0.unlockedAt < $1.unlockedAt }
            .compactMap { BadgeID(rawValue: $0.badgeId) }
        for id in unseen where !pendingToasts.contains(id) { pendingToasts.append(id) }
    }
}
