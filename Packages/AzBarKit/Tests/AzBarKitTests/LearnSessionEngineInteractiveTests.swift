import Testing
import Foundation
@testable import AzBarKit

@Suite struct LearnSessionEngineInteractiveTests {
    let beyts: Poem
    init() throws { beyts = try Fixture.poem2130() }

    /// Three singles with four-word mesras, so every exercise can be built.
    let singles: Poem = {
        func s(_ i: Int, _ text: String) -> Couplet {
            Couplet(index: i, kind: .single, verses: [MemTestSupport.verse(i + 1, text, position: 4)])
        }
        return Poem(id: 55, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "", couplets: [
            s(0, "گل سرخ باغ بهار"), s(1, "دل عاشق شب تنها"), s(2, "ماه روشن آسمان دور"),
        ])
    }()

    func eng(_ p: Poem, _ idx: [Int], _ o: LearnSessionOptions) -> LearnSessionEngine {
        LearnSessionEngine(poem: p, coupletIndices: idx, options: o)
    }

    // MARK: Step lists

    @Test func interactiveBeytSteps() {
        let e = eng(beyts, [0, 1], .interactive)
        let first: [LearnStep] = [.read, .cloze(level: 1), .cloze(level: 2), .fillBlank(mesraIndex: 1), .cloze(level: 3),
                                  .wordBank(mesraIndex: 0, distractors: 0), .firstLetters,
                                  .wordBank(mesraIndex: 1, distractors: 1), .recallSecond]
        #expect(e.steps(for: LearnItem(coupletIndex: 0, isRetry: false)) == first)
        #expect(e.steps(for: LearnItem(coupletIndex: 1, isRetry: false)) == first + [.recallChain])
        #expect(e.steps(for: LearnItem(coupletIndex: 0, isRetry: true)) ==
                [.cloze(level: 2), .wordBank(mesraIndex: 1, distractors: 1), .recallSecond])
    }

    @Test func interactiveSingleSteps() {
        let e = eng(singles, [0, 1], .interactive)
        #expect(e.steps(for: LearnItem(coupletIndex: 0, isRetry: false)) ==
                [.read, .cloze(level: 1), .cloze(level: 2), .fillBlank(mesraIndex: 0), .cloze(level: 3),
                 .wordBank(mesraIndex: 0, distractors: 1)])
        #expect(e.steps(for: LearnItem(coupletIndex: 1, isRetry: false)) ==
                [.read, .cloze(level: 1), .cloze(level: 2), .fillBlank(mesraIndex: 0), .cloze(level: 3),
                 .wordBank(mesraIndex: 0, distractors: 1), .firstLetters, .recallChain])
        #expect(e.steps(for: LearnItem(coupletIndex: 1, isRetry: true)) ==
                [.cloze(level: 2), .wordBank(mesraIndex: 0, distractors: 1)])
    }

    @Test func practiceAndChallengeSteps() {
        let p = eng(beyts, [0], .practice)
        #expect(p.steps(for: LearnItem(coupletIndex: 0, isRetry: false)) ==
                [.fillBlank(mesraIndex: 1), .wordBank(mesraIndex: 0, distractors: 1), .wordBank(mesraIndex: 1, distractors: 2)])
        let c = eng(beyts, [0], .challenge)
        #expect(c.steps(for: LearnItem(coupletIndex: 0, isRetry: false)) ==
                [.wordBank(mesraIndex: 0, distractors: 2), .wordBank(mesraIndex: 1, distractors: 2)])
        let ps = eng(singles, [0], .practice)
        #expect(ps.steps(for: ps.currentItem!) == [.fillBlank(mesraIndex: 0), .wordBank(mesraIndex: 0, distractors: 2)])
        let cs = eng(singles, [0], .challenge)
        #expect(cs.steps(for: cs.currentItem!) == [.wordBank(mesraIndex: 0, distractors: 2)])
    }

    @Test func classicMatchesOldSequences() {
        let e = eng(beyts, [0, 1], .classic)
        #expect(e.steps(for: LearnItem(coupletIndex: 1, isRetry: false)) ==
                [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3), .firstLetters, .recallSecond, .recallChain])
        #expect(e.options == .classic && !e.isGradedStep && e.currentExercise == nil)
    }

    @Test func unbuildableGradedStepsAreFiltered() {
        // Two-word mesras: no word bank, and too few distractors for fill-blank.
        let tiny = Poem(id: 4, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "", couplets: [
            Couplet(index: 0, kind: .beyt, verses: [MemTestSupport.verse(1, "دل جان", position: 0), MemTestSupport.verse(2, "جان دل", position: 1)])])
        let learn = eng(tiny, [0], .interactive)
        #expect(learn.steps(for: learn.currentItem!) ==
                [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3), .firstLetters, .recallSecond])
        let practice = eng(tiny, [0], .practice)
        #expect(practice.isFinished && practice.queue.isEmpty)
    }

    @Test func exerciseLookup() {
        for (poem, idx) in [(beyts, [0, 1, 2]), (singles, [0, 1, 2])] {
            for mode in [LearnSessionOptions.interactive, .practice, .challenge] {
                let e = eng(poem, idx, mode)
                for item in e.queue {
                    for step in e.steps(for: item) {
                        switch step {
                        case .fillBlank, .wordBank: #expect(e.exercise(for: step, coupletIndex: item.coupletIndex) != nil)
                        default: #expect(e.exercise(for: step, coupletIndex: item.coupletIndex) == nil)
                        }
                    }
                }
            }
        }
    }

    // MARK: Walking

    /// Walks a learn session: ungraded steps advance, recall steps reveal, graded steps are checked.
    func walkToRating(_ e: inout LearnSessionEngine, correct: Bool = true) {
        var guardCount = 0
        while guardCount < 100 {
            guardCount += 1
            if e.isGradedStep {
                if !e.isRevealed { e.check(correct: correct) }
                if e.awaitsRating { return }
            } else if e.isRecallStep {
                e.reveal()
                if e.awaitsRating { return }
            }
            e.advance()
        }
        Issue.record("did not reach a rating")
    }

    @Test func advanceBlockedOnGradedUntilCheck() {
        var e = eng(beyts, [0], .interactive)
        for _ in 0..<3 { e.advance() }
        #expect(e.currentStep == .fillBlank(mesraIndex: 1) && e.isGradedStep && e.currentExercise != nil)
        e.advance()
        #expect(e.currentStep == .fillBlank(mesraIndex: 1))
        e.reveal()                       // ignored on graded steps
        #expect(!e.isRevealed)
        e.check(correct: true)
        #expect(e.isRevealed && !e.awaitsRating && !e.isRecallStep)
        e.advance()
        #expect(e.currentStep == .cloze(level: 3) && !e.isRevealed)
    }

    @Test func checkOnlyOnGradedAndOnce() {
        var e = eng(beyts, [0], .interactive)
        e.check(correct: false)
        #expect(e.gradedCount == 0 && e.totalMistakes == 0 && !e.isRevealed)
        for _ in 0..<3 { e.advance() }
        e.check(correct: false)
        e.check(correct: false)
        #expect(e.gradedCount == 1 && e.totalMistakes == 1 && e.mistakes(for: 0) == 1)
    }

    @Test func mistakesAndSuggestedRating() {
        var e = eng(beyts, [0, 1], .interactive)
        #expect(e.suggestedRating(for: 0) == .good)
        for _ in 0..<3 { e.advance() }
        e.check(correct: false)
        #expect(e.suggestedRating(for: 0) == .hard && e.suggestedRating(for: 1) == .good)
        e.advance(); e.advance()                // cloze(3), wordBank(0)
        e.check(correct: false)
        #expect(e.mistakes(for: 0) == 2 && e.suggestedRating(for: 0) == .again)
        var p = eng(beyts, [0], .interactive)
        for _ in 0..<3 { p.notePeek() }
        #expect(p.suggestedRating(for: 0) == .hard)
    }

    @Test func ratingEventCarriesMistakes() {
        var e = eng(beyts, [0], .interactive)
        for _ in 0..<3 { e.advance() }
        e.check(correct: false)
        e.advance()                              // cloze(3)
        e.advance()                              // wordBank(0,d:0)
        e.check(correct: true)
        e.advance()                              // firstLetters
        e.advance()                              // wordBank(1)
        e.check(correct: true)
        e.advance()                              // recallSecond
        e.reveal()
        #expect(e.awaitsRating)
        let ev = e.rate(.hard)
        #expect(ev.mistakes == 1 && ev.coupletIndex == 0 && e.gradedCount == 3 && e.isFinished)
        #expect(LearnRatingEvent(coupletIndex: 1, rating: .good).mistakes == 0)
    }

    @Test func gradedLastStepAwaitsRatingForSingleWithoutChain() {
        var e = eng(singles, [0], .interactive)
        walkToRating(&e)
        #expect(e.currentStep == .wordBank(mesraIndex: 0, distractors: 1))
        #expect(e.awaitsRating && e.isGradedStep)
        e.advance()                              // blocked: needs a rating
        #expect(e.currentStep == .wordBank(mesraIndex: 0, distractors: 1))
        e.rate(.good)
        #expect(e.isFinished && e.learnedCount == 1)
    }

    @Test func againInInteractiveModeAddsRetry() {
        var e = eng(beyts, [0], .interactive)
        walkToRating(&e, correct: false)
        e.rate(.again)
        #expect(e.queue.count == 2 && e.queue[1].isRetry && !e.isFinished)
        #expect(e.currentStep == .cloze(level: 2))
        walkToRating(&e)
        #expect(e.currentItem?.isRetry == true && e.awaitsRating)
        e.rate(.good)
        #expect(e.isFinished && e.learnedCount == 1)
    }

    @Test func progressMonotonicInteractive() {
        var e = eng(beyts, [0, 1], .interactive)
        var last = 0.0
        var guardCount = 0
        while !e.isFinished && guardCount < 300 {
            guardCount += 1
            if e.isGradedStep, !e.isRevealed { e.check(correct: guardCount % 3 != 0) }
            else if e.isRecallStep { e.reveal() }
            if e.awaitsRating { e.rate(.good) } else { e.advance() }
            #expect(e.progress >= last)
            last = e.progress
        }
        #expect(e.isFinished && e.progress == 1)
    }

    // MARK: Practice and challenge

    @Test func practiceNeverAwaitsRatingAndFinishes() {
        var e = eng(beyts, [0, 1], .practice)
        var steps = 0
        while !e.isFinished && steps < 50 {
            steps += 1
            #expect(e.isGradedStep && !e.isRecallStep)
            e.advance()                          // blocked before check
            e.check(correct: steps % 2 == 0)
            #expect(!e.awaitsRating)
            e.advance()
        }
        #expect(e.isFinished && steps == 6 && e.gradedCount == 6 && e.totalMistakes == 3)
        #expect(e.learnedCount == 2 && e.progress == 1)
        #expect(e.mistakes(for: 0) + e.mistakes(for: 1) == 3)
    }

    @Test func challengeFinishesWithoutRatings() {
        var e = eng(singles, [0, 1, 2], .challenge)
        var n = 0
        while !e.isFinished && n < 20 {
            n += 1
            e.check(correct: true)
            #expect(!e.awaitsRating)
            e.advance()
        }
        #expect(n == 3 && e.gradedCount == 3 && e.totalMistakes == 0)
        #expect(LessonScoring.challengePassed(graded: e.gradedCount, mistakes: e.totalMistakes))
    }
}
