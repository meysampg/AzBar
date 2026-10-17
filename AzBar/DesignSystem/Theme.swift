import SwiftUI

extension Color {
    /// sRGB colour from a 0xRRGGBB literal.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// "Persian paper" design tokens. Light only.
enum Theme {
    /// Raw sRGB values, so contrast can be unit tested.
    enum Hex {
        static let paper: UInt32 = 0xFBF7EF
        static let paperDeep: UInt32 = 0xF3ECDD
        static let card: UInt32 = 0xFFFFFF
        static let hairline: UInt32 = 0xEBE2CF
        static let sand: UInt32 = 0xD9CFBA
        static let track: UInt32 = 0xECE4D2
        static let sandDeep: UInt32 = 0xA79C85
        static let ink: UInt32 = 0x1F2A2E
        static let inkSecondary: UInt32 = 0x5B6467
        static let inkTertiary: UInt32 = 0x7E837C
        static let teal: UInt32 = 0x0F6E78
        static let tealDeep: UInt32 = 0x0A525A
        static let tealSoft: UInt32 = 0xE3F0EF
        static let gold: UInt32 = 0xC9A227
        static let goldDeep: UInt32 = 0x7A5C05
        static let goldSoft: UInt32 = 0xF7EDCB
        static let success: UInt32 = 0x2E7D4F
        static let successDeep: UInt32 = 0x1F6B3F
        static let successSoft: UInt32 = 0xE4F2E8
        static let danger: UInt32 = 0xB3412E
        static let dangerDeep: UInt32 = 0x9A3424
        static let dangerSoft: UInt32 = 0xF8E5E0
        static let warning: UInt32 = 0xA15C00
        static let warningSoft: UInt32 = 0xFBEBD3
        /// Text on warningSoft (warning itself is 4.4:1 there).
        static let warningDeep: UInt32 = 0x7F4A00
        static let info: UInt32 = 0x2F6DB3
        static let infoSoft: UInt32 = 0xE3EDF8
        /// Text on infoSoft (info itself is 4.48:1 there).
        static let infoDeep: UInt32 = 0x24569A
        static let flame: UInt32 = 0xD9682B
        static let plum: UInt32 = 0x6E4A8E
        static let rose: UInt32 = 0xB4485A
    }

    enum Palette {
        static let paper = Color(hex: Hex.paper)
        static let paperDeep = Color(hex: Hex.paperDeep)
        static let card = Color(hex: Hex.card)
        static let hairline = Color(hex: Hex.hairline)
        static let sand = Color(hex: Hex.sand)
        static let track = Color(hex: Hex.track)
        static let sandDeep = Color(hex: Hex.sandDeep)
        static let ink = Color(hex: Hex.ink)
        static let inkSecondary = Color(hex: Hex.inkSecondary)
        static let inkTertiary = Color(hex: Hex.inkTertiary)
        static let teal = Color(hex: Hex.teal)
        static let tealDeep = Color(hex: Hex.tealDeep)
        static let tealSoft = Color(hex: Hex.tealSoft)
        static let gold = Color(hex: Hex.gold)
        static let goldDeep = Color(hex: Hex.goldDeep)
        static let goldSoft = Color(hex: Hex.goldSoft)
        static let success = Color(hex: Hex.success)
        static let successDeep = Color(hex: Hex.successDeep)
        static let successSoft = Color(hex: Hex.successSoft)
        static let danger = Color(hex: Hex.danger)
        static let dangerDeep = Color(hex: Hex.dangerDeep)
        static let dangerSoft = Color(hex: Hex.dangerSoft)
        static let warning = Color(hex: Hex.warning)
        static let warningSoft = Color(hex: Hex.warningSoft)
        static let warningDeep = Color(hex: Hex.warningDeep)
        static let info = Color(hex: Hex.info)
        static let infoSoft = Color(hex: Hex.infoSoft)
        static let infoDeep = Color(hex: Hex.infoDeep)
        static let flame = Color(hex: Hex.flame)
        static let plum = Color(hex: Hex.plum)
        static let rose = Color(hex: Hex.rose)

        // Component-specific literals used by several files.
        /// Locked medallion face.
        static let lockedFill = Color(hex: 0xEEE7D7)
        /// Locked symbol on a medallion.
        static let lockedSymbol = Color(hex: 0xB5AA92)
        static let goldEdge = Color(hex: 0xB08A1A)
        static let whiteEdge = Color(hex: 0xCFE3E1)
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    enum Layout {
        static let margin: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let sectionGap: CGFloat = 28
        static let readableWidth: CGFloat = 640
        static let sessionWidth: CGFloat = 560
    }

    enum Radius {
        static let token: CGFloat = 8
        static let tile: CGFloat = 12
        static let control: CGFloat = 14
        static let card: CGFloat = 20
        static let panel: CGFloat = 24
        static let medallionSquare: CGFloat = 20
        static let highlight: CGFloat = 16
        /// Kept for existing call sites.
        static let small: CGFloat = 10
    }

    struct ShadowSpec: Sendable {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    enum Shadow {
        private static let base: UInt32 = 0x3B2F1A
        static let card = ShadowSpec(color: Color(hex: base, opacity: 0.07), radius: 10, y: 3)
        static let elevated = ShadowSpec(color: Color(hex: base, opacity: 0.12), radius: 16, y: 6)
        static let medallion = ShadowSpec(color: Color(hex: base, opacity: 0.10), radius: 4, y: 2)
    }

    static func color(for rating: Rating) -> Color {
        switch rating {
        case .again: Palette.danger
        case .hard: Palette.warning
        case .good: Palette.success
        case .easy: Palette.info
        }
    }

    static func softColor(for rating: Rating) -> Color {
        switch rating {
        case .again: Palette.dangerSoft
        case .hard: Palette.warningSoft
        case .good: Palette.successSoft
        case .easy: Palette.infoSoft
        }
    }

    /// Deep (text-safe) colour for a rating, used on its soft background.
    static func deepColor(for rating: Rating) -> Color {
        switch rating {
        case .again: Palette.dangerDeep
        case .hard: Palette.warningDeep
        case .good: Palette.successDeep
        case .easy: Palette.infoDeep
        }
    }

    /// Persian button title for a rating.
    static func title(for rating: Rating) -> String {
        switch rating {
        case .again: "دوباره"
        case .hard: "سخت"
        case .good: "خوب"
        case .easy: "آسان"
        }
    }
}

extension View {
    func azShadow(_ spec: Theme.ShadowSpec) -> some View {
        shadow(color: spec.color, radius: spec.radius, x: 0, y: spec.y)
    }
}

extension Theme {
    /// Deprecated colours of the old Duolingo-style components; remove in the final cleanup.
    enum Playful {
        @available(*, deprecated, message: "Use Theme.Palette.success")
        static let correct = Palette.success
        @available(*, deprecated, message: "Use Theme.Palette.danger")
        static let wrong = Palette.danger
        @available(*, deprecated, message: "Use Theme.Palette.gold")
        static let xp = Palette.gold
        @available(*, deprecated, message: "Use Theme.Palette.gold")
        static let gold = Palette.gold
        @available(*, deprecated, message: "Use Theme.Palette.sand")
        static let locked = Palette.sand
    }
}
