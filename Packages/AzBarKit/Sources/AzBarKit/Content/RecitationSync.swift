import Foundation

/// Parses the Ganjoor desktop sync XML:
/// `<SyncArray><SyncInfo><VerseOrder>0</VerseOrder><AudioMiliseconds>0</AudioMiliseconds></SyncInfo>…`.
/// `VerseOrder` is a 0-based offset into `Poem.orderedVerses`. Negative orders are dropped;
/// `<OneSecondBugFix>` and other elements are ignored.
public enum RecitationSyncParser {
    public static func parse(xml: String) -> [SyncPoint] {
        parse(data: Data(xml.utf8))
    }

    public static func parse(data: Data) -> [SyncPoint] {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.points
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var points: [SyncPoint] = []
        private var inSyncInfo = false
        private var current = ""
        private var verseOrder: Int?
        private var millis: Int?

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            if elementName == "SyncInfo" {
                inSyncInfo = true
                verseOrder = nil
                millis = nil
            }
            current = ""
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            current += string
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?) {
            guard inSyncInfo else { return }
            let text = current.trimmingCharacters(in: .whitespacesAndNewlines)
            switch elementName {
            case "VerseOrder": verseOrder = Int(text)
            case "AudioMiliseconds": millis = Int(text)
            case "SyncInfo":
                inSyncInfo = false
                if let v = verseOrder, v >= 0, let ms = millis {
                    points.append(SyncPoint(verseOffset: v, milliseconds: ms))
                }
            default: break
            }
        }
    }
}

public struct RecitationSyncLoader: Sendable {
    public init() {}

    /// Downloads and parses a sync file. The server returns a JSON-encoded string containing XML;
    /// a raw XML body is accepted as well.
    public func load(_ url: URL, session: URLSession = .shared) async throws -> [SyncPoint] {
        let data: Data
        do {
            let (d, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 404 { throw ContentError.notFound }
                guard (200..<300).contains(http.statusCode) else { throw ContentError.network("HTTP \(http.statusCode)") }
            }
            data = d
        } catch let e as ContentError {
            throw e
        } catch {
            throw ContentError.network(error.localizedDescription)
        }
        return try Self.points(fromBody: data)
    }

    /// Decodes a response body (JSON string containing XML, or raw XML).
    public static func points(fromBody data: Data) throws -> [SyncPoint] {
        let xml: String
        if let decoded = try? JSONDecoder().decode(String.self, from: data) {
            xml = decoded
        } else if let raw = String(data: data, encoding: .utf8) {
            xml = raw
        } else {
            throw ContentError.decoding("sync body is not UTF-8")
        }
        let points = RecitationSyncParser.parse(xml: xml)
        guard !points.isEmpty else { throw ContentError.decoding("no sync points") }
        return points
    }
}
