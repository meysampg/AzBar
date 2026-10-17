// PLACEHOLDER (WP0): WP3 overwrites this file, keeping `struct LibraryView: View` with `init()`
import SwiftUI

struct LibraryView: View {
    var body: some View {
        ContentUnavailableView("کتابخانه", systemImage: "books.vertical")
            .navigationTitle("کتابخانه")
    }
}
