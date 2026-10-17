import Foundation
@testable import AzBarKit

enum MemTestSupport {
    static var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    static let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    static func verse(_ id: Int, _ text: String, position: Int) -> Verse {
        Verse(id: id, order: id, position: position, text: text)
    }

    /// Poem with: 0 beyt, 1 beyt, 2 single, 3 paragraph (-1), 4 single (after a paragraph).
    static func poem(id: Int = 100) -> Poem {
        let c0 = Couplet(index: 0, kind: .beyt, verses: [verse(1, "اَلا یا اَیُّهَا السّاقی ادِر کَأساً", position: 0), verse(2, "که عشق آسان نمود اول ولی افتاد مشکل‌ها", position: 1)])
        let c1 = Couplet(index: 1, kind: .beyt, verses: [verse(3, "به بوی نافه‌ای کآخر صبا", position: 0), verse(4, "ز تاب جعد مشکینش چه خون افتاد", position: 1)])
        let c2 = Couplet(index: 2, kind: .single, verses: [verse(5, "مرا در منزل جانان چه امن عیش", position: 4)])
        let p = Couplet(index: -6, kind: .paragraph, verses: [verse(6, "متن", position: -1)])
        let c4 = Couplet(index: 4, kind: .single, verses: [verse(7, "جرس فریاد می‌دارد", position: 4)])
        return Poem(id: id, poetId: 2, categoryId: 24, title: "t", fullTitle: "t", urlSlug: "t", fullUrl: "/t",
                    couplets: [c0, c1, c2, p, c4])
    }
}
