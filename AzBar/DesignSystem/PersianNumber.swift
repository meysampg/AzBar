import Foundation

enum PersianNumber {
    private static let digitsMap: [Character: Character] = [
        "0": "۰", "1": "۱", "2": "۲", "3": "۳", "4": "۴",
        "5": "۵", "6": "۶", "7": "۷", "8": "۸", "9": "۹",
    ]

    /// Converts ASCII digits in `s` to Persian digits.
    static func digits(_ s: String) -> String {
        String(s.map { digitsMap[$0] ?? $0 })
    }

    /// Persian digits, with the "٬" thousands separator for values of 10 000 and above.
    static func string(_ n: Int) -> String {
        let negative = n < 0
        let raw = String(n.magnitude)
        var s = raw
        if n.magnitude >= 10_000 {
            var out = ""
            for (i, ch) in raw.reversed().enumerated() {
                if i > 0, i % 3 == 0 { out.append("٬") }
                out.append(ch)
            }
            s = String(out.reversed())
        }
        return (negative ? "-" : "") + digits(s)
    }
}

extension Int {
    var fa: String { PersianNumber.string(self) }
}

extension Double {
    /// Persian digits with "٫" as decimal separator.
    func fa(fractionDigits: Int) -> String {
        let s = String(format: "%.\(max(0, fractionDigits))f", locale: Locale(identifier: "en_US_POSIX"), self)
        return PersianNumber.digits(s.replacingOccurrences(of: ".", with: "٫"))
    }
}
