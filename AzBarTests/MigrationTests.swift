import Testing
import Foundation
import SwiftData
@testable import AzBar

/// V1 -> V2 lightweight migration on a real on-disk store (the user's iPhone already has V1 data).
@MainActor
struct MigrationTests {
    private func makeDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: "azbar-migration-\(UUID().uuidString)",
                                                                    directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Creates and populates a V1 store, then releases the container so the file is closed.
    private func seedV1(at url: URL, due: Date, reviewedAt: Date) throws {
        let schema = Schema(versionedSchema: AzBarSchemaV1.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let context = container.mainContext
        context.insert(AzBarSchemaV1.CoupletCard(key: "500:0", poemId: 500, poetId: 2, coupletIndex: 0, stateRaw: 2,
                                                  stability: 30, difficulty: 5, due: due, lastReview: reviewedAt,
                                                  reps: 4, lapses: 1, createdAt: reviewedAt))
        context.insert(AzBarSchemaV1.CoupletCard(key: "500:1", poemId: 500, poetId: 2, coupletIndex: 1, stateRaw: 1,
                                                  stability: 1, difficulty: 6, due: due, reps: 1))
        context.insert(AzBarSchemaV1.MemorizationPlan(poemId: 500, poetId: 2, title: "غزل", poetName: "حافظ",
                                                       memorizableCount: 2, nextCoupletIndex: 2,
                                                       addedAt: reviewedAt, lastStudiedAt: reviewedAt))
        context.insert(AzBarSchemaV1.ReviewLogEntry(cardKey: "500:0", ratingRaw: 3, reviewedAt: reviewedAt,
                                                     elapsedDays: 2, scheduledDays: 5, stateBeforeRaw: 2,
                                                     isLearning: false))
        context.insert(AzBarSchemaV1.ReviewLogEntry(cardKey: "500:1", ratingRaw: 3, reviewedAt: reviewedAt,
                                                     elapsedDays: 0, scheduledDays: 1, stateBeforeRaw: 0,
                                                     isLearning: true))
        context.insert(AzBarSchemaV1.FavoritePoem(poemId: 500, poetId: 2, title: "غزل"))
        context.insert(AzBarSchemaV1.DailyActivity(dayKey: DayKey(reviewedAt, calendar: DayKey.gregorian()).string,
                                                    reviewCount: 3, learnedCount: 2))
        try context.save()
    }

    private func openV2(at url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: AzBarSchemaV2.self)
        return try ModelContainer(for: schema, migrationPlan: AzBarMigrationPlan.self,
                                  configurations: ModelConfiguration(schema: schema, url: url))
    }

    @Test func v1DataSurvivesMigrationToV2() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "azbar.store")
        let reviewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let due = Date(timeIntervalSince1970: 1_700_500_000)
        try seedV1(at: url, due: due, reviewedAt: reviewedAt)

        let container = try openV2(at: url)
        let ctx = container.mainContext

        let cards = try ctx.fetch(FetchDescriptor<CoupletCard>(sortBy: [SortDescriptor(\.coupletIndex)]))
        #expect(cards.count == 2)
        let c0 = try #require(cards.first)
        #expect(c0.key == "500:0" && c0.poemId == 500 && c0.poetId == 2 && c0.stateRaw == 2)
        #expect(c0.stability == 30 && c0.difficulty == 5 && c0.reps == 4 && c0.lapses == 1)
        #expect(c0.due == due && c0.lastReview == reviewedAt && c0.createdAt == reviewedAt)

        let plan = try #require(try ctx.fetch(FetchDescriptor<MemorizationPlan>()).first)
        #expect(plan.poemId == 500 && plan.title == "غزل" && plan.poetName == "حافظ")
        #expect(plan.memorizableCount == 2 && plan.nextCoupletIndex == 2 && !plan.isArchived)
        #expect(plan.lastStudiedAt == reviewedAt)

        let logs = try ctx.fetch(FetchDescriptor<ReviewLogEntry>())
        #expect(logs.count == 2 && logs.filter(\.isLearning).count == 1)
        #expect(try ctx.fetch(FetchDescriptor<FavoritePoem>()).count == 1)
        let activity = try #require(try ctx.fetch(FetchDescriptor<DailyActivity>()).first)
        #expect(activity.reviewCount == 3 && activity.learnedCount == 2)

        // New entities exist and are empty.
        #expect(try ctx.fetch(FetchDescriptor<DailyXP>()).isEmpty)
        #expect(try ctx.fetch(FetchDescriptor<LessonRecord>()).isEmpty)
        #expect(try ctx.fetch(FetchDescriptor<AchievementRecord>()).isEmpty)
        #expect(try ctx.fetch(FetchDescriptor<FrozenDay>()).isEmpty)
        #expect(try ctx.fetch(FetchDescriptor<GamificationState>()).isEmpty)
        #expect(try ctx.fetch(FetchDescriptor<PoemPathState>()).isEmpty)
    }

    @Test func migratedStoreBackfillsGamificationAndStaysWritable() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "azbar.store")
        let now = Date.now
        try seedV1(at: url, due: now, reviewedAt: now)

        let container = try openV2(at: url)
        let progress = ProgressStore(container: container)
        let suite = try #require(UserDefaults(suiteName: "azbar.migration.\(UUID().uuidString)"))
        let gamification = GamificationStore(container: container, progress: progress, settings: AppSettings(defaults: suite))

        gamification.reconcile(now: now)
        // 2 learned cards * 8 + 1 non-learning review log * 3.
        #expect(gamification.totalXP == 19)
        #expect(gamification.pendingToasts.isEmpty)
        #expect(progress.learnedCoupletCount() == 2)
        #expect(progress.currentStreak(now: now) == 1)

        // Existing data is untouched by the backfill, and new writes succeed.
        gamification.reconcile(now: now)
        #expect(gamification.totalXP == 19)
        #expect(gamification.award([XPAward(.lessonCompleted, 10)], now: now) == 10)
        #expect(gamification.totalXP == 29)
        #expect(progress.cards(poemId: 500).count == 2)
        #expect(progress.plan(poemId: 500)?.memorizableCount == 2)
    }

    @Test func v2StoreReopensWithoutReMigrating() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "azbar.store")
        try seedV1(at: url, due: .now, reviewedAt: .now)
        do {
            let first = try openV2(at: url)
            first.mainContext.insert(DailyXP(dayKey: "2026-10-17", xp: 12))
            try first.mainContext.save()
        }
        let second = try openV2(at: url)
        #expect(try second.mainContext.fetch(FetchDescriptor<DailyXP>()).first?.xp == 12)
        #expect(try second.mainContext.fetch(FetchDescriptor<CoupletCard>()).count == 2)
    }
}
