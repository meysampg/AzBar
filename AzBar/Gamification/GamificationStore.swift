// STUB (P-B): implement, keep signatures
import Foundation
import SwiftData

/// XP, levels, streak freezes, badges and the learning path. Main-actor only.
/// P0 ships the contract with default values; package B implements it.
@MainActor @Observable
final class GamificationStore {
    private let container: ModelContainer
    private let progress: ProgressStore
    private let settings: AppSettings

    /// Bump after every write; read in every query so views invalidate.
    private(set) var revision = 0
    /// Badges waiting for the toast overlay, oldest first.
    private(set) var pendingToasts: [BadgeID] = []

    init(container: ModelContainer, progress: ProgressStore, settings: AppSettings) {
        self.container = container
        self.progress = progress
        self.settings = settings
    }

    func dismissToast() {
        if !pendingToasts.isEmpty { pendingToasts.removeFirst() }
    }

    // MARK: Reads

    var totalXP: Int { _ = revision; return 0 }
    var levelInfo: LevelInfo { LevelCurve.info(totalXP: totalXP) }
    var todayXP: Int { _ = revision; return 0 }
    var dailyGoal: Int { settings.dailyXPGoal }
    var freezesAvailable: Int { _ = revision; return 0 }
    var longestStreak: Int { _ = revision; return 0 }

    func xp(on day: Date) -> Int {
        _ = revision
        _ = day
        return 0
    }

    /// Seven entries, oldest first, ending on the given day.
    func weekXP(endingOn: Date = .now) -> [(day: DayKey, xp: Int)] {
        _ = revision
        let cal = DayKey.gregorian()
        let end = DayKey(endingOn, calendar: cal)
        return (0..<7).map { (end.adding(days: $0 - 6, calendar: cal), 0) }
    }

    func unlocked() -> [BadgeID: Date] {
        _ = revision
        return [:]
    }

    func snapshot() -> GamificationSnapshot {
        _ = revision
        return GamificationSnapshot(level: levelInfo.level)
    }

    // MARK: Path

    /// Fixed per poem on first use; falls back to the setting.
    func lessonSize(poemId: PoemID) -> Int {
        _ = revision
        _ = poemId
        return min(max(settings.newCoupletsPerSession, 1), 5)
    }

    func completedNodeIds(poemId: PoemID) -> Set<String> {
        _ = revision
        _ = poemId
        return []
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

    /// Call when a learn, practice, challenge or review session starts (captures level/goal/streak "before").
    func beginSession(now: Date = .now) {
        _ = now
    }

    /// Adds XP to today; returns the total awarded.
    @discardableResult
    func award(_ awards: [XPAward], now: Date = .now) -> Int {
        _ = now
        return awards.reduce(0) { $0 + $1.amount }
    }

    func completeLesson(_ outcome: LessonOutcome) -> SessionReward {
        SessionReward(xpEarned: 0,
                      accuracy: outcome.gradedCount > 0
                        ? LessonScoring.accuracy(graded: outcome.gradedCount, mistakes: outcome.mistakes) : nil,
                      celebrations: [])
    }

    func completeReviewSession(cardsReviewed: Int, now: Date = .now) -> SessionReward {
        _ = (cardsReviewed, now)
        return SessionReward(xpEarned: 0, accuracy: nil, celebrations: [])
    }

    func recordFalOpened(now: Date = .now) {
        _ = now
    }

    /// Run at launch and on `scenePhase == .active`: backfill, weekly freeze, auto-freeze, badge check.
    func reconcile(now: Date = .now) {
        _ = now
    }
}
