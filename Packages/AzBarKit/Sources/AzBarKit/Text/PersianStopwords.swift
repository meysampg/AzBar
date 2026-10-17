import Foundation

public enum PersianStopwords {
    /// Compared against normalized forms (`PersianText.normalizeForSearch`).
    public static let set: Set<String> = Set(
        PersianText.normalizeForSearch(
            "و به از که در با را بر تا این آن ای چو چون هر نه من تو او ما شما ز بی یا اگر گر هم است بود شد کز کو مرا ترا تورا همه پس ولی اما باز نیز هست کی چه کجا کین وین زان کان بدان درین وان ام ات اش"
        ).split(separator: " ").map(String.init)
    )
}
