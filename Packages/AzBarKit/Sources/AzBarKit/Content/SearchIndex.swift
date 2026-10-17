import Foundation

/// In-memory full-text index over bundled poems. Text is normalized with
/// `PersianText.normalizeForSearch` (diacritics, tatweel and ZWNJ removed, letter variants unified),
/// so queries match regardless of vowel marks or half-spaces. Built once, then queried.
public actor SearchIndex {
    private struct Entry {
        let poemId: Int
        let poetId: Int
        let poemTitle: String
        let coupletIndex: Int?
        let verseId: Int?
        let text: String        // original text shown to the user
        let normalized: String
    }

    private var entries: [Entry] = []
    private var built = false

    public init() {}

    public var isBuilt: Bool { built }
    public var entryCount: Int { entries.count }

    /// Builds the index (no-op when already built).
    public func build(poems: [Poem]) {
        guard !built else { return }
        var result: [Entry] = []
        result.reserveCapacity(poems.reduce(0) { $0 + $1.couplets.reduce(1) { $0 + $1.verses.count } })
        for poem in poems {
            result.append(Entry(poemId: poem.id, poetId: poem.poetId, poemTitle: poem.title, coupletIndex: nil,
                                verseId: nil, text: poem.title, normalized: PersianText.normalizeForSearch(poem.title)))
            for couplet in poem.couplets {
                for verse in couplet.verses {
                    result.append(Entry(poemId: poem.id, poetId: poem.poetId, poemTitle: poem.title,
                                        coupletIndex: couplet.index, verseId: verse.id, text: verse.text,
                                        normalized: PersianText.normalizeForSearch(verse.text)))
                }
            }
        }
        entries = result
        built = true
    }

    /// Returns hits in insertion order (a poet's hits are skipped once it reaches `perPoetLimit`). The query is normalized; queries shorter than 2 characters return nothing.
    public func search(_ query: String, limit: Int = 100, perPoetLimit: Int = .max) -> [SearchHit] {
        let q = PersianText.normalizeForSearch(query)
        guard q.count >= 2, limit > 0 else { return [] }
        var hits: [SearchHit] = []
        var perPoet: [Int: Int] = [:]
        for e in entries where e.normalized.range(of: q, options: .literal) != nil {
            if perPoet[e.poetId, default: 0] >= perPoetLimit { continue }
            perPoet[e.poetId, default: 0] += 1
            let id = e.verseId.map { "\(e.poemId):\(e.coupletIndex ?? -1):\($0)" } ?? "\(e.poemId):title"
            hits.append(SearchHit(id: id, poemId: e.poemId, poetId: e.poetId, poemTitle: e.poemTitle,
                                  coupletIndex: e.coupletIndex, matchedText: e.text))
            if hits.count >= limit { break }
        }
        return hits
    }
}
