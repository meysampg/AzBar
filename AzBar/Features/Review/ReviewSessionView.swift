// PLACEHOLDER (WP0): WP4 overwrites this file, keeping `struct ReviewSessionView: View` with `init()`
import SwiftUI

struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("جلسهٔ مرور", systemImage: "rectangle.stack")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("بستن", systemImage: "xmark") { dismiss() }
                    }
                }
        }
    }
}
