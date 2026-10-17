import Testing
import Foundation
import SwiftData
@testable import AzBar

@MainActor
struct GamificationStoreTests {
    let cal = DayKey.gregorian()
    let scheduler = FSRSScheduler()

    struct Env {
        let container: ModelContainer
        let progress: ProgressStore
        let settings: AppSettings
        let store: GamificationStore
    }

    func makeEnv() throws -> Env {
        let schema = Schema(versionedSchema: AzBarSchemaV2.self)
        let container = try ModelContainer(for: schema, migrationPlan: AzBarMigrationPlan.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let suite = try #require(UserDefaults(suiteName: "azbar.gamification.\(UUID().uuidString)"))
        let settings = AppSettings(defaults: suite)
        let progress = ProgressStore(container: container)
        return Env(container: container, progress: progress, settings: settings,
                   store: GamificationStore(container: container, progress: progress, settings: settings))
    }

    func at(daysAgo n: Int, hour: Int = 12) -> Date {
        let d = cal.date(byAdding: .day, value: -n, to: cal.startOfDay(for: .now))!
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: d)!
    }

    func record(_ env: Env, at date: Date, idx: Int = 0, isLearning: Bool = false) {
        env.progress.record(.good, key: CoupletKey(poemId: 500, coupletIndex: idx), poetId: 2,
                            isLearning: isLearning, scheduler: scheduler, now: date)
    }

    func outcome(kind: LessonKind = .lesson, node: String? = "L0", graded: Int = 4, mistakes: Int = 0,
                 passed: Bool = true, at date: Date = .now) -> LessonOutcome {
        LessonOutcome(poemId: 500, nodeId: node, kind: kind, gradedCount: graded, mistakes: mistakes,
                      newCouplets: 2, passed: passed, finishedAt: date)
    }

    @Test func awardAccumulatesToday() throws {
        let env = try makeEnv()
        let s = env.store
        #expect(s.totalXP == 0 && s.todayXP == 0)
        #expect(s.award([XPAward(.exerciseCorrect, 2), XPAward(.coupletLearned, 3)]) == 5)
        #expect(s.award([XPAward(.exerciseCorrect, 2)]) == 2)
        #expect(s.todayXP == 7 && s.totalXP == 7)
        #expect(s.award([]) == 0)
        #expect(s.weekXP().count == 7)
        #expect(s.weekXP().last?.xp == 7 && s.weekXP().first?.xp == 0)
        #expect(env.progress.activeDays().contains(DayKey(.now, calendar: cal)))
    }

    @Test func crossingFortyXPCelebratesLevelUpAndGoal() throws {
        let env = try makeEnv()
        let s = env.store
        s.beginSession()
        s.award([XPAward(.lessonCompleted, 40)])
        let reward = s.completeReviewSession(cardsReviewed: 0)
        #expect(s.levelInfo.level == 2)
        #expect(reward.xpEarned == 40)
        #expect(reward.celebrations.contains(.levelUp(level: 2)))
        #expect(reward.celebrations.contains(.dailyGoal(goal: 20)))
        #expect(reward.celebrations.contains(.streak(days: 1)))
        // Level-up grants a freeze.
        #expect(s.freezesAvailable == 1)
    }

    @Test func completeLessonWritesRecordAndBadges() throws {
        let env = try makeEnv()
        let s = env.store
        s.beginSession()
        s.award([XPAward(.exerciseCorrect, 2)])
        let reward = s.completeLesson(outcome(node: "L0"))
        #expect(s.completedNodeIds(poemId: 500).contains("L0"))
        // 2 (exercise) + 10 (lesson) + 5 (perfect).
        #expect(reward.xpEarned == 17)
        #expect(reward.accuracy == 1)
        #expect(reward.celebrations.contains(.badge(.firstLesson)))
        #expect(reward.celebrations.contains(.badge(.perfectLesson)))
        #expect(s.unlocked()[.firstLesson] != nil)
        #expect(s.pendingToasts.isEmpty)

        // Practice re-runs and failed challenges do not complete nodes.
        s.beginSession()
        _ = s.completeLesson(outcome(kind: .practice, node: "L0-p"))
        _ = s.completeLesson(outcome(kind: .challenge, node: "C", graded: 10, mistakes: 5, passed: false))
        #expect(s.completedNodeIds(poemId: 500) == ["L0"])
        _ = s.completeLesson(outcome(kind: .challenge, node: "C", graded: 10, mistakes: 0, passed: true))
        #expect(s.completedNodeIds(poemId: 500) == ["L0", "C"])
        #expect(s.unlocked()[.firstChallenge] != nil)
    }

    @Test func nightLessonUnlocksNightOwl() throws {
        let env = try makeEnv()
        let reward = env.store.completeLesson(outcome(at: at(daysAgo: 0, hour: 23)))
        #expect(reward.celebrations.contains(.badge(.nightOwl)))
        #expect(env.store.unlocked()[.earlyBird] == nil)
    }

    @Test func reviewSessionBonusNeedsFiveCards() throws {
        let env = try makeEnv()
        env.store.beginSession()
        #expect(env.store.completeReviewSession(cardsReviewed: 4).xpEarned == 0)
        env.store.beginSession()
        #expect(env.store.completeReviewSession(cardsReviewed: 5).xpEarned == 5)
    }

