import SwiftUI

enum PoemFont: String, CaseIterable, Identifiable, Sendable {
    case naskh, nastaliq, vazirmatn

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .naskh: "نسخ"
        case .nastaliq: "نستعلیق"
        case .vazirmatn: "وزیرمتن"
        }
    }

    var regularName: String {
        switch self {
        case .naskh: "NotoNaskhArabic-Regular"
        case .nastaliq: "NotoNastaliqUrdu-Regular"
        case .vazirmatn: "Vazirmatn-Regular"
        }
    }

    /// Nastaliq has no bold master; its bold name equals the regular one.
    var boldName: String {
        switch self {
        case .naskh: "NotoNaskhArabic-Bold"
        case .nastaliq: "NotoNastaliqUrdu-Regular"
        case .vazirmatn: "Vazirmatn-Bold"
        }
    }

    func lineSpacing(_ size: CGFloat) -> CGFloat {
        switch self {
        case .naskh: size * 0.45
        case .nastaliq: size * 1.0
        case .vazirmatn: size * 0.35
        }
    }

    func verticalPadding(_ size: CGFloat) -> CGFloat {
        self == .nastaliq ? size * 0.3 : 0
    }
}

enum AppFontWeight {
    case regular, medium, semibold, bold

    var postScriptName: String {
        switch self {
        case .regular: "Vazirmatn-Regular"
        case .medium: "Vazirmatn-Medium"
        case .semibold: "Vazirmatn-SemiBold"
        case .bold: "Vazirmatn-Bold"
        }
    }
}

extension Font.TextStyle {
    var basePointSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    fileprivate var defaultAppWeight: AppFontWeight {
        switch self {
        case .largeTitle, .title, .title2: .bold
        case .title3, .headline: .semibold
        default: .regular
        }
    }
}

extension Font {
    /// App UI font (Vazirmatn) scaling with Dynamic Type. Never use `.bold()` on it; pass `weight`.
    static func app(_ style: Font.TextStyle, weight: AppFontWeight? = nil) -> Font {
        let w = weight ?? style.defaultAppWeight
        return .custom(w.postScriptName, size: style.basePointSize, relativeTo: style)
    }

    /// Poem text font.
    static func poem(_ f: PoemFont, size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? f.boldName : f.regularName, size: size, relativeTo: .title3)
    }
}
