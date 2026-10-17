import Foundation

/// Small JSON file cache: `{directory}/{kind}-{id}.json`. Freshness is judged by file modification date.
public struct DiskCache: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func fileURL(kind: String, id: Int) -> URL {
        directory.appendingPathComponent("\(kind)-\(id).json")
    }

    /// Returns the cached value and whether it is still fresh (`maxAge == nil` means never expires).
    public func read<T: Decodable>(_ type: T.Type, kind: String, id: Int, maxAge: TimeInterval?,
                                   now: Date = Date()) -> (value: T, isFresh: Bool)? {
        let url = fileURL(kind: kind, id: id)
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        guard let maxAge else { return (value, true) }
        let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        let fresh = modified.map { now.timeIntervalSince($0) <= maxAge } ?? false
        return (value, fresh)
    }

    public func write<T: Encodable>(_ value: T, kind: String, id: Int) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(value)
            try data.write(to: fileURL(kind: kind, id: id), options: .atomic)
        } catch {
            // Caching is best-effort.
        }
    }

    public func remove(kind: String, id: Int) {
        try? FileManager.default.removeItem(at: fileURL(kind: kind, id: id))
    }
}
