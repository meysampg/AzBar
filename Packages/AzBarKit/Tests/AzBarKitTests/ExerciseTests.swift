import Testing
import Foundation
@testable import AzBarKit

@Suite struct ExerciseTests {
    let poem: Poem
    init() throws { poem = try Fixture.poem2130() }

    func words(_ text: String) -> [String] { PersianTokenizer.tokenize(text, mesraIndex: 0, startId: 0).filter(\.isWord).map(\.core) }

    func tinyPoem() -> Poem {
        Poem(id: 9, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "",
             couplets: [Couplet(index: 0, kind: .beyt, verses: [
                MemTestSupport.verse(1, "یک دو", position: 0), MemTestSupport.verse(2, "سه چهار پنج", position: 1)])])
    }

    // MARK: AnswerMatcher

    @Test func matcher() {
        #expect(AnswerMatcher.equivalent("اَلا", "الا"))
        #expect(AnswerMatcher.equivalent("می‌خواهم", "میخواهم"))
        #expect(AnswerMatcher.equivalent("كتاب", "کتاب"))
        #expect(AnswerMatcher.equivalent("ياد", "یاد"))
        #expect(!AnswerMatcher.equivalent("دل", "گل"))
        #expect(AnswerMatcher.sequenceEquivalent(["اَلا", "یا"], ["الا", "یا"]))
        #expect(!AnswerMatcher.sequenceEquivalent(["الا"], ["الا", "یا"]))
        #expect(!AnswerMatcher.sequenceEquivalent(["یا", "الا"], ["الا", "یا"]))
    }

    // MARK: Word bank

    @Test func wordBankStructure() throws {
        for c in poem.memorizableCouplets {
            for m in c.verses.indices {
                guard let ex = WordBankExercise.make(poem: poem, coupletIndex: c.index, mesraIndex: m, distractorCount: 3) else { continue }
                #expect(ex.answer.map(\.text) == words(c.verses[m].text))
                let bankIds = Set(ex.bank.map(\.id))
                #expect(ex.bank.count == bankIds.count)
                #expect(bankIds == Set(ex.answer.map(\.id)).union(ex.bank.filter(\.isDistractor).map(\.id)))
                #expect(ex.bank.count == ex.answer.count + ex.bank.filter(\.isDistractor).count)
                #expect(ex.bank.filter { !$0.isDistractor }.map(\.id).sorted() == ex.answer.map(\.id))
                #expect(ex.bank.filter { !$0.isDistractor }.map(\.id) != ex.answer.map(\.id))
                let ds = ex.bank.filter(\.isDistractor)
                #expect(ds.count <= 3)
                let answerSet = Set(ex.answer.map(\.normalized))
                #expect(ds.allSatisfy { !PersianStopwords.set.contains($0.normalized) && !answerSet.contains($0.normalized) })
                #expect(Set(ds.map(\.normalized)).count == ds.count)
            }
        }
    }

    @Test func wordBankHasDistractors() throws {
        let ex = try #require(WordBankExercise.make(poem: poem, coupletIndex: 0, mesraIndex: 0, distractorCount: 2))
        #expect(ex.bank.filter(\.isDistractor).count == 2)
        let none = try #require(WordBankExercise.make(poem: poem, coupletIndex: 0, mesraIndex: 0, distractorCount: 0))
        #expect(none.bank.count == none.answer.count)
    }

    @Test func wordBankDeterministic() {
        let a = WordBankExercise.make(poem: poem, coupletIndex: 1, mesraIndex: 1, distractorCount: 2)
        let b = WordBankExercise.make(poem: poem, coupletIndex: 1, mesraIndex: 1, distractorCount: 2)
        #expect(a != nil && a == b)
        let other = WordBankExercise.make(poem: poem, coupletIndex: 2, mesraIndex: 1, distractorCount: 2)
        #expect(a != other)
    }

    @Test func wordBankEvaluation() throws {
        let ex = try #require(WordBankExercise.make(poem: poem, coupletIndex: 0, mesraIndex: 0, distractorCount: 2))
        let ids = ex.answer.map(\.id)
        let ok = ex.evaluate(ids)
        #expect(ok.isCorrect && ok.wrongPositions.isEmpty)
        #expect(ok.expected == ex.answer.map(\.text).joined(separator: " "))
        var swapped = ids
        swapped.swapAt(0, 1)
        let bad = ex.evaluate(swapped)
        #expect(!bad.isCorrect && bad.wrongPositions == [0, 1])
        let short = ex.evaluate(Array(ids.dropLast()))
        #expect(!short.isCorrect)
        let distractor = try #require(ex.bank.first(where: { $0.isDistractor }))
        var withDistractor = ids
        withDistractor[0] = distractor.id
        #expect(ex.evaluate(withDistractor).wrongPositions == [0])
        #expect(!ex.evaluate(ids + [ids[0]]).isCorrect)
        #expect(!ex.evaluate([999]).isCorrect)
    }

    @Test func wordBankDuplicateWordsInterchangeable() throws {
        let p = Poem(id: 8, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "", couplets: [
            Couplet(index: 0, kind: .beyt, verses: [MemTestSupport.verse(1, "دل دل جان", position: 0), MemTestSupport.verse(2, "سرو باغ نور", position: 1)]),
            Couplet(index: 1, kind: .beyt, verses: [MemTestSupport.verse(3, "گل ماه شب", position: 0), MemTestSupport.verse(4, "خاک آب باد", position: 1)]),
        ])
        let ex = try #require(WordBankExercise.make(poem: p, coupletIndex: 0, mesraIndex: 0, distractorCount: 2))
        #expect(ex.answer.map(\.id) == [0, 1, 2])
        #expect(ex.evaluate([1, 0, 2]).isCorrect)
        #expect(!ex.evaluate([0, 2, 1]).isCorrect)
    }

