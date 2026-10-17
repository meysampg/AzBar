import SwiftUI

extension View {
    /// RTL + fa_IR + Persian calendar. Apply at every presentation/preview root.
    func persianRoot() -> some View {
        environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "fa_IR"))
            .environment(\.calendar, Calendar(identifier: .persian))
    }
}
