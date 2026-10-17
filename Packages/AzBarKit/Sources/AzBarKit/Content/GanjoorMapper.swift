import Foundation

/// Maps Ganjoor API DTOs to domain models. Implements exactly the algorithm of `Tools/fetch_ganjoor.py`
/// (docs/ARCHITECTURE.md section 3b); keep both in sync.
public enum GanjoorMapper {
    /// Strips `\r`, collapses runs of spaces/tabs, trims. Keeps ZWNJ and diacritics.
    public static func clean(_ s: String?) -> String {
        guard let s else { return "" }
        var out = ""
        out.reserveCapacity(s.count)
        var lastWasSpace = false
        for var ch in s {
            if ch == "\r\n" { ch = "\n" } else if ch == "\r" { continue }
            if ch == " " || ch == "\t" {
                if !lastWasSpace { out.append(" ") }
                lastWasSpace = true
            } else {
                out.append(ch)
                lastWasSpace = false
            }
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func couplets(from verses: [GanjoorVerseDTO]) -> [Couplet] {
        let ordered = verses.enumerated().sorted {
            $0.element.vOrder != $1.element.vOrder ? $0.element.vOrder < $1.element.vOrder : $0.offset < $1.offset
        }.map(\.element)
        var groups: [Int: (isNull: Bool, verses: [GanjoorVerseDTO])] = [:]
        var order: [Int] = []
        for v in ordered {
            let key = v.coupletIndex ?? -v.vOrder
            if groups[key] == nil {
                groups[key] = (v.coupletIndex == nil, [])
                order.append(key)
            }
            groups[key]!.verses.append(v)
        }
        return order.map { key in
            let g = groups[key]!
            let vs = g.verses
            let firstPos = vs[0].versePosition
            let kind: CoupletKind
            if g.isNull {
                kind = .paragraph
            } else if vs.count >= 2, let p = firstPos, p == 0 || p == 2 {
                kind = .beyt
            } else if vs.count == 1, let p = firstPos, p == 4 || p == 0 {
                kind = .single
            } else {
                kind = .paragraph
            }
            let summary = vs.lazy.map { clean($0.coupletSummary) }.first { !$0.isEmpty }
            return Couplet(
                index: key, kind: kind,
                verses: vs.map { Verse(id: $0.id, order: $0.vOrder, position: $0.versePosition ?? 0, text: clean($0.text)) },
                summary: summary)
        }
    }

    public static func recitations(from dtos: [GanjoorRecitationDTO]?) -> [Recitation] {
        let items = (dtos ?? []).enumerated().compactMap { (i, r) -> (Int, Int, Recitation)? in
            let mp3 = (r.mp3Url ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !mp3.isEmpty, let url = URL(string: mp3) else { return nil }
            let xml = (r.xmlText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rec = Recitation(id: r.id, artist: clean(r.audioArtist), mp3Url: url,
                                 syncUrl: xml.isEmpty ? nil : URL(string: xml),
                                 order: r.audioOrder ?? 0, type: r.recitationType ?? 0,
                                 synced: r.inSyncWithText ?? false)
            return (rec.order, i, rec)
        }
        return items.sorted { $0.0 != $1.0 ? $0.0 < $1.0 : $0.1 < $1.1 }.map(\.2)
    }

    public static func poem(from dto: GanjoorPoemDTO, poetId: PoetID, categoryId: CategoryID) -> Poem {
        let summary = clean(dto.poemSummary)
        return Poem(
            id: dto.id, poetId: poetId, categoryId: categoryId,
            title: clean(dto.title), fullTitle: clean(dto.fullTitle),
            urlSlug: dto.urlSlug ?? "", fullUrl: dto.fullUrl ?? "",
            summary: summary.isEmpty ? nil : summary,
            couplets: couplets(from: dto.verses ?? []),
            recitations: recitations(from: dto.recitations))
    }

    /// Poem whose poet/category come from the response's own `category` block (requires `catInfo=true`).
    public static func poem(from dto: GanjoorPoemDTO) -> Poem? {
        guard let catId = dto.category?.cat?.id, let poetId = dto.category?.poet?.id else { return nil }
        return poem(from: dto, poetId: poetId, categoryId: catId)
    }

    public static func poet(from dto: GanjoorPoetDTO, slug: String? = nil) -> Poet {
        let fullName = clean(dto.name)
        let nick = clean(dto.nickname)
        let derivedSlug = dto.fullUrl.map { $0.split(separator: "/").first.map(String.init) ?? "" } ?? ""
        return Poet(
            id: dto.id, name: nick.isEmpty ? fullName : nick, fullName: fullName,
            slug: slug ?? derivedSlug, rootCategoryId: dto.rootCatId ?? 0,
            description: clean(dto.description).isEmpty ? nil : clean(dto.description),
            birthYearHijri: dto.birthYearInLHijri.flatMap { $0 == 0 ? nil : $0 },
            deathYearHijri: dto.deathYearInLHijri.flatMap { $0 == 0 ? nil : $0 })
    }

    public static func memorizableCount(_ couplets: [Couplet]) -> Int {
        couplets.filter(\.isMemorizable).count
    }

    public static func category(from dto: GanjoorCatDTO, poetId: PoetID, parentId: CategoryID? = nil) -> PoemCategory {
        PoemCategory(
            id: dto.id, poetId: poetId, title: clean(dto.title), slug: dto.urlSlug ?? "",
            parentId: parentId ?? dto.ancestors?.last?.id,
            children: (dto.children ?? []).map { CategoryRef(id: $0.id, title: clean($0.title)) },
            poems: (dto.poems ?? []).map {
                PoemSummary(id: $0.id, categoryId: dto.id, title: clean($0.title), urlSlug: $0.urlSlug ?? "",
                            excerpt: clean($0.excerpt).isEmpty ? nil : clean($0.excerpt), coupletCount: nil)
            })
    }
}
