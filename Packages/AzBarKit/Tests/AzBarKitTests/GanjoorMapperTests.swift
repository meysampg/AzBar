import Foundation
import Testing
@testable import AzBarKit

@Suite struct GanjoorMapperTests {
    @Test func ghazal1HasSevenBeyts() throws {
        let poem = try Fixture.poem2130()
        #expect(poem.id == 2130)
        #expect(poem.couplets.count == 7)
        #expect(poem.couplets.allSatisfy { $0.kind == .beyt && $0.verses.count == 2 })
        #expect(poem.couplets.map(\.index) == Array(0..<7))
        #expect(poem.memorizableCouplets.count == 7)
        #expect(poem.title == "غزل شمارهٔ ۱")
        #expect(poem.fullUrl == "/hafez/ghazal/sh1")
        #expect(poem.summary?.hasPrefix("در این شعر حافظ") == true)
    }

    @Test func firstCoupletKeepsDiacriticsAndSummary() throws {
        let c = try #require(try Fixture.poem2130().couplet(at: 0))
        #expect(c.verses[0].id == 3794588)
        #expect(c.verses[0].order == 1)
        #expect(c.verses[0].position == 0)
        #expect(c.firstMesra == "اَلا یا اَیُّهَا السّاقی اَدِرْ کَأساً و ناوِلْها")
        #expect(c.secondMesra?.hasPrefix("که عشق آسان") == true)
        #expect(c.summary?.hasPrefix("هان ای ساقی جام شراب را") == true)
        // ZWNJ is preserved
        #expect(c.verses[1].text.unicodeScalars.contains("\u{200C}"))
    }

    @Test func recitationsMappedAndSorted() throws {
        let poem = try Fixture.poem2130()
        #expect(poem.recitations.count == 20)
        let first = poem.recitations[0]
        #expect(first.id == 2840)
        #expect(first.artist == "فریدون فرح\u{200C}اندوز")
        #expect(first.mp3Url.absoluteString == "https://i.ganjoor.net/a/2130-ff.mp3")
        #expect(first.syncUrl?.absoluteString == "https://api.ganjoor.net/api/audio/xml/2840")
        #expect(first.synced)
        let orders = poem.recitations.map(\.order)
        #expect(orders == orders.sorted())
    }

    @Test func recitationsWithoutMp3AreDropped() {
        let dtos = [
            GanjoorRecitationDTO(id: 1, audioArtist: "الف", mp3Url: "", xmlText: nil, audioOrder: 1, recitationType: 0, inSyncWithText: false),
            GanjoorRecitationDTO(id: 2, audioArtist: "ب", mp3Url: "https://x.test/b.mp3", xmlText: "", audioOrder: 3, recitationType: 0, inSyncWithText: nil),
            GanjoorRecitationDTO(id: 3, audioArtist: "پ", mp3Url: "https://x.test/p.mp3", xmlText: "https://x.test/s", audioOrder: 2, recitationType: 1, inSyncWithText: true),
        ]
        let recs = GanjoorMapper.recitations(from: dtos)
        #expect(recs.map(\.id) == [3, 2])
        #expect(recs[1].syncUrl == nil)
        #expect(recs[1].synced == false)
    }

    @Test func nullCoupletIndexBecomesNegativeParagraph() {
        let verses = [
            GanjoorVerseDTO(id: 10, vOrder: 2, coupletIndex: 0, versePosition: 1, text: "دوم  \r"),
            GanjoorVerseDTO(id: 9, vOrder: 1, coupletIndex: 0, versePosition: 0, text: " اول   خوب"),
            GanjoorVerseDTO(id: 11, vOrder: 3, coupletIndex: nil, versePosition: -1, text: "بند"),
            GanjoorVerseDTO(id: 12, vOrder: 4, coupletIndex: 1, versePosition: 4, text: "تک"),
        ]
        let cs = GanjoorMapper.couplets(from: verses)
        #expect(cs.map(\.index) == [0, -3, 1])
        #expect(cs.map(\.kind) == [.beyt, .paragraph, .single])
        #expect(cs[0].verses.map(\.id) == [9, 10])
        #expect(cs[0].verses[0].text == "اول خوب")
        #expect(cs[0].verses[1].text == "دوم")
        #expect(cs[1].isMemorizable == false)
        #expect(cs[2].isMemorizable)
    }

    @Test func positionTwoPairIsBeyt() {
        let verses = [
            GanjoorVerseDTO(id: 1, vOrder: 1, coupletIndex: 0, versePosition: 2, text: "الف"),
            GanjoorVerseDTO(id: 2, vOrder: 2, coupletIndex: 0, versePosition: 3, text: "ب"),
        ]
        #expect(GanjoorMapper.couplets(from: verses)[0].kind == .beyt)
    }

    @Test func summaryIsFirstNonEmpty() {
        let verses = [
            GanjoorVerseDTO(id: 1, vOrder: 1, coupletIndex: 0, versePosition: 0, text: "الف", coupletSummary: "  "),
            GanjoorVerseDTO(id: 2, vOrder: 2, coupletIndex: 0, versePosition: 1, text: "ب", coupletSummary: " معنی  دوم "),
        ]
        #expect(GanjoorMapper.couplets(from: verses)[0].summary == "معنی دوم")
    }

    @Test func rubaiyatCategoryAndPoetMap() throws {
        let catResp = try Fixture.decode(GanjoorCatWithPoetDTO.self, "ganjoor-cat-26.json")
        let cat = GanjoorMapper.category(from: try #require(catResp.cat), poetId: 2, parentId: 9)
        #expect(cat.id == 26)
        #expect(cat.title == "رباعیات")
        #expect(cat.poems.count == 42)
        #expect(cat.poems[0].id == 2051)
        #expect(cat.poems[0].excerpt == "جز نقش تو در نظر نیامد ما را")
        #expect(cat.parentId == 9)

        let poetResp = try Fixture.decode(GanjoorCatWithPoetDTO.self, "ganjoor-poet-2.json")
        let poet = GanjoorMapper.poet(from: try #require(poetResp.poet), slug: "hafez")
        #expect(poet.id == 2)
        #expect(poet.name == "حافظ")
        #expect(poet.fullName == "حافظ شیرازی")
        #expect(poet.rootCategoryId == 9)
        #expect(poet.birthYearHijri == 726)
        #expect(poet.deathYearHijri == 792)
    }

    @Test func endpointsBuildExpectedURLs() {
        let e = GanjoorEndpoints()
        #expect(e.poet(id: 2).absoluteString == "https://api.ganjoor.net/api/ganjoor/poet/2")
        #expect(e.category(id: 24).absoluteString == "https://api.ganjoor.net/api/ganjoor/cat/24?poems=true")
        #expect(e.poem(id: 2130).absoluteString.hasPrefix("https://api.ganjoor.net/api/ganjoor/poem/2130?verseDetails=true"))
        #expect(e.syncXML(recitationId: 2840).absoluteString == "https://api.ganjoor.net/api/audio/xml/2840")
    }
}