    @Test func freezeBridgesMissedYesterday() throws {
        let env = try makeEnv()
        record(env, at: at(daysAgo: 3)); record(env, at: at(daysAgo: 2))
        #expect(env.progress.currentStreak() == 0)
        env.store.reconcile()
        #expect(env.progress.currentStreak() == 2)
        #expect(env.progress.frozenDays() == [DayKey(at(daysAgo: 1), calendar: cal)])
        #expect(env.store.freezesAvailable == 0)
        env.store.reconcile()
        #expect(env.progress.frozenDays().count == 1)
    }

    @Test func freezeNotUsedWhenGapTooLarge() throws {
        let env = try makeEnv()
        record(env, at: at(daysAgo: 5)); record(env, at: at(daysAgo: 4))
        env.store.reconcile()
        #expect(env.progress.frozenDays().isEmpty)
        #expect(env.store.freezesAvailable == 1)
    }

    @Test func weeklyFreezeGrantIsCappedAtTwo() throws {
        let env = try makeEnv()
        let s = env.store
        s.reconcile(now: at(daysAgo: 0))
        #expect(s.freezesAvailable == 1)
        s.reconcile(now: at(daysAgo: 0))
        #expect(s.freezesAvailable == 1)
        let week2 = cal.date(byAdding: .day, value: 7, to: at(daysAgo: 0))!
        s.reconcile(now: week2)
        #expect(s.freezesAvailable == 2)
        let week3 = cal.date(byAdding: .day, value: 14, to: at(daysAgo: 0))!
        s.reconcile(now: week3)
        #expect(s.freezesAvailable == 2)
    }

    @Test func backfillRunsOnceAndIsSilent() throws {
        let env = try makeEnv()
        for i in 0..<3 { record(env, at: at(daysAgo: i), idx: i % 2, isLearning: i == 0) }
        record(env, at: at(daysAgo: 0), idx: 1, isLearning: false)
        // Cards: 2 learned; review logs not learning: 3.
        env.store.reconcile()
        #expect(env.store.totalXP == 8 * 2 + 3 * 3)
        #expect(env.store.longestStreak == 3)
        #expect(env.store.unlocked()[.streak3] != nil)
        #expect(env.store.pendingToasts.isEmpty)
        env.store.reconcile()
        #expect(env.store.totalXP == 8 * 2 + 3 * 3)
        #expect(env.store.pendingToasts.isEmpty)
        let state = try env.container.mainContext.fetch(FetchDescriptor<GamificationState>())
        #expect(state.count == 1 && state[0].didBackfill)
    }

    @Test func falOpenedFiveTimesQueuesToast() throws {
        let env = try makeEnv()
        env.store.reconcile()
        for _ in 0..<4 { env.store.recordFalOpened() }
        #expect(env.store.pendingToasts.isEmpty)
        env.store.recordFalOpened()
        #expect(env.store.pendingToasts == [.falSeeker])
        env.store.dismissToast()
        #expect(env.store.pendingToasts.isEmpty)
        // Seen after dismissal: a later reconcile does not re-queue it.
        env.store.reconcile()
        #expect(env.store.pendingToasts.isEmpty)
    }

    @Test func unseenBadgesRequeueOnReconcile() throws {
        let env = try makeEnv()
        env.store.reconcile()
        for _ in 0..<5 { env.store.recordFalOpened() }
        #expect(env.store.pendingToasts == [.falSeeker])
        env.store.reconcile()
        #expect(env.store.pendingToasts == [.falSeeker])
    }

    @Test func lessonSizeIsFixedPerPoem() throws {
        let env = try makeEnv()
        env.settings.newCoupletsPerSession = 2
        #expect(env.store.lessonSize(poemId: 500) == 2)
        env.settings.newCoupletsPerSession = 4
        #expect(env.store.lessonSize(poemId: 500) == 2)
        #expect(env.store.lessonSize(poemId: 501) == 4)
    }

    @Test func pathReflectsCardsAndCompletedNodes() throws {
        let env = try makeEnv()
        func v(_ i: Int, _ pos: Int) -> Verse { Verse(id: 5000 + i, order: i, position: pos, text: "مصراع \(i)") }
        let couplets = (0..<4).map { Couplet(index: $0, kind: .beyt, verses: [v($0 * 2, 0), v($0 * 2 + 1, 1)]) }
        let poem = Poem(id: 500, poetId: 2, categoryId: 24, title: "غزل", fullTitle: "غزل", urlSlug: "g",
                        fullUrl: "/g", couplets: couplets)
        env.settings.newCoupletsPerSession = 2
        var nodes = env.store.path(for: poem)
        #expect(nodes.map(\.id) == ["L0", "L2", "R3", "C"])
        #expect(nodes.first?.state == .current)
        for i in 0..<4 { record(env, at: .now, idx: i, isLearning: true) }
        nodes = env.store.path(for: poem)
        #expect(nodes.first { $0.id == "R3" }?.state == .available)
        _ = env.store.completeLesson(outcome(kind: .practice, node: "R3"))
        nodes = env.store.path(for: poem)
        #expect((nodes.first { $0.id == "R3" }?.state ?? .locked) >= .completed)
    }
}
