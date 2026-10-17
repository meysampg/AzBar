import Foundation

public struct MesraToken: Identifiable, Hashable, Sendable {
    public var id: Int
    public var mesraIndex: Int
    /// Full token as it appears in the text (leading + core + trailing).
    public var text: String
    public var core: String
    public var leading: String
    public var trailing: String
    public var normalized: String
    /// True when `normalized` contains at least one letter.
    public var isWord: Bool

    public init(id: Int, mesraIndex: Int, text: String, core: String, leading: String,
                trailing: String, normalized: String, isWord: Bool) {
        self.id = id
        self.mesraIndex = mesraIndex
        self.text = text
        self.core = core
        self.leading = leading
        self.trailing = trailing
        self.normalized = normalized
        self.isWord = isWord
    }
}

public enum PersianTokenizer {
    private static let punctuation: Set<Character> = Set("،؛؟!.:«»\"'()[]…-–—")

    /// Splits on Unicode whitespace only (ZWNJ is never a separator) and peels punctuation.
    public static func tokenize(_ mesra: String, mesraIndex: Int, startId: Int) -> [MesraToken] {
        let words = mesra.split(whereSeparator: { $0.isWhitespace || $0 == "\u{00A0}" })
        var result: [MesraToken] = []
        var nextId = startId
        for w in words {
            let chars = Array(w)
            var lo = 0
            var hi = chars.count
            while lo < hi, punctuation.contains(chars[lo]) { lo += 1 }
            while hi > lo, punctuation.contains(chars[hi - 1]) { hi -= 1 }
            let leading = String(chars[0..<lo])
            let core = String(chars[lo..<hi])
            let trailing = String(chars[hi...])
            let normalized = PersianText.normalizeForSearch(core)
            let isWord = normalized.contains { $0.isLetter }
            result.append(MesraToken(id: nextId, mesraIndex: mesraIndex, text: String(w), core: core,
                                     leading: leading, trailing: trailing, normalized: normalized, isWord: isWord))
            nextId += 1
        }
        return result
    }
}
