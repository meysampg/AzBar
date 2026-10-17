import SwiftUI

enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 10
        static let card: CGFloat = 20
        static let highlight: CGFloat = 16
    }

    static func color(for rating: Rating) -> Color {
        switch rating {
        case .again: .red
        case .hard: .orange
        case .good: .green
        case .easy: .blue
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
