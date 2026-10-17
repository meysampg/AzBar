import SwiftUI

/// Semantic text roles. All scale with Dynamic Type.
extension Font {
    static var azDisplay: Font { .app(.largeTitle, weight: .bold) }
    static var azTitle: Font { .app(.title2, weight: .bold) }
    static var azHeadline: Font { .app(.headline, weight: .semibold) }
    static var azBody: Font { .app(.body) }
    static var azCallout: Font { .app(.callout, weight: .medium) }
    /// Supporting text; pair with `Theme.Palette.inkSecondary`.
    static var azMeta: Font { .app(.subheadline) }
    static var azCaption: Font { .app(.caption, weight: .medium) }
    static var azButton: Font { .app(.headline, weight: .bold) }
    static var azNumber: Font { .app(.title2, weight: .bold) }
}
