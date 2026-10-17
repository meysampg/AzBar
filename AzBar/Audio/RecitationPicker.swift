import Foundation

enum RecitationPicker {
    /// Picks the default recitation: prefers `type == 0`, then a matching artist, then synced ones,
    /// otherwise the lowest `order`.
    static func preferred(_ list: [Recitation], artist: String?) -> Recitation? {
        guard !list.isEmpty else { return nil }
        let pool = list.filter { $0.type == 0 }
        let candidates = pool.isEmpty ? list : pool
        if let artist, !artist.isEmpty {
            let matches = candidates.filter { $0.artist == artist }
            if let best = matches.min(by: Self.isOrderedBefore) { return best }
        }
        return candidates.min(by: Self.isOrderedBefore)
    }

    private static func isOrderedBefore(_ a: Recitation, _ b: Recitation) -> Bool {
        if a.synced != b.synced { return a.synced }
        return a.order < b.order
    }
}
