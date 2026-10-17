import Foundation
@testable import AzBarKit

enum Fixture {
    static func url(_ name: String) -> URL {
        Bundle.module.resourceURL!.appendingPathComponent("Fixtures").appendingPathComponent(name)
    }

    static func data(_ name: String) throws -> Data {
        try Data(contentsOf: url(name))
    }

    static func decode<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        try JSONDecoder().decode(T.self, from: data(name))
    }

    /// The real Hafez ghazal 1 response mapped to a domain poem.
    static func poem2130() throws -> Poem {
        let dto = try decode(GanjoorPoemDTO.self, "ganjoor-poem-2130.json")
        return GanjoorMapper.poem(from: dto, poetId: 2, categoryId: 24)
    }

    /// Repository-relative path of the bundled app pack (for the large-pack timing test).
    static var fullPackURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("AzBar/Resources/Content/pack-hafez.json")
    }
}
