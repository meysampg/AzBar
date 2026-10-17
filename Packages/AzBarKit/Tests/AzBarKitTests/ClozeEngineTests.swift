import Testing
import Foundation
@testable import AzBarKit

@Suite struct ClozeEngineTests {
    let poem = MemTestSupport.poem()

    @Test func determinism() {
        let a = ClozeEngine(poemId: 100, couplet: poem.couplets[0])
        let b = ClozeEngine(poemId: 100, couplet: poem.couplets[0])
        #expect(a.hidingOrder == b.hidingOrder)
        // Stable across processes: pin the hash.
        #expect(FNV1a64.hash("") == 0xcbf29ce484222325)
        #expect(FNV1a64.hash("a") == 0xaf63dc4c8601ec8c)
        var g1 = SplitMix64(seed: 1), g2 = SplitMix64(seed: 1)
        #expect(g1.next() == g2.next())
        var g0 = SplitMix64(seed: 0)
        #expect(g0.next() == 0xE220A8397B1DCDAF)
    }

    @Test func differentPoemsDifferentOrders() {
        let long = Couplet(index: 0, kind: .beyt, verses: [
            Verse(id: 1, order: 1, position: 0, text: "شب تاریک و بیم موج و گردابی چنین هایل"),
            Verse(id: 2, order: 2, position: 1, text: "کجا دانند حال ما سبکباران ساحل‌ها")])
        let orders = Set((1...6).map { ClozeEngine(poemId: $0, couplet: long).hidingOrder })
        #expect(orders.count > 1)
    }

    @Test func nestedLevels() {
        let e = ClozeEngine(poemId: 100, couplet: poem.couplets[0])
        let words = e.hidingOrder.count
        #expect(e.hiddenIds(level: 0).isEmpty)
        let l1 = e.hiddenIds(level: 1), l2 = e.hiddenIds(level: 2), l3 = e.hiddenIds(level: 3)
        #expect(l1.isSubset(of: l2) && l2.isSubset(of: l3))
        #expect(l3.count == words)
        #expect(l1.count >= 1)
        #expect(e.hiddenIds(fraction: 0.01).count == 1)
        #expect(e.hiddenIds(fraction: -1).isEmpty)
        #expect(e.hiddenIds(fraction: 2).count == words)
    }

    @Test func stopwordsLast() {
        let c = Couplet(index: 0, kind: .beyt, verses: [
            Verse(id: 1, order: 1, position: 0, text: "که عشق آسان نمود اول"),
            Verse(id: 2, order: 2, position: 1, text: "و در این دل مشکل‌ها")])
        let e = ClozeEngine(poemId: 7, couplet: c)
        let flat = e.tokens.flatMap { $0 }
        let isStop = { (id: Int) in PersianStopwords.set.contains(flat.first { $0.id == id }!.normalized) }
        let content = flat.filter { $0.isWord && !PersianStopwords.set.contains($0.normalized) }.count
        #expect(content > 0)
        for id in e.hidingOrder.prefix(content) { #expect(!isStop(id)) }
        for id in e.hidingOrder.dropFirst(content) { #expect(isStop(id)) }
        // Below 100% a stopword is only hidden once all content words are hidden.
        for f in [0.3, 0.6, 0.75] {
            let hidden = e.hiddenIds(fraction: f)
            if hidden.contains(where: isStop) { #expect(hidden.count > content) }
        }
    }

    @Test func zwnjWordIsOneToken() {
        let c = Couplet(index: 0, kind: .single, verses: [Verse(id: 1, order: 1, position: 4, text: "می‌خواهم، تو را")])
        let e = ClozeEngine(poemId: 1, couplet: c)
        #expect(e.tokens[0].count == 3)
        #expect(e.tokens[0][0].core == "می‌خواهم")
        #expect(e.tokens[0][0].trailing == "،")
    }

    @Test func firstLetterHints() {
        let tok = { (s: String) in PersianTokenizer.tokenize(s, mesraIndex: 0, startId: 0)[0] }
        #expect(ClozeEngine.firstLetterHint(tok("درد")) == "د…")
        #expect(ClozeEngine.firstLetterHint(tok("عشق")) == "ع" + String(repeating: "\u{0640}", count: 2))
        #expect(ClozeEngine.firstLetterHint(tok("به")) == "ب\u{0640}")
        #expect(ClozeEngine.firstLetterHint(tok("«ساقی»")) == "س" + String(repeating: "\u{0640}", count: 3))
        #expect(ClozeEngine.firstLetterHint(tok("اَلا")) == "اَ…")
    }
}
