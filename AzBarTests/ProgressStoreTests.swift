import Testing
import Foundation
import SwiftData
@testable import AzBar

@MainActor
struct ProgressStoreTests {
    let cal = Calendar.current
    let scheduler = FSRSScheduler()

    func makeStore() throws -> ProgressStore {
        let schema = Schema(versionedSchema: AzBarSchemaV1.self)
        let container = try ModelContainer(for: schema, migrationPlan: AzBarMigrationPlan.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ProgressStore(container: container)
    }

    func poem(id: Int = 500) -> Poem {
        func v(_ i: Int, _ pos: Int) -> Verse { Verse(id: id * 10 + i, order: i, position: pos, text: "مصراع \(i)") }
        return Poem(id: id, poetId: 2, categoryId: 24, title: "غزل", fullTitle: "غزل", urlSlug: "g", fullUrl: "/g",
                    couplets: [Couplet(index: 0, kind: .beyt, verses: [v(1, 0), v(2, 1)]),
                               Couplet(index: 1, kind: .beyt, verses: [v(3, 0), v(4, 1)]),
                               Couplet(index: -5, kind: .paragraph, verses: [v(5, -1)])])
    }

    func daysAgo(_ n: Int, hour: Int = 12) -> Date {
        let d = cal.date(byAdding: .day, value: -n, to: cal.startOfDay(for: .now))!
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: d)!
    }

    @Test func recordUpsertsAndLogs() throws {
        let store = try makeStore()
        let key = CoupletKey(poemId: 500, coupletIndex: 0)
        #expect(store.card(key) == nil)
        let now = Date.now
        let r1 = store.record(.good, key: key, poetId: 2, isLearning: true, scheduler: scheduler, now: now)
        let saved = try #require(store.card(key))
        #expect(saved == r1.card)
        #expect(saved.reps == 1 && saved.state == .review)
        let r2 = store.record(.again, key: key, poetId: 2, isLearning: false, scheduler: scheduler, now: now.addingTimeInterval(60))
        #expect(store.card(key) == r2.card)
        #expect(store.card(key)?.reps == 2)
        #expect(store.cards(poemId: 500).count == 1)
        #expect(store.revision >= 2)
        let act = store.todayActivity()
        #expect(act.learned == 1 && act.reviews == 1)
    }

    @Test func dueQueries() throws {
        let store = try makeStore()
        let now = Date.now
        store.record(.again, key: CoupletKey(poemId: 500, coupletIndex: 1), poetId: 2, isLearning: true, scheduler: scheduler, now: now)
        store.record(.good, key: CoupletKey(poemId: 500, coupletIndex: 0), poetId: 2, isLearning: true, scheduler: scheduler, now: now)
        // Again -> due in 10 min; Good -> 3 days.
        #expect(store.dueCount(until: now.addingTimeInterval(3600)) == 1)
        #expect(store.dueCount(until: now.addingTimeInterval(10 * 86400)) == 2)
        let items = store.dueItems(until: now.addingTimeInterval(10 * 86400), limit: nil)
        #expect(items.map(\.key.coupletIndex) == [1, 0])
        #expect(store.dueItems(until: now.addingTimeInterval(10 * 86400), limit: 1).count == 1)
        #expect(store.nextDueDate() == items.first?.card.due)
        let in3 = cal.date(byAdding: .day, value: 3, to: now)!
        #expect(store.dueCount(on: in3) == 2)
    }

    @Test func plansAndCascade() throws {
        let store = try makeStore()
        let p = poem()
        store.addPlan(poem: p, poetName: "حافظ")
        let plan = try #require(store.plan(poemId: 500))
        #expect(plan.memorizableCount == 2 && plan.nextCoupletIndex == 0 && !plan.isArchived)
        store.addPlan(poem: p, poetName: "حافظ")
        #expect(store.activePlans().count == 1)
        store.advancePlan(poemId: 500, to: 1)
        #expect(store.plan(poemId: 500)?.nextCoupletIndex == 1)
        store.record(.good, key: CoupletKey(poemId: 500, coupletIndex: 0), poetId: 2, isLearning: true, scheduler: scheduler)
        let prog = store.progress(poemId: 500, totalMemorizable: 2)
        #expect(prog.total == 2 && prog.notStarted == 1 && prog.young == 1)
        store.removePlan(poemId: 500)
        #expect(store.plan(poemId: 500) == nil)
        #expect(store.cards(poemId: 500).isEmpty)
        #expect(store.activePlans().isEmpty)
    }

    @Test func favorites() throws {
        let store = try makeStore()
        #expect(!store.isFavorite(500))
        store.toggleFavorite(poemId: 500, poetId: 2, title: "غزل")
        #expect(store.isFavorite(500) && store.favorites().count == 1)
        store.toggleFavorite(poemId: 500, poetId: 2, title: "غزل")
        #expect(!store.isFavorite(500) && store.favorites().isEmpty)
    }

    func rec(_ store: ProgressStore, at date: Date, idx: Int = 0) {
        store.record(.good, key: CoupletKey(poemId: 500, coupletIndex: idx), poetId: 2, isLearning: false, scheduler: scheduler, now: date)
    }

    @Test func streakTodayOnly() throws {
        let store = try makeStore()
        #expect(store.currentStreak() == 0)
        rec(store, at: daysAgo(0, hour: 8))
        #expect(store.currentStreak() == 1)
        #expect(store.hasActivity(on: .now))
    }

    @Test func streakWithGap() throws {
        let store = try makeStore()
        rec(store, at: daysAgo(0)); rec(store, at: daysAgo(1)); rec(store, at: daysAgo(3))
        #expect(store.currentStreak() == 2)
    }

    @Test func streakContinuesFromYesterday() throws {
        let store = try makeStore()
        rec(store, at: daysAgo(1)); rec(store, at: daysAgo(2)); rec(store, at: daysAgo(3))
        #expect(store.currentStreak() == 3)
        #expect(!store.hasActivity(on: .now))
        let old = try makeStore()
        rec(old, at: daysAgo(2))
        #expect(old.currentStreak() == 0)
    }
}
