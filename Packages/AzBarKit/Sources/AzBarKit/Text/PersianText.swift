import Foundation

public enum PersianText {
    private static func isDiacritic(_ v: UInt32) -> Bool {
        (0x064B...0x065F).contains(v) || v == 0x0670
            || (0x06D6...0x06DC).contains(v) || (0x06DF...0x06E8).contains(v) || (0x06EA...0x06ED).contains(v)
    }

    private static func isInvisible(_ v: UInt32) -> Bool {
        v == 0x0640 || v == 0x200C || v == 0x200D || v == 0x200F || v == 0x200E
    }

    /// Removes only the Arabic/Persian diacritics. Keeps ZWNJ and does not map letters.
    public static func removingDiacritics(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars where !isDiacritic(u.value) { out.append(u) }
        return String(out)
    }

    /// Search normalization: strips diacritics, tatweel and joiners, unifies letter variants and digits,
    /// collapses whitespace.
    public static func normalizeForSearch(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars {
            let v = u.value
            if isDiacritic(v) || isInvisible(v) { continue }
            switch v {
            case 0x064A, 0x0649, 0x0626: out.append(Unicode.Scalar(0x06CC)!)
            case 0x0643: out.append(Unicode.Scalar(0x06A9)!)
            case 0x0629, 0x06C0: out.append(Unicode.Scalar(0x0647)!)
            case 0x0623, 0x0625, 0x0622, 0x0671: out.append(Unicode.Scalar(0x0627)!)
            case 0x0624: out.append(Unicode.Scalar(0x0648)!)
            case 0x06F0...0x06F9: out.append(Unicode.Scalar(0x30 + (v - 0x06F0))!)
            case 0x0660...0x0669: out.append(Unicode.Scalar(0x30 + (v - 0x0660))!)
            default: out.append(u)
            }
        }
        let parts = String(out).split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }
}
