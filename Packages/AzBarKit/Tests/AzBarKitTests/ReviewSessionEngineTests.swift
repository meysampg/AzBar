import Testing
import Foundation
@testable import AzBarKit

@Suite struct ReviewSessionEngineTests {
    let cal = MemTestSupport.utc
    let now = MemTestSupport.t0

    func item(_ i: Int, reps: Int = 2) -> ReviewItem {
        var c = FSRSCard(stability: 5, difficulty: 5, due: now, lastReview: now.addingTimeInterval(-86400 * 5), reps: reps, lapses: 0, state: .review)
        c.reps = reps
        return ReviewItem(key: CoupletKey(poemId: 100, coupletIndex: i), card: c)
    }

    @Test func againRequeuesAtPlusThreeMaxTwice() {
        let list = [item(0), item(1), item(2), item(4)]
        var e = ReviewSessionEngine(items: list, scheduler: FSRSScheduler(calendar: cal))
        #expect(e.total == 4 && e.position == 0)
        e.reveal()
        e.rate(.again, now: now)           // a requeued behind c: [a, b, c, a', d]
        #expect(e.current?.key.coupletIndex == 1)
        e.rate(.good, now: now)
        e.rate(.good, now: now)
        #expect(e.current?.key.coupletIndex == 0)
        #expect(e.current?.card.state == .relearning)
        e.rate(.again, now: now)           // second requeue, appended at the end
        #expect(e.current?.key.coupletIndex == 4)
        e.rate(.good, now: now)
        #expect(e.current?.key.coupletIndex == 0)
        e.rate(.again, now: now)           // third Again: not requeued again
        #expect(e.isFinished)
        #expect(e.counts[.again] == 3)
        #expect(e.counts[.good] == 3)
        #expect(!e.isRevealed)
    }

    @Test func finishAndResult() {
        var e = ReviewSessionEngine(items: [item(0)], scheduler: FSRSScheduler(calendar: cal))
        #expect(!e.isFinished)
        let r = e.rate(.good, now: now)
        #expect(r.card.state == .review && r.scheduledDays >= 1)
        #expect(e.isFinished && e.current == nil)
    }

    @Test func modeSelection() {
        let poem = MemTestSupport.poem()
        let e = ReviewSessionEngine(items: [], scheduler: FSRSScheduler(calendar: cal))
        #expect(e.mode(for: item(0, reps: 1), poem: poem) == .recallSecond)  // no previous: beyt
        #expect(e.mode(for: item(1, reps: 1), poem: poem) == .recallChain)   // odd reps + previous
        #expect(e.mode(for: item(1, reps: 2), poem: poem) == .recallSecond)  // beyt
        #expect(e.mode(for: item(2, reps: 2), poem: poem) == .recallChain)   // single with previous
        let lone = Poem(id: 1, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "",
                        couplets: [Couplet(index: 0, kind: .single, verses: [MemTestSupport.verse(1, "x", position: 4)])])
        let it = ReviewItem(key: CoupletKey(poemId: 1, coupletIndex: 0), card: item(0).card)
        #expect(e.mode(for: it, poem: lone) == .recallFromHints)
    }

    @Test func poemProgress() {
        let mk = { (s: CardState, st: Double) in FSRSCard(stability: st, difficulty: 5, due: self.now, state: s) }
        let p = PoemProgress.compute(cards: [mk(.learning, 1), mk(.relearning, 1), mk(.review, 5), mk(.review, 21), mk(.review, 40)], totalMemorizable: 8)
        #expect(p.total == 8 && p.notStarted == 3 && p.learning == 2 && p.young == 1 && p.mature == 2)
        #expect(abs(p.fraction - (0.5 + 0.6 + 2.0) / 8) < 1e-9)
        #expect(PoemProgress.compute(cards: [], totalMemorizable: 0).fraction == 0)
    }
}
