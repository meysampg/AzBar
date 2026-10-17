import Testing
import Foundation
@testable import AzBarKit

@Suite struct BadgeCatalogTests {
    @Test func fifteenUniqueEntriesInTableOrder() {
        #expect(BadgeCatalog.all.count == 15)
        #expect(Set(BadgeCatalog.all.map(\.id)).count == 15)
        #expect(BadgeCatalog.all.map(\.id) == BadgeID.allCases)
        for id in BadgeID.allCases { #expect(BadgeCatalog.definition(id).id == id) }
    }

    @Test func thresholds() {
        let expected: [BadgeID: (BadgeMetric, Int)] = [
            .firstLesson: (.lessons, 1), .perfectLesson: (.perfectLessons, 1), .firstGhazal: (.poemsCompleted, 1),
            .tenGhazals: (.poemsCompleted, 10), .firstChallenge: (.challenges, 1), .streak3: (.longestStreak, 3),
            .streak7: (.longestStreak, 7), .streak30: (.longestStreak, 30), .reviews100: (.reviews, 100),
            .reviews500: (.reviews, 500), .mature50: (.matureCouplets, 50), .level10: (.level, 10),
            .nightOwl: (.nightSessions, 1), .earlyBird: (.earlySessions, 1), .falSeeker: (.falOpened, 5),
        ]
        for (id, e) in expected {
            let d = BadgeCatalog.definition(id)
            #expect(d.metric == e.0 && d.target == e.1)
        }
    }

    @Test func newlyUnlockedExcludesAlreadyUnlocked() {
        var s = GamificationSnapshot()
        #expect(BadgeCatalog.newlyUnlocked(snapshot: s, alreadyUnlocked: []).isEmpty)
        s.lessonsCompleted = 1
        s.longestStreak = 7
        #expect(BadgeCatalog.newlyUnlocked(snapshot: s, alreadyUnlocked: []) == [.firstLesson, .streak3, .streak7])
        #expect(BadgeCatalog.newlyUnlocked(snapshot: s, alreadyUnlocked: [.firstLesson, .streak3]) == [.streak7])
        #expect(BadgeCatalog.newlyUnlocked(snapshot: s, alreadyUnlocked: Set(BadgeID.allCases)).isEmpty)
    }

    @Test func progressClamped() {
        let s = GamificationSnapshot(longestStreak: 99, reviewsTotal: 250)
        let p = BadgeCatalog.progress(.reviews500, snapshot: s)
        #expect(p.current == 250 && p.target == 500 && p.fraction == 0.5 && !p.isComplete)
        let done = BadgeCatalog.progress(.streak30, snapshot: s)
        #expect(done.current == 30 && done.fraction == 1 && done.isComplete)
        #expect(BadgeCatalog.progress(.firstLesson, snapshot: GamificationSnapshot()).fraction == 0)
    }

    @Test func snapshotValues() {
        let s = GamificationSnapshot(lessonsCompleted: 1, perfectLessons: 2, poemsCompleted: 3, challengesPassed: 4,
                                     longestStreak: 5, reviewsTotal: 6, matureCouplets: 7, level: 8,
                                     nightSessions: 9, earlySessions: 10, falOpened: 11)
        let metrics: [BadgeMetric] = [.lessons, .perfectLessons, .poemsCompleted, .challenges, .longestStreak,
                                      .reviews, .matureCouplets, .level, .nightSessions, .earlySessions, .falOpened]
        #expect(metrics.map(s.value) == Array(1...11))
        #expect(GamificationSnapshot().value(.level) == 0)
    }

    @Test func sessionTime() {
        for h in [22, 23, 0, 1, 2, 3] { #expect(SessionTime.classify(hour: h) == .night) }
        for h in [4, 5, 6] { #expect(SessionTime.classify(hour: h) == .early) }
        for h in 7...21 { #expect(SessionTime.classify(hour: h) == nil) }
    }
}
