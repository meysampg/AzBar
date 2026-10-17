import Testing
@testable import AzBarKit

@Suite struct CoupletKeyAndTextTests {
    @Test func coupletKeyRoundTrips() {
        let k = CoupletKey(poemId: 2130, coupletIndex: 0)
        #expect(k.stringValue == "2130:0")
        #expect(CoupletKey(string: "2130:0") == k)
        #expect(CoupletKey(string: "x") == nil)
    }

    @Test func normalizeStripsDiacriticsAndZWNJ() {
        #expect(PersianText.normalizeForSearch("اَلا يا") == "الا یا")
        #expect(PersianText.removingDiacritics("اَلا") == "الا")
    }
}
