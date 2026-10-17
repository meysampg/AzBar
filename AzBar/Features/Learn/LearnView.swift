// PLACEHOLDER (WP0): WP4 overwrites this file, keeping `init(request:)`
import SwiftUI

struct LearnView: View {
    let request: LearnRequest
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("حفظ", systemImage: "brain.head.profile")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("بستن", systemImage: "xmark") { dismiss() }
                    }
                }
        }
    }
}
