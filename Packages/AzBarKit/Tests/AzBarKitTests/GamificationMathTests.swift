import Testing
import Foundation
@testable import AzBarKit

@Suite struct GamificationMathTests {
    let cal = DayKey.gregorian(timeZone: TimeZone(identifier: "UTC")!)

    // MARK: DayKey

    @Test func dayKeyRoundTrip() {
        let k = DayKey(year: 2026, month: 3, day: 9)
        #expect(k.string == "2026-03-09")
        #expect(k.description == "2026-03-09")
        #expect(DayKey(string: "2026-03-09") == k)
        #expect(DayKey(string: "2026-3-9") == nil)
        #expect(DayKey(string: "garbage") == nil)
        #expect(DayKey(string: "2026-13-01") == nil)
        let date = k.startDate(in: cal)
        #expect(DayKey(date, calendar: cal) == k)
    }

    @Test func dayKeyRollover() {
        #expect(DayKey(year: 2026, month: 1, day: 31).adding(days: 1, calendar: cal) == DayKey(year: 2026, month: 2, day: 1))
        #expect(DayKey(year: 2025, month: 12, day: 31).adding(days: 1, calendar: cal) == DayKey(year: 2026, month: 1, day: 1))
        #expect(DayKey(year: 2026, month: 1, day: 1).adding(days: -1, calendar: cal) == DayKey(year: 2025, month: 12, day: 31))
        #expect(DayKey(year: 2024, month: 2, day: 28).adding(days: 1, calendar: cal) == DayKey(year: 2024, month: 2, day: 29))
        #expect(DayKey(year: 2026, month: 5, day: 10).adding(days: 0, calendar: cal) == DayKey(year: 2026, month: 5, day: 10))
    }

    @Test func dayKeyDSTSafe() {
        var tehran = Calendar(identifier: .gregorian)
        tehran.timeZone = TimeZone(identifier: "America/New_York")!
        // 2026-03-08 is the US spring-forward day.
        let k = DayKey(year: 2026, month: 3, day: 8)
        #expect(k.adding(days: 1, calendar: tehran) == DayKey(year: 2026, month: 3, day: 9))
        #expect(k.adding(days: -1, calendar: tehran) == DayKey(year: 2026, month: 3, day: 7))
    }

    @Test func dayKeyOrderingAndCodable() throws {
        let a = DayKey(year: 2025, month: 12, day: 31)
        let b = DayKey(year: 2026, month: 1, day: 1)
        #expect(a < b && !(b < a))
        #expect([b, a].sorted() == [a, b])
        let data = try JSONEncoder().encode(a)
        #expect(try JSONDecoder().decode(DayKey.self, from: data) == a)
    }

    // MARK: XP

    @Test func completionAwards() {
        func total(_ kind: LessonKind, _ g: Int, _ m: Int, _ p: Bool = true) -> Int {
            XPTable.completionAwards(kind: kind, gradedCount: g, mistakes: m, passed: p).map(\.amount).reduce(0, +)
        }
        #expect(total(.lesson, 6, 1) == 10)
        #expect(total(.lesson, 6, 0) == 15)
        #expect(total(.lesson, 1, 0) == 10)
        #expect(total(.practice, 3, 0) == 13)
        #expect(total(.practice, 3, 2) == 8)
        #expect(total(.challenge, 4, 0) == 35)
        #expect(total(.challenge, 4, 1) == 25)
        #expect(total(.challenge, 4, 3, false) == 0)
        let perfect = XPTable.completionAwards(kind: .lesson, gradedCount: 6, mistakes: 0, passed: true)
        #expect(perfect.map(\.source) == [.lessonCompleted, .perfectBonus])
        let ch = XPTable.completionAwards(kind: .challenge, gradedCount: 4, mistakes: 0, passed: true)
        #expect(ch.map(\.source) == [.challengePassed, .perfectChallengeBonus])
    }

    @Test func reviewAndLegacyXP() {
        #expect(Rating.allCases.map(XPTable.reviewRated) == [1, 2, 3, 3])
        #expect(XPTable.reviewSessionAwards(cardsReviewed: 4).isEmpty)
        #expect(XPTable.reviewSessionAwards(cardsReviewed: 5) == [XPAward(.reviewSessionCompleted, 5)])
        #expect(XPTable.legacyXP(learnedCards: 10, reviewLogs: 20) == 140)
        #expect(XPTable.legacyXP(learnedCards: 0, reviewLogs: 0) == 0)
    }

    @Test func typicalLessonXP() {
        // 6 correct exercises + 2 couplets rated + completion = 28
        #expect(6 * XPTable.exerciseCorrect + 2 * XPTable.coupletLearned + XPTable.lessonCompleted == 28)
    }

    // MARK: Level

    @Test func levelThresholds() {
        #expect((1...4).map { LevelCurve.threshold(level: $0) } == [0, 40, 100, 180])
        #expect(LevelCurve.level(forXP: 0) == 1)
        #expect(LevelCurve.level(forXP: 39) == 1)
        #expect(LevelCurve.level(forXP: 40) == 2)
        #expect(LevelCurve.level(forXP: 99) == 2)
        #expect(LevelCurve.level(forXP: 100) == 3)
        #expect(LevelCurve.level(forXP: -5) == 1)
    }

    @Test func levelMonotonicAndCapped() {
        var last = 1
        for xp in 0...20_000 {
            let l = LevelCurve.level(forXP: xp)
            #expect(l >= last && l <= LevelCurve.maxLevel)
            #expect(LevelCurve.threshold(level: l) <= xp)
            last = l
        }
        #expect(LevelCurve.level(forXP: 10_000_000) == LevelCurve.maxLevel)
    }

    @Test func levelInfo() {
        let i = LevelCurve.info(totalXP: 55)
        #expect(i.level == 2 && i.xpIntoLevel == 15 && i.xpForNextLevel == 60 && i.xpRemaining == 45)
        #expect(abs(i.fraction - 0.25) < 1e-9)
        let zero = LevelCurve.info(totalXP: 0)
        #expect(zero.level == 1 && zero.fraction == 0 && zero.xpRemaining == 40)
        let top = LevelCurve.info(totalXP: 10_000_000)
        #expect(top.level == 99 && top.fraction == 1 && top.xpRemaining == 0)
    }

    // MARK: Daily goal

    @Test func dailyGoal() {
        #expect(DailyGoal.options == [10, 20, 30, 50] && DailyGoal.defaultGoal == 20)
        #expect(DailyGoal.progress(xp: 10, goal: 20) == 0.5)
        #expect(DailyGoal.progress(xp: 99, goal: 20) == 1)
        #expect(DailyGoal.progress(xp: 5, goal: 0) == 0)
        #expect(DailyGoal.justMet(before: 18, after: 22, goal: 20))
        #expect(DailyGoal.justMet(before: 0, after: 20, goal: 20))
        #expect(!DailyGoal.justMet(before: 20, after: 25, goal: 20))
        #expect(!DailyGoal.justMet(before: 5, after: 19, goal: 20))
        #expect(!DailyGoal.justMet(before: 25, after: 30, goal: 20))
    }
}
