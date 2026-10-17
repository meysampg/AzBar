import Testing
import Foundation
@testable import AzBarKit

@Suite struct LearnSessionEngineTests {
    let poem = MemTestSupport.poem()

    @Test func stepSequences() {
        let e = LearnSessionEngine(poem: poem, coupletIndices: [0, 1, 2, 4])
        #expect(e.steps(for: LearnItem(coupletIndex: 0, isRetry: false)) ==
                [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3), .firstLetters, .recallSecond])
        #expect(e.steps(for: LearnItem(coupletIndex: 1, isRetry: false)) ==
                [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3), .firstLetters, .recallSecond, .recallChain])
        #expect(e.steps(for: LearnItem(coupletIndex: 2, isRetry: false)).last == .recallChain)
        #expect(e.steps(for: LearnItem(coupletIndex: 1, isRetry: true)) == [.cloze(level: 2), .recallSecond])
        #expect(e.steps(for: LearnItem(coupletIndex: 2, isRetry: true)) == [.cloze(level: 2), .cloze(level: 3)])
    }

    @Test func singleWithoutChain() {
        let single = Poem(id: 1, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "",
                          couplets: [Couplet(index: 0, kind: .single, verses: [MemTestSupport.verse(1, "یک دو سه", position: 4)])])
        var e = LearnSessionEngine(poem: single, coupletIndices: [0])
        #expect(e.steps(for: e.currentItem!) == [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3)])
        for _ in 0..<3 { e.advance() }
        #expect(e.currentStep == .cloze(level: 3))
        #expect(e.isRecallStep && !e.awaitsRating)
        e.reveal()
        #expect(e.awaitsRating)
        e.rate(.good)
        #expect(e.isFinished && e.learnedCount == 1)
    }

    func walkToRating(_ e: inout LearnSessionEngine) {
        while true {
            if e.isRecallStep {
                e.reveal()
                if e.awaitsRating { return }
            }
            e.advance()
        }
    }

    @Test func againAddsOneRetryOnly() {
        var e = LearnSessionEngine(poem: poem, coupletIndices: [0])
        walkToRating(&e)
        let ev = e.rate(.again)
        #expect(ev.coupletIndex == 0 && ev.rating == .again)
        #expect(e.queue.count == 2 && e.queue[1].isRetry && !e.isFinished)
        #expect(e.learnedCount == 0)
        walkToRating(&e)
        #expect(e.currentItem?.isRetry == true)
        e.rate(.again)
        #expect(e.queue.count == 2 && e.isFinished)
        #expect(e.learnedCount == 1)
    }

    @Test func progressMonotonic() {
        var e = LearnSessionEngine(poem: poem, coupletIndices: [0, 1])
        var last = e.progress
        #expect(last == 0)
        var ratings = 0
        while !e.isFinished {
            if e.isRecallStep {
                e.reveal()
                if e.awaitsRating {
                    e.rate(ratings == 0 ? .again : .good)
                    ratings += 1
                    #expect(e.progress >= last)
                    last = e.progress
                    continue
                }
            }
            e.advance()
            #expect(e.progress >= last)
            last = e.progress
        }
        #expect(e.progress == 1)
        #expect(ratings == 3)
    }

    @Test func advanceIgnoredOnUnrevealedRecall() {
        var e = LearnSessionEngine(poem: poem, coupletIndices: [0])
        for _ in 0..<5 { e.advance() }
        #expect(e.currentStep == .recallSecond)
        e.advance()
        #expect(e.currentStep == .recallSecond)
    }
}