    @Test func wordBankIgnoresDiacriticsAndZWNJ() throws {
        let p = Poem(id: 7, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "", couplets: [
            Couplet(index: 0, kind: .beyt, verses: [MemTestSupport.verse(1, "اَلا می‌خواهم دل", position: 0), MemTestSupport.verse(2, "سرو باغ نور", position: 1)]),
        ])
        let ex = try #require(WordBankExercise.make(poem: p, coupletIndex: 0, mesraIndex: 0, distractorCount: 0))
        #expect(ex.answer.map(\.normalized) == ["الا", "میخواهم", "دل"])
        #expect(ex.answer[0].text == "اَلا")
    }

    @Test func wordBankNilForShortMesra() {
        #expect(WordBankExercise.make(poem: tinyPoem(), coupletIndex: 0, mesraIndex: 0, distractorCount: 2) == nil)
        #expect(WordBankExercise.make(poem: tinyPoem(), coupletIndex: 0, mesraIndex: 1, distractorCount: 2) != nil)
        #expect(WordBankExercise.make(poem: tinyPoem(), coupletIndex: 5, mesraIndex: 0, distractorCount: 2) == nil)
        #expect(WordBankExercise.make(poem: tinyPoem(), coupletIndex: 0, mesraIndex: 4, distractorCount: 2) == nil)
    }

    // MARK: Fill blank

    @Test func fillBlankStructure() throws {
        var made = 0
        for c in poem.memorizableCouplets {
            for m in c.verses.indices {
                guard let ex = FillBlankExercise.make(poem: poem, coupletIndex: c.index, mesraIndex: m) else { continue }
                made += 1
                let blank = try #require(ex.tokens.first { $0.id == ex.blankTokenId })
                #expect(blank.mesraIndex == m && blank.isWord)
                #expect(!PersianStopwords.set.contains(blank.normalized))
                #expect((3...4).contains(ex.options.count))
                let normalized = ex.options.map { PersianText.normalizeForSearch($0) }
                #expect(Set(normalized).count == ex.options.count)
                #expect(normalized.filter { $0 == blank.normalized }.count == 1)
                #expect(ex.options[ex.correctOptionIndex] == blank.core)
                #expect(ex.evaluate(optionIndex: ex.correctOptionIndex).isCorrect)
            }
        }
        #expect(made > 0)
    }

    @Test func fillBlankEvaluateWrong() throws {
        let ex = try #require(FillBlankExercise.make(poem: poem, coupletIndex: 0, mesraIndex: 1))
        let wrong = (ex.correctOptionIndex + 1) % ex.options.count
        let r = ex.evaluate(optionIndex: wrong)
        #expect(!r.isCorrect && r.wrongPositions == [0] && r.expected == ex.options[ex.correctOptionIndex])
        #expect(!ex.evaluate(optionIndex: 99).isCorrect)
    }

    @Test func fillBlankDeterministic() {
        let a = FillBlankExercise.make(poem: poem, coupletIndex: 3, mesraIndex: 0)
        #expect(a != nil && a == FillBlankExercise.make(poem: poem, coupletIndex: 3, mesraIndex: 0))
        #expect(FillBlankExercise.make(poem: poem, coupletIndex: 3, mesraIndex: 0, optionCount: 3)?.options.count == 3)
    }

    @Test func fillBlankNilForTinyPoem() {
        let tiny = Poem(id: 6, poetId: 1, categoryId: 1, title: "", fullTitle: "", urlSlug: "", fullUrl: "", couplets: [
            Couplet(index: 0, kind: .beyt, verses: [MemTestSupport.verse(1, "دل و جان", position: 0), MemTestSupport.verse(2, "دل و دل", position: 1)])])
        #expect(FillBlankExercise.make(poem: tiny, coupletIndex: 0, mesraIndex: 0) == nil)
        #expect(FillBlankExercise.make(poem: tiny, coupletIndex: 0, mesraIndex: 7) == nil)
    }

    // MARK: Scoring

    @Test func suggestedRating() {
        #expect(LessonScoring.suggestedRating(mistakes: 0, peeks: 0) == .good)
        #expect(LessonScoring.suggestedRating(mistakes: 0, peeks: 2) == .good)
        #expect(LessonScoring.suggestedRating(mistakes: 0, peeks: 3) == .hard)
        #expect(LessonScoring.suggestedRating(mistakes: 1, peeks: 0) == .hard)
        #expect(LessonScoring.suggestedRating(mistakes: 1, peeks: 9) == .hard)
        #expect(LessonScoring.suggestedRating(mistakes: 2, peeks: 0) == .again)
        #expect(LessonScoring.suggestedRating(mistakes: 5, peeks: 5) == .again)
    }

    @Test func accuracyAndChallengeRule() {
        #expect(LessonScoring.accuracy(graded: 0, mistakes: 0) == 1)
        #expect(LessonScoring.accuracy(graded: 4, mistakes: 1) == 0.75)
        #expect(LessonScoring.accuracy(graded: 2, mistakes: 5) == 0)
        #expect(LessonScoring.challengePassed(graded: 4, mistakes: 1))
        #expect(!LessonScoring.challengePassed(graded: 4, mistakes: 2))
        #expect(LessonScoring.challengePassed(graded: 10, mistakes: 2))
        #expect(!LessonScoring.challengePassed(graded: 10, mistakes: 3))
        #expect(LessonScoring.challengePassed(graded: 15, mistakes: 3))
    }
}
