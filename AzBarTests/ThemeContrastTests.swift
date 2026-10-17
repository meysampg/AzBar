import Foundation
import Testing
@testable import AzBar

/// WCAG 2.x contrast of the "Persian paper" tokens, computed from `Theme.Hex`.
struct ThemeContrastTests {
    typealias H = Theme.Hex

    private static func luminance(_ hex: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((hex >> 16) & 0xFF) + 0.7152 * channel((hex >> 8) & 0xFF) + 0.0722 * channel(hex & 0xFF)
    }

    static func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    struct Pair: CustomTestStringConvertible {
        let name: String
        let foreground: UInt32
        let background: UInt32
        var testDescription: String { name }
    }

    static let pairs: [Pair] = [
        // Text on the screen and card backgrounds.
        Pair(name: "ink/paper", foreground: H.ink, background: H.paper),
        Pair(name: "ink/white", foreground: H.ink, background: H.card),
        Pair(name: "ink/paperDeep", foreground: H.ink, background: H.paperDeep),
        Pair(name: "inkSecondary/paper", foreground: H.inkSecondary, background: H.paper),
        Pair(name: "inkSecondary/white", foreground: H.inkSecondary, background: H.card),
        Pair(name: "inkSecondary/paperDeep", foreground: H.inkSecondary, background: H.paperDeep),
        Pair(name: "teal/paper", foreground: H.teal, background: H.paper),
        Pair(name: "teal/white", foreground: H.teal, background: H.card),
        Pair(name: "teal/tealSoft", foreground: H.teal, background: H.tealSoft),
        Pair(name: "goldDeep/paper", foreground: H.goldDeep, background: H.paper),
        Pair(name: "goldDeep/white", foreground: H.goldDeep, background: H.card),
        Pair(name: "goldDeep/goldSoft", foreground: H.goldDeep, background: H.goldSoft),
        // White labels on solid fills.
        Pair(name: "white/teal", foreground: H.card, background: H.teal),
        Pair(name: "white/success", foreground: H.card, background: H.success),
        Pair(name: "white/danger", foreground: H.card, background: H.danger),
        Pair(name: "white/warning", foreground: H.card, background: H.warning),
        Pair(name: "white/info", foreground: H.card, background: H.info),
        // Deep tones on soft tones.
        Pair(name: "successDeep/successSoft", foreground: H.successDeep, background: H.successSoft),
        Pair(name: "dangerDeep/dangerSoft", foreground: H.dangerDeep, background: H.dangerSoft),
        Pair(name: "warningDeep/warningSoft", foreground: H.warningDeep, background: H.warningSoft),
        Pair(name: "infoDeep/infoSoft", foreground: H.infoDeep, background: H.infoSoft),
        Pair(name: "danger/white", foreground: H.danger, background: H.card),
        Pair(name: "inkSecondary/white (neutral chip)", foreground: H.inkSecondary, background: H.card),
        // Ink on gold.
        Pair(name: "ink/gold", foreground: H.ink, background: H.gold),
    ]

    @Test(arguments: pairs)
    func meetsAA(_ pair: Pair) {
        let r = Self.ratio(pair.foreground, pair.background)
        #expect(r >= 4.5, "\(pair.name) is \(r)")
    }

    @Test func tertiaryInkIsDecorativeOnly() {
        // Documented as ≈3.6:1; it must never be promoted to essential text without raising it.
        #expect(Self.ratio(H.inkTertiary, H.paper) < 4.5)
        #expect(Self.ratio(H.inkTertiary, H.paper) >= 3.0)
    }

    @Test func accentColorMatchesTeal() {
        #expect(H.teal == 0x0F6E78)
    }
}
