import Foundation
import Testing
@testable import AzBarKit

@Suite struct RecitationSyncTests {
    @Test func fixtureParsesToFourteenPoints() throws {
        let points = try RecitationSyncLoader.points(fromBody: Fixture.data("sync-2840.json"))
        #expect(points.count == 14)
        #expect(points.map(\.verseOffset) == Array(0..<14))
        #expect(points[0].milliseconds == 0)
        #expect(points[1].milliseconds == 7386)
        #expect(points[13].milliseconds == 92436)
        let ms = points.map(\.milliseconds)
        #expect(ms == ms.sorted())
    }

    @Test func rawXMLBodyParses() throws {
        let xml = """
        <DesktopGanjoorPoemAudioList><PoemAudio><SyncArray>
        <SyncInfo><VerseOrder>0</VerseOrder><AudioMiliseconds>0</AudioMiliseconds></SyncInfo>
        <SyncInfo><VerseOrder>1</VerseOrder><AudioMiliseconds>1500</AudioMiliseconds></SyncInfo>
        </SyncArray></PoemAudio></DesktopGanjoorPoemAudioList>
        """
        let points = try RecitationSyncLoader.points(fromBody: Data(xml.utf8))
        #expect(points == [SyncPoint(verseOffset: 0, milliseconds: 0), SyncPoint(verseOffset: 1, milliseconds: 1500)])
    }

    @Test func negativeOrdersAndBugFixAreIgnored() {
        let xml = """
        <A><OneSecondBugFix>true</OneSecondBugFix><SyncArray>
        <SyncInfo><VerseOrder>-1</VerseOrder><AudioMiliseconds>0</AudioMiliseconds></SyncInfo>
        <SyncInfo><VerseOrder>0</VerseOrder><AudioMiliseconds>100</AudioMiliseconds></SyncInfo>
        </SyncArray></A>
        """
        #expect(RecitationSyncParser.parse(xml: xml) == [SyncPoint(verseOffset: 0, milliseconds: 100)])
    }

    @Test func garbageThrowsDecoding() {
        #expect(throws: ContentError.self) { try RecitationSyncLoader.points(fromBody: Data("not xml".utf8)) }
        #expect(RecitationSyncParser.parse(xml: "").isEmpty)
    }

    @Test func syncMatchesPoemVerseCount() throws {
        let poem = try Fixture.poem2130()
        let points = try RecitationSyncLoader.points(fromBody: Fixture.data("sync-2840.json"))
        #expect(points.count == poem.orderedVerses.count)
        #expect(poem.coupletIndex(forVerseOffset: points[3].verseOffset) == 1)
    }
}
