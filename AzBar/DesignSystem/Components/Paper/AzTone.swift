import SwiftUI

/// Semantic colour family shared by chips, icon badges and tiles.
enum AzTone: Sendable {
    case teal, gold, neutral, success, info, danger, warning

    /// Text and symbol colour that is legible on `soft`.
    var foreground: Color {
        switch self {
        case .teal: Theme.Palette.teal
        case .gold: Theme.Palette.goldDeep
        case .neutral: Theme.Palette.inkSecondary
        case .success: Theme.Palette.successDeep
        case .info: Theme.Palette.infoDeep
        case .danger: Theme.Palette.dangerDeep
        case .warning: Theme.Palette.warningDeep
        }
    }

    var soft: Color {
        switch self {
        case .teal: Theme.Palette.tealSoft
        case .gold: Theme.Palette.goldSoft
        case .neutral: Theme.Palette.paperDeep
        case .success: Theme.Palette.successSoft
        case .info: Theme.Palette.infoSoft
        case .danger: Theme.Palette.dangerSoft
        case .warning: Theme.Palette.warningSoft
        }
    }

    /// Solid fill colour.
    var strong: Color {
        switch self {
        case .teal: Theme.Palette.teal
        case .gold: Theme.Palette.gold
        case .neutral: Theme.Palette.sandDeep
        case .success: Theme.Palette.success
        case .info: Theme.Palette.info
        case .danger: Theme.Palette.danger
        case .warning: Theme.Palette.warning
        }
    }

    init(_ rating: Rating) {
        switch rating {
        case .again: self = .danger
        case .hard: self = .warning
        case .good: self = .success
        case .easy: self = .info
        }
    }
}
